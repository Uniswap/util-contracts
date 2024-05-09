// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockToken} from "../mock/MockToken.sol";
import {FeeCollector} from "../../src/FeeCollector.sol";
import {IFeeCollector} from "../../src/interfaces/IFeeCollector.sol";
import {IPermit2} from "../../src/external/IPermit2.sol";
import {IAllowanceTransfer} from "../../src/external/IAllowanceTransfer.sol";

contract FeeCollectorTest is Test {
    ERC20 constant DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ERC20 constant USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ERC20 constant UNI = ERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    address constant WHALE = 0x55FE002aefF02F77364de339a1292923A15844B8;
    address constant UNIVERSAL_ROUTER = 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address payable constant FEE_COLLECTOR = payable(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

    address caller;
    address feeRecipient;

    FeeCollector collector;
    IPermit2 permit2;

    function setUp() public {
        caller = makeAddr("caller");
        feeRecipient = makeAddr("feeRecipient");

        vm.createSelectFork(vm.envString("FORK_URL"), 17972788);

        deployCodeTo("FeeCollector.sol", abi.encode(caller, UNIVERSAL_ROUTER, PERMIT2, address(USDC)), FEE_COLLECTOR);
        collector = FeeCollector(FEE_COLLECTOR);
        permit2 = IPermit2(PERMIT2);

        assertEq(address(collector), FEE_COLLECTOR, "FeeCollector address does not match expected");
    }

    function testSwapBalance() public {
        vm.prank(WHALE);
        DAI.transfer(address(collector), 1000 ether);

        // Check balances and allowances
        uint256 preSwapBalance = USDC.balanceOf(address(feeRecipient));
        assertEq(DAI.balanceOf(address(collector)), 1000 ether);
        assertEq(USDC.balanceOf(address(collector)), 0);
        assertEq(DAI.allowance(address(collector), PERMIT2), 0);
        (uint160 preSwapAllowance,,) = permit2.allowance(address(collector), address(DAI), UNIVERSAL_ROUTER);
        assertEq(preSwapAllowance, 0);

        // Build params for approve and swap
        bytes memory DAI_USDC_UR_CALLDATA =
            hex"24856bc3000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000010000000000000000000000000068b3465833fb72A70ecDF485E0e4C7bD8665Fc450000000000000000000000000000000000000000000000056bc75e2d631000000000000000000000000000000000000000000000000000000000000005adccc500000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002b6b175474e89094c44da98b954eedeac495271d0f000064a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000";

        // Approve DAI to permit2 and permit2 to universal router
        vm.startPrank(address(collector));
        DAI.approve(PERMIT2, type(uint256).max);
        permit2.approve(address(DAI), UNIVERSAL_ROUTER, type(uint160).max, type(uint48).max);
        vm.stopPrank();

        // Swap collector DAI balance to USDC
        vm.prank(caller);
        collector.swapBalance(DAI_USDC_UR_CALLDATA, 0);
        uint256 collectorUSDCBalance = USDC.balanceOf(address(collector));
        assertEq(collectorUSDCBalance, 99989240);

        // Withdraw USDC to feeRecipient
        assertEq(USDC.balanceOf(address(feeRecipient)), preSwapBalance);
        vm.prank(caller);
        collector.withdrawFeeToken(feeRecipient, collectorUSDCBalance);
        assertEq(USDC.balanceOf(address(feeRecipient)), preSwapBalance + collectorUSDCBalance);
        assertEq(USDC.balanceOf(address(collector)), 0);
    }

    function testSwapBalanceWithApproves() public {
        vm.prank(WHALE);
        DAI.transfer(address(collector), 1000 ether);

        // Check balances and allowances
        assertEq(DAI.balanceOf(address(collector)), 1000 ether);
        assertEq(USDC.balanceOf(address(feeRecipient)), 0);
        assertEq(USDC.balanceOf(address(collector)), 0);
        assertEq(DAI.allowance(address(collector), PERMIT2), 0);
        (uint160 preSwapAllowance,,) = permit2.allowance(address(collector), address(DAI), UNIVERSAL_ROUTER);
        assertEq(preSwapAllowance, 0);

        // Build params for approve and swap
        ERC20[] memory tokensToApprove = new ERC20[](1);
        tokensToApprove[0] = DAI;
        bytes memory DAI_USDC_UR_CALLDATA =
            hex"24856bc3000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000010000000000000000000000000068b3465833fb72A70ecDF485E0e4C7bD8665Fc450000000000000000000000000000000000000000000000056bc75e2d631000000000000000000000000000000000000000000000000000000000000005adccc500000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002b6b175474e89094c44da98b954eedeac495271d0f000064a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000";

        // Swap collector DAI balance to USDC
        vm.prank(caller);
        collector.swapBalance(DAI_USDC_UR_CALLDATA, 0, tokensToApprove);
        uint256 collectorUSDCBalance = USDC.balanceOf(address(collector));
        assertEq(collectorUSDCBalance, 99989240);
        assertEq(DAI.allowance(address(collector), PERMIT2), type(uint256).max);
        (uint160 postSwapAllowance,,) = permit2.allowance(address(collector), address(DAI), UNIVERSAL_ROUTER);
        assertEq(postSwapAllowance, type(uint160).max);

        // Withdraw USDC to feeRecipient
        assertEq(USDC.balanceOf(address(feeRecipient)), 0);
        vm.prank(caller);
        collector.withdrawFeeToken(feeRecipient, collectorUSDCBalance);
        assertEq(USDC.balanceOf(address(feeRecipient)), collectorUSDCBalance);
        assertEq(USDC.balanceOf(address(collector)), 0);
    }

    function testSwapBalanceNative() public {
        vm.deal(address(collector), 1000 ether);

        // Check balances and allowances
        uint256 preSwapBalance = USDC.balanceOf(address(feeRecipient));
        assertEq(address(collector).balance, 1000 ether);

        // Build params for native swap
        bytes memory ETH_USDC_UR_CALLDATA =
            hex"24856bc30000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000020b080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000400000000000000000000000003fc91a3afd70395cd496c647d5a6cc9d4b2b7fad00000000000000000000000000000000000000000000003635c9adc5dea00000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000068b3465833fb72a70ecdf485e0e4c7bd8665fc4500000000000000000000000000000000000000000000003635c9adc5dea000000000000000000000000000000000000000000000000000000000015d817f744000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";

        vm.prank(caller);
        collector.swapBalance(ETH_USDC_UR_CALLDATA, 1000 ether);
        uint256 collectorUSDCBalance = USDC.balanceOf(address(collector));
        assertEq(collectorUSDCBalance, 1531751180017);

        // Withdraw USDC to feeRecipient
        assertEq(USDC.balanceOf(address(feeRecipient)), preSwapBalance);
        vm.prank(caller);
        collector.withdrawFeeToken(feeRecipient, collectorUSDCBalance);
        assertEq(USDC.balanceOf(address(feeRecipient)), preSwapBalance + collectorUSDCBalance);
        assertEq(USDC.balanceOf(address(collector)), 0);
    }

    function testSwapBalanceBatchSwap() public {
        vm.prank(WHALE);
        DAI.transfer(address(collector), 100 ether);
        vm.deal(address(collector), 1000 ether);

        // Check balances and allowances
        uint256 preSwapBalance = USDC.balanceOf(address(feeRecipient));
        assertEq(address(collector).balance, 1000 ether);
        assertEq(DAI.balanceOf(address(collector)), 100 ether);

        // Build params for approve and swap
        ERC20[] memory tokensToApprove = new ERC20[](1);
        tokensToApprove[0] = DAI;
        bytes memory ETH_AND_DAI_TO_USDC_UR_CALLDATA =
            hex"24856bc30000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000030b080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000001e000000000000000000000000000000000000000000000000000000000000000400000000000000000000000003fc91a3afd70395cd496c647d5a6cc9d4b2b7fad00000000000000000000000000000000000000000000003635c9adc5dea00000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000068b3465833fb72a70ecdf485e0e4c7bd8665fc4500000000000000000000000000000000000000000000003635c9adc5dea00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000000000000000000000010000000000000000000000000068b3465833fb72a70ecdf485e0e4c7bd8665fc450000000000000000000000000000000000000000000000056bc75e2d63100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002b6b175474e89094c44da98b954eedeac495271d0f000064a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000";

        // Swap native and DAI to USDC
        vm.prank(caller);
        collector.swapBalance(ETH_AND_DAI_TO_USDC_UR_CALLDATA, 1000 ether, tokensToApprove);
        uint256 collectorUSDCBalance = USDC.balanceOf(address(collector));
        assertEq(DAI.balanceOf(address(collector)), 0);
        assertEq(address(collector).balance, 0);
        assertEq(collectorUSDCBalance, 1531851169257);

        // Withdraw USDC to feeRecipient
        assertEq(USDC.balanceOf(address(feeRecipient)), preSwapBalance);
        vm.prank(caller);
        collector.withdrawFeeToken(feeRecipient, collectorUSDCBalance);
        assertEq(USDC.balanceOf(address(feeRecipient)), preSwapBalance + collectorUSDCBalance);
        assertEq(USDC.balanceOf(address(collector)), 0);
    }

    function testRevokeApprovalsAndSwapBalanceWithApprovals() public {
        // Approve DAI to permit2 and permit2 to universal router
        vm.startPrank(address(collector));
        DAI.approve(PERMIT2, type(uint256).max);
        permit2.approve(address(DAI), UNIVERSAL_ROUTER, type(uint160).max, type(uint48).max);
        vm.stopPrank();

        ERC20[] memory tokensToRevoke = new ERC20[](1);
        tokensToRevoke[0] = DAI;

        // revoke token approval
        vm.prank(caller);
        collector.revokeTokenApprovals(tokensToRevoke);
        assertEq(DAI.allowance(address(collector), PERMIT2), 0);
        
        IAllowanceTransfer.TokenSpenderPair[] memory approvals = new IAllowanceTransfer.TokenSpenderPair[](1);
        approvals[0] = IAllowanceTransfer.TokenSpenderPair(address(DAI), UNIVERSAL_ROUTER);

        // revoke permit2 approval
        vm.prank(caller);
        collector.revokePermit2Approvals(approvals);
        (uint256 allowance,,) = permit2.allowance(address(collector), address(DAI), UNIVERSAL_ROUTER);
        assertEq(allowance, 0);

        // SwapBalance like normal with approves
        vm.prank(WHALE);
        DAI.transfer(address(collector), 1000 ether);

        // Check balances and allowances
        assertEq(DAI.balanceOf(address(collector)), 1000 ether);
        assertEq(USDC.balanceOf(address(feeRecipient)), 0);
        assertEq(USDC.balanceOf(address(collector)), 0);
        assertEq(DAI.allowance(address(collector), PERMIT2), 0);
        (uint160 preSwapAllowance,,) = permit2.allowance(address(collector), address(DAI), UNIVERSAL_ROUTER);
        assertEq(preSwapAllowance, 0);

        // Build params for approve and swap
        ERC20[] memory tokensToApprove = new ERC20[](1);
        tokensToApprove[0] = DAI;
        bytes memory DAI_USDC_UR_CALLDATA =
            hex"24856bc3000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000010000000000000000000000000068b3465833fb72A70ecDF485E0e4C7bD8665Fc450000000000000000000000000000000000000000000000056bc75e2d631000000000000000000000000000000000000000000000000000000000000005adccc500000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002b6b175474e89094c44da98b954eedeac495271d0f000064a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000";

        // Swap collector DAI balance to USDC
        vm.prank(caller);
        collector.swapBalance(DAI_USDC_UR_CALLDATA, 0, tokensToApprove);
        uint256 collectorUSDCBalance = USDC.balanceOf(address(collector));
        assertEq(collectorUSDCBalance, 99989240);
        assertEq(DAI.allowance(address(collector), PERMIT2), type(uint256).max);
        (uint160 postSwapAllowance,,) = permit2.allowance(address(collector), address(DAI), UNIVERSAL_ROUTER);
        assertEq(postSwapAllowance, type(uint160).max);

        // Withdraw USDC to feeRecipient
        assertEq(USDC.balanceOf(address(feeRecipient)), 0);
        vm.prank(caller);
        collector.withdrawFeeToken(feeRecipient, collectorUSDCBalance);
        assertEq(USDC.balanceOf(address(feeRecipient)), collectorUSDCBalance);
        assertEq(USDC.balanceOf(address(collector)), 0);
    }

    function testrevokePermit2Approvals() public {
        (uint256 allowance,,) = permit2.allowance(address(collector), address(DAI), UNIVERSAL_ROUTER);
        assertEq(allowance, 0);

        vm.prank(address(collector));
        permit2.approve(address(DAI), UNIVERSAL_ROUTER, 100 ether, 0);
        (allowance,,) = permit2.allowance(address(collector), address(DAI), UNIVERSAL_ROUTER);
        assertEq(allowance, 100 ether);

        IAllowanceTransfer.TokenSpenderPair[] memory approvals = new IAllowanceTransfer.TokenSpenderPair[](1);
        approvals[0] = IAllowanceTransfer.TokenSpenderPair(address(DAI), UNIVERSAL_ROUTER);

        vm.prank(caller);
        collector.revokePermit2Approvals(approvals);
        (allowance,,) = permit2.allowance(address(collector), address(DAI), UNIVERSAL_ROUTER);
        assertEq(allowance, 0);
    }
}
