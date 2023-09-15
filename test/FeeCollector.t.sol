// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockToken} from "./mock/MockToken.sol";
import {MockUniversalRouter} from "./mock/MockUniversalRouter.sol";
import {IMockUniversalRouter} from "./mock/MockUniversalRouter.sol";
import {FeeCollector} from "../src/FeeCollector.sol";

contract FeeCollectorTest is Test {
    FeeCollector public collector;

    address caller;
    address feeRecipient;
    address permit2;

    MockToken mockFeeToken;
    MockToken tokenIn;
    MockToken tokenOut;
    MockUniversalRouter router;

    function setUp() public {
        // Mock caller and fee recipient
        caller = makeAddr("caller");
        feeRecipient = makeAddr("feeRecipient");
        permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
        mockFeeToken = new MockToken();
        tokenIn = new MockToken();
        tokenOut = new MockToken();
        router = new MockUniversalRouter();

        collector = new FeeCollector(caller, address(router), permit2, address(mockFeeToken));
    }

    function testSwapBalance() public {
        tokenIn.mint(address(collector), 100 ether);
        tokenOut.mint(address(router), 100 ether);
        assertEq(tokenIn.balanceOf(address(collector)), 100 ether);
        assertEq(tokenOut.balanceOf(address(router)), 100 ether);

        bytes memory swapData = abi.encodeWithSelector(
            IMockUniversalRouter.execute.selector, abi.encode(address(tokenIn), address(tokenOut), 100 ether, 100 ether)
        );

        vm.prank(address(collector));
        tokenIn.approve(address(router), 100 ether);
        vm.prank(caller);
        collector.swapBalance(swapData, 0);

        assertEq(tokenIn.balanceOf(address(collector)), 0 ether);
        assertEq(tokenOut.balanceOf(address(collector)), 100 ether);
        assertEq(tokenIn.balanceOf(address(router)), 100 ether);
        assertEq(tokenOut.balanceOf(address(router)), 0 ether);
    }

    function testSwapBalanceNative() public {
        vm.deal(address(collector), 100 ether);
        tokenOut.mint(address(router), 100 ether);
        assertEq(address(collector).balance, 100 ether);
        assertEq(tokenOut.balanceOf(address(router)), 100 ether);

        bytes memory swapData = abi.encodeWithSelector(
            IMockUniversalRouter.execute.selector, abi.encode(address(0), address(tokenOut), 100 ether, 100 ether)
        );

        vm.prank(caller);
        collector.swapBalance(swapData, 100 ether);

        assertEq(address(collector).balance, 0 ether);
        assertEq(tokenOut.balanceOf(address(collector)), 100 ether);
        assertEq(address(router).balance, 100 ether);
        assertEq(tokenOut.balanceOf(address(router)), 0 ether);
    }

    function testSwapBalanceNativeError() public {
        tokenIn.mint(address(collector), 100 ether);
        tokenOut.mint(address(router), 100 ether);
        assertEq(tokenIn.balanceOf(address(collector)), 100 ether);
        assertEq(tokenOut.balanceOf(address(router)), 100 ether);

        bytes memory badSwapCallData = abi.encodeWithSelector(
            IMockUniversalRouter.execute.selector, abi.encode(address(tokenIn), address(tokenOut))
        );

        vm.prank(address(collector));
        tokenIn.approve(address(router), 100 ether);
        vm.expectRevert(FeeCollector.UniversalRouterCallFailed.selector);
        vm.prank(caller);
        collector.swapBalance(badSwapCallData, 0);

        assertEq(tokenIn.balanceOf(address(collector)), 100 ether);
        assertEq(tokenOut.balanceOf(address(collector)), 0 ether);
        assertEq(tokenIn.balanceOf(address(router)), 0 ether);
        assertEq(tokenOut.balanceOf(address(router)), 100 ether);
    }

    function testSwapBalanceUnauthorized() public {
        tokenIn.mint(address(collector), 100 ether);
        tokenOut.mint(address(router), 100 ether);
        assertEq(tokenIn.balanceOf(address(collector)), 100 ether);
        assertEq(tokenOut.balanceOf(address(router)), 100 ether);

        bytes memory swapData = abi.encodeWithSelector(
            IMockUniversalRouter.execute.selector, abi.encode(address(tokenIn), address(tokenOut), 100 ether, 100 ether)
        );

        vm.prank(address(collector));
        tokenIn.approve(address(router), 100 ether);
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0xbeef));
        collector.swapBalance(swapData, 0);

        assertEq(tokenIn.balanceOf(address(collector)), 100 ether);
        assertEq(tokenOut.balanceOf(address(collector)), 0 ether);
        assertEq(tokenIn.balanceOf(address(router)), 0 ether);
        assertEq(tokenOut.balanceOf(address(router)), 100 ether);
    }

    function testWithdrawFeeToken() public {
        assertEq(mockFeeToken.balanceOf(address(collector)), 0);
        assertEq(mockFeeToken.balanceOf(address(feeRecipient)), 0);
        mockFeeToken.mint(address(collector), 100 ether);
        assertEq(mockFeeToken.balanceOf(address(collector)), 100 ether);
        vm.prank(caller);
        collector.withdrawFeeToken(feeRecipient);
        assertEq(mockFeeToken.balanceOf(address(collector)), 0);
        assertEq(mockFeeToken.balanceOf(address(feeRecipient)), 100 ether);
    }

    function testWithdrawFeeTokenUnauthorized() public {
        assertEq(mockFeeToken.balanceOf(address(collector)), 0);
        assertEq(mockFeeToken.balanceOf(address(feeRecipient)), 0);
        mockFeeToken.mint(address(collector), 100 ether);
        assertEq(mockFeeToken.balanceOf(address(collector)), 100 ether);
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0xbeef));
        collector.withdrawFeeToken(feeRecipient);
        assertEq(mockFeeToken.balanceOf(address(collector)), 100 ether);
    }

    function testTransferOwnership() public {
        address newOwner = makeAddr("newOwner");
        assertEq(collector.owner(), caller);
        vm.prank(caller);
        collector.transferOwnership(newOwner);
        assertEq(collector.owner(), newOwner);
    }

    function testTransferOwnershipUnauthorized() public {
        address newOwner = makeAddr("newOwner");
        assertEq(collector.owner(), caller);
        vm.expectRevert("UNAUTHORIZED");
        collector.transferOwnership(newOwner);
        assertEq(collector.owner(), caller);
    }
}
