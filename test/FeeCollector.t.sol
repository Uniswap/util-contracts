// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockToken} from "./mock/MockToken.sol";
import {MockSearcher} from "./mock/MockSearcher.sol";
import {FeeCollector} from "../src/FeeCollector.sol";

contract FeeCollectorTest is Test {
    FeeCollector public collector;

    address caller;
    address feeRecipient;

    MockToken mockFeeToken;
    MockToken tokenIn;
    MockToken tokenOut;

    MockSearcher searcherContract;

    function setUp() public {
        // Mock caller and fee recipient
        caller = makeAddr("caller");
        feeRecipient = makeAddr("feeRecipient");
        mockFeeToken = new MockToken();
        tokenIn = new MockToken();
        tokenOut = new MockToken();

        collector = new FeeCollector(caller, feeRecipient, address(mockFeeToken), 100 ether);
        searcherContract = new MockSearcher(payable(address(collector)));
    }

    function testSwapBalance() public {
        tokenIn.mint(address(collector), 100 ether);
        assertEq(tokenIn.balanceOf(address(collector)), 100 ether);

        // For the test we just assume the filler has the required fee tokens
        mockFeeToken.mint(address(searcherContract), 100 ether);

        ERC20[] memory tokens = new ERC20[](1);
        tokens[0] = tokenIn;
        bytes memory call = abi.encodeWithSignature("doMev()");
        searcherContract.swapBalances(tokens, call);

        // Expect that the full tokenIn balance of the collector was sent to the searcher contract
        assertEq(tokenIn.balanceOf(address(collector)), 0);
        assertEq(tokenIn.balanceOf(address(searcherContract)), 100 ether);
        // Expect that the fee tokens were transferred to the fee recipient
        assertEq(mockFeeToken.balanceOf(address(feeRecipient)), 100 ether);
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
