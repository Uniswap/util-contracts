// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockToken} from "./mock/MockToken.sol";
import {FeeCollector} from "../src/FeeCollector.sol";

contract FeeCollectorTest is Test {
    FeeCollector public collector;

    uint256 callerPrivateKey;
    uint256 feeRecipientPrivateKey;

    address caller;
    address feeRecipient;
    address router;

    MockToken mockFeeToken;

    function setUp() public {
        // Mock caller and fee recipient
        callerPrivateKey = 0x12341234;
        caller = vm.addr(callerPrivateKey);
        feeRecipientPrivateKey = 0x12341235;
        feeRecipient = vm.addr(feeRecipientPrivateKey);
        router = 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD;
        mockFeeToken = new MockToken();

        collector = new FeeCollector(caller, router, feeRecipient, address(mockFeeToken));
    }

    function testSwapBalanceApproves() public {
        MockToken tokenToApprove1 = new MockToken();
        MockToken tokenToApprove2 = new MockToken();
        ERC20[] memory tokensToApprove = new ERC20[](2);
        tokensToApprove[0] = tokenToApprove1;
        tokensToApprove[1] = tokenToApprove2;
        assertEq(tokenToApprove1.allowance(address(collector), router), 0);
        assertEq(tokenToApprove2.allowance(address(collector), router), 0);
        vm.prank(caller);
        collector.swapBalance(tokensToApprove, abi.encodeWithSelector(0x12341234));
        assertEq(tokenToApprove1.allowance(address(collector), router), type(uint256).max);
        assertEq(tokenToApprove2.allowance(address(collector), router), type(uint256).max);
    }

    function testWithdrawFeeToken() public {
        assertEq(mockFeeToken.balanceOf(address(collector)), 0);
        assertEq(mockFeeToken.balanceOf(address(feeRecipient)), 0);
        mockFeeToken.mint(address(collector), 100 ether);
        assertEq(mockFeeToken.balanceOf(address(collector)), 100 ether);
        vm.prank(caller);
        collector.withdrawFeeToken();
        assertEq(mockFeeToken.balanceOf(address(collector)), 0);
        assertEq(mockFeeToken.balanceOf(address(feeRecipient)), 100 ether);
    }

    function testWithdrawFeeTokenNotAllowed() public {
        assertEq(mockFeeToken.balanceOf(address(collector)), 0);
        assertEq(mockFeeToken.balanceOf(address(feeRecipient)), 0);
        mockFeeToken.mint(address(collector), 100 ether);
        assertEq(mockFeeToken.balanceOf(address(collector)), 100 ether);
        vm.expectRevert("UNAUTHORIZED");
        vm.prank(address(0xbeef));
        collector.withdrawFeeToken();
        assertEq(mockFeeToken.balanceOf(address(collector)), 100 ether);
    }
}
