// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockToken} from "../mock/MockToken.sol";
import {FeeCollector} from "../../src/FeeCollector.sol";
import {IFeeCollector} from "../../src/interfaces/IFeeCollector.sol";
import {IPermit2} from "../../src/external/IPermit2.sol";
import {IAllowanceTransfer} from "../../src/external/IAllowanceTransfer.sol";

contract FeeCollectorZksyncTest is Test {
    ERC20 constant USDC = ERC20(0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4);
    ERC20 constant WETH = ERC20(0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91);
    address constant WHALE = 0x428AB2BA90Eba0a4Be7aF34C9Ac451ab061AC010;
    address constant UNIVERSAL_ROUTER = 0x28731BCC616B5f51dD52CF2e4dF0E78dD1136C06;
    address constant PERMIT2 = 0x0000000000225e31D15943971F47aD3022F714Fa;

    address owner;
    address feeRecipient;

    FeeCollector collector;
    IPermit2 permit2;

    function setUp() public {
        owner = makeAddr("owner");
        feeRecipient = makeAddr("feeRecipient");

        vm.createSelectFork(vm.envString("FORK_URL_324"), 37078060);

        vm.label(UNIVERSAL_ROUTER, "UniversalRouter");
        assertGe(UNIVERSAL_ROUTER.code.length, 0);
        assertGe(UNIVERSAL_ROUTER.balance, 0);

        collector = new FeeCollector(owner, UNIVERSAL_ROUTER, PERMIT2, address(USDC));
        vm.label(address(collector), "FeeCollector");
        assertEq(collector.owner(), owner);
        assertEq(collector.universalRouter(), UNIVERSAL_ROUTER);

        permit2 = IPermit2(PERMIT2);
    }

    function testSwapBalance() public {
        vm.prank(WHALE);
        WETH.transfer(address(collector), 20 ether);

        // Check balances and allowances
        uint256 preSwapBalance = USDC.balanceOf(address(feeRecipient));
        assertEq(preSwapBalance, 0);
        assertEq(WETH.balanceOf(address(collector)), 20 ether);
        assertEq(USDC.balanceOf(address(collector)), 0);
        assertEq(WETH.allowance(address(collector), PERMIT2), 0);
        (uint160 preSwapAllowance,,) = permit2.allowance(address(collector), address(WETH), UNIVERSAL_ROUTER);
        assertEq(preSwapAllowance, 0);

        // Build params for approve and swap
        // bytes memory WETH_USDC_UR_CALLDATA =
            // hex"24856bc300000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000400000604000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000002e0000000000000000000000000000000000000000000000000000000000000036000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000010a741a46278000000000000000000000000000000000000000000000000000000000000f9bbcf500000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000425aea5775959fbc2557cc8789bc1bf90a239d9a910001f43355df6d4c9c3035724fd0e3914de96a5a83aaf40000641d17cbcf0d6d143135ae902365d2e5e2a16538d4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000058d15e17628000000000000000000000000000000000000000000000000000000000000533b88400000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002b5aea5775959fbc2557cc8789bc1bf90a239d9a910001f41d17cbcf0d6d143135ae902365d2e5e2a16538d400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000001d17cbcf0d6d143135ae902365d2e5e2a16538d40000000000000000000000007ffc3dbf3b2b50ff3a1d5523bc24bb5043837b14000000000000000000000000000000000000000000000000000000000000001900000000000000000000000000000000000000000000000000000000000000600000000000000000000000001d17cbcf0d6d143135ae902365d2e5e2a16538d400000000000000000000000032f4b2e69ebd7746596af8699dac1908f43107ad0000000000000000000000000000000000000000000000000000000014cf757b";
        bytes memory WETH_USDC_UR_CALLDATA = hex"3593564c000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000006674ae790000000000000000000000000000000000000000000000000000000000000005a1a1a1a1a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000003e0000000000000000000000000000000000000000000000000000000000000076000000000000000000000000000000000000000000000000000000000000009800000000000000000000000000000000000000000000000000000000000000b80000000000000000000000000000000000000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001600000000000000000000000000000000000000000000000000000000000000100000000000000000000000000d09c6edff99123d0110ba4ea639a26061697a5df000000000000000000000000000000000000000000000000671ccfb86977e17f00000000000000000000000000000000000000000000000000000005af69d9d100000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002b5aea5775959fbc2557cc8789bc1bf90a239d9a910001f41d17cbcf0d6d143135ae902365d2e5e2a16538d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000d09c6edff99123d0110ba4ea639a26061697a5df000000000000000000000000000000000000000000000000225eefe82327f5d5000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002b5aea5775959fbc2557cc8789bc1bf90a239d9a91000bb81d17cbcf0d6d143135ae902365d2e5e2a16538d4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000036000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000120000000000000000000000000d09c6edff99123d0110ba4ea639a26061697a5df0000000000000000000000000000000000000000000009dde5f0e5c8e7b9a4b20000000000000000000000000000000000000000000000000000000204c5974000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000425a7d6b2f92c77fad6ccabd7ee0624e64907eaf3e000bb85aea5775959fbc2557cc8789bc1bf90a239d9a910001f41d17cbcf0d6d143135ae902365d2e5e2a16538d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000120000000000000000000000000d09c6edff99123d0110ba4ea639a26061697a5df000000000000000000000000000000000000000000000349f7504c984d3de19000000000000000000000000000000000000000000000000000000000abb9990800000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000425a7d6b2f92c77fad6ccabd7ee0624e64907eaf3e0027105aea5775959fbc2557cc8789bc1bf90a239d9a91000bb81d17cbcf0d6d143135ae902365d2e5e2a16538d400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000120000000000000000000000000d09c6edff99123d0110ba4ea639a26061697a5df000000000000000000000000000000000000000000000000000000008bf2525e000000000000000000000000000000000000000000000000000000008423c4e300000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000423355df6d4c9c3035724fd0e3914de96a5a83aaf40001f45aea5775959fbc2557cc8789bc1bf90a239d9a910001f41d17cbcf0d6d143135ae902365d2e5e2a16538d400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000100000000000000000000000000d09c6edff99123d0110ba4ea639a26061697a5df000000000000000000000000000000000000000000000000000000006bcd59820000000000000000000000000000000000000000000000000000000065f417e900000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002b493257fd37edb34451f62edf8d2a0c418852ba4c0000641d17cbcf0d6d143135ae902365d2e5e2a16538d400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000120000000000000000000000000d09c6edff99123d0110ba4ea639a26061697a5df000000000000000000000000000000000000000000000000000000000002c8730000000000000000000000000000000000000000000000000000000006ae662500000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000059bbeb516fb02a01611cbbe0453fe3c580d72810110001f45aea5775959fbc2557cc8789bc1bf90a239d9a910001f43355df6d4c9c3035724fd0e3914de96a5a83aaf40000641d17cbcf0d6d143135ae902365d2e5e2a16538d400000000000000";
        // Approve DAI to permit2 and permit2 to universal router

        address[] memory tokensToApprove = new address[](1);
        tokensToApprove[0] = 0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91; // WETH

        for(uint i = 0; i < tokensToApprove.length; i++) {
            vm.startPrank(address(collector));
            WETH.approve(PERMIT2, type(uint256).max);
            assertEq(WETH.allowance(address(collector), PERMIT2), type(uint256).max);
            permit2.approve(address(WETH), UNIVERSAL_ROUTER, type(uint160).max, type(uint48).max);
            (preSwapAllowance,,) = permit2.allowance(address(collector), address(WETH), UNIVERSAL_ROUTER);
            assertEq(preSwapAllowance, type(uint160).max);
            vm.stopPrank();
        }

        // Swap collector DAI balance to USDC
        // vm.prank(owner);
        // collector.swapBalance(WETH_USDC_UR_CALLDATA, 0);

        // trading approx 10 WETH for USDC, slippage has been modified to be 1 USDC minimum on each leg of the swap
        // the two swaps are wrapped in a subplan, which should allow for reverts, so why is it reverting?

        // Command: EXECUTE_SUB_PLAN
        // V3_SWAP_EXACT_IN:
        //     recipient: 0xd09c6EDFF99123D0110Ba4Ea639A26061697a5DF
        //     amountIn: 7430041876204872063
        //     amountOutMin: 1
        //     path: [object Object]
        //     payerIsUser: true
        // V3_SWAP_EXACT_IN:
        //     recipient: 0xd09c6EDFF99123D0110Ba4Ea639A26061697a5DF
        //     amountIn: 2476680625401624021
        //     amountOutMin: 1
        //     path: [object Object]
        // payerIsUser: true

        bytes[] memory inputs = new bytes[](1);
        inputs[0] = hex"00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001600000000000000000000000000000000000000000000000000000000000000100000000000000000000000000d09c6edff99123d0110ba4ea639a26061697a5df000000000000000000000000000000000000000000000000671ccfb86977e17f000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002b5aea5775959fbc2557cc8789bc1bf90a239d9a910001f41d17cbcf0d6d143135ae902365d2e5e2a16538d40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000d09c6edff99123d0110ba4ea639a26061697a5df000000000000000000000000000000000000000000000000225eefe82327f5d5000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002b5aea5775959fbc2557cc8789bc1bf90a239d9a91000bb81d17cbcf0d6d143135ae902365d2e5e2a16538d4000000000000000000000000000000000000000000";
    
        bytes memory cd = abi.encodeWithSignature("execute(bytes,bytes[])", hex"a1", inputs);
        console2.logBytes(cd);
        vm.prank(address(collector));
        (bool success,) = UNIVERSAL_ROUTER.call(cd);
        require(success, "Swap failed");
    }
}