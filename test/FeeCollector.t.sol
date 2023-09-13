// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {MockToken} from "./mock/MockToken.sol";
import {FeeCollector} from "../src/FeeCollector.sol";
import {IUniversalRouter} from "../src/external/IUniversalRouter.sol";

contract FeeCollectorTest is Test {
    FeeCollector public collector;

    uint256 callerPrivateKey;
    uint256 usdcRecipientPrivateKey;

    address caller;
    address usdcRecipient;
    address usdc;

    MockToken mockUSDC;
    IUniversalRouter immutable router = IUniversalRouter(0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD);

    function setUp() public {
        // Mock caller and usdc recipient
        callerPrivateKey = 0x12341234;
        caller = vm.addr(callerPrivateKey);
        usdcRecipientPrivateKey = 0x12341235;
        usdcRecipient = vm.addr(usdcRecipientPrivateKey);

        mockUSDC = new MockToken();

        collector = new FeeCollector(caller, router, usdcRecipient, address(mockUSDC));
    }

    function testWithdrawUSDC() public {
        assertEq(mockUSDC.balanceOf(address(collector)), 0);
        assertEq(mockUSDC.balanceOf(address(usdcRecipient)), 0);
        mockUSDC.mint(address(collector), 100 ether);
        assertEq(mockUSDC.balanceOf(address(collector)), 100 ether);
        vm.prank(caller);
        collector.withdrawUSDC();
        assertEq(mockUSDC.balanceOf(address(collector)), 0);
        assertEq(mockUSDC.balanceOf(address(usdcRecipient)), 100 ether);
    }

    function testWithdrawUSDCNotAllowed() public {
        assertEq(mockUSDC.balanceOf(address(collector)), 0);
        assertEq(mockUSDC.balanceOf(address(usdcRecipient)), 0);
        mockUSDC.mint(address(collector), 100 ether);
        assertEq(mockUSDC.balanceOf(address(collector)), 100 ether);
        vm.expectRevert(FeeCollector.CallerNotAllowlisted.selector);
        vm.prank(address(0xbeef));
        collector.withdrawUSDC();
        assertEq(mockUSDC.balanceOf(address(collector)), 100 ether);
    }
}
