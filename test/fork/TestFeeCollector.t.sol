// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockToken} from "../mock/MockToken.sol";
import {FeeCollector} from "../../src/FeeCollector.sol";
import {IFeeCollector} from "../../src/interfaces/IFeeCollector.sol";

contract FeeCollectorTest is Test {
    uint256 constant ONE = 10 ** 18;

    ERC20 constant DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ERC20 constant USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address constant WHALE = 0x55FE002aefF02F77364de339a1292923A15844B8;
    address constant UNIVERSAL_ROUTER = 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address payable constant FEE_COLLECTOR = payable(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

    uint256 callerPrivateKey;
    uint256 feeRecipientPrivateKey;

    address caller;
    address feeRecipient;

    FeeCollector collector;

    function setUp() public {
        callerPrivateKey = 0x12341234;
        feeRecipientPrivateKey = 0x12351235;

        caller = vm.addr(callerPrivateKey);
        feeRecipient = vm.addr(feeRecipientPrivateKey);

        vm.createSelectFork(vm.envString("FORK_URL"), 17972788);

        deployCodeTo(
            "FeeCollector.sol",
            abi.encode(caller, UNIVERSAL_ROUTER, PERMIT2, feeRecipient, address(USDC)),
            FEE_COLLECTOR
        );
        collector = FeeCollector(FEE_COLLECTOR);

        assertEq(address(collector), FEE_COLLECTOR, "Reactor address does not match expected");

        // Transfer 1000 DAI to collector
        vm.startPrank(WHALE);
        DAI.transfer(FEE_COLLECTOR, 1000 * ONE);
        vm.stopPrank();
    }

    function testSwapBalance() public {
        assertEq(DAI.balanceOf(FEE_COLLECTOR), 1000 * ONE);
        assertEq(USDC.balanceOf(address(feeRecipient)), 0);
        assertEq(USDC.balanceOf(FEE_COLLECTOR), 0);
        ERC20[] memory tokensToApprove = new ERC20[](1);
        tokensToApprove[0] = DAI;
        bytes memory DAI_USDC_UR_CALLDATA =
            hex"24856bc3000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000010000000000000000000000000068b3465833fb72A70ecDF485E0e4C7bD8665Fc450000000000000000000000000000000000000000000000056bc75e2d631000000000000000000000000000000000000000000000000000000000000005adccc500000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002b6b175474e89094c44da98b954eedeac495271d0f000064a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000";

        // Swap collector DAI balance to USDC
        vm.prank(caller);
        collector.swapBalance(tokensToApprove, DAI_USDC_UR_CALLDATA);
        uint256 collectorUSDCBalance = USDC.balanceOf(address(collector));
        assertEq(collectorUSDCBalance, 99989240);

        // Withdraw USDC to feeRecipient
        assertEq(USDC.balanceOf(address(feeRecipient)), 0);
        vm.prank(caller);
        collector.withdrawFeeToken();
        assertEq(USDC.balanceOf(address(feeRecipient)), collectorUSDCBalance);
    }
}
