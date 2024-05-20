// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {TokenFees, FeeOnTransferDetector} from "../src/FeeOnTransferDetector.sol";
import {MockV2Factory} from "./mock/MockV2Factory.sol";
import {MockFotToken} from "./mock/MockFotToken.sol";
import {MockToken} from "./mock/MockToken.sol";

interface IUniswapV2Pair {
    function sync() external;
}

contract FeeOnTransferDetectorTest is Test {
    FeeOnTransferDetector public detector;
    MockV2Factory public factory;

    function setUp() public {
        factory = new MockV2Factory();
        detector = new FeeOnTransferDetector(address(factory));
    }

    function testBasicFotToken() public {
        MockFotToken fotToken = new MockFotToken(200, 500);
        MockToken otherToken = new MockToken();
        address pair = factory.deployPair(address(fotToken), address(otherToken));
        fotToken.setPair(pair);
        fotToken.mint(pair, 100 ether);
        otherToken.mint(pair, 100 ether);
        IUniswapV2Pair(pair).sync();

        TokenFees memory fees = detector.validate(address(fotToken), address(otherToken), 1 ether);
        assertEq(fees.buyFeeBps, 200);
        assertEq(fees.sellFeeBps, 500);
        assertEq(fees.hasExternalFees, false);
    }

    function testBasicFotTokenFuzz(uint16 buyFee, uint16 sellFee) public {
        sellFee = uint16(bound(sellFee, 0, 10000));
        buyFee = uint16(bound(buyFee, 0, 10000));
        MockFotToken fotToken = new MockFotToken(buyFee, sellFee);
        MockToken otherToken = new MockToken();
        address pair = factory.deployPair(address(fotToken), address(otherToken));
        fotToken.setPair(pair);
        fotToken.mint(pair, 100 ether);
        otherToken.mint(pair, 100 ether);
        IUniswapV2Pair(pair).sync();

        TokenFees memory fees = detector.validate(address(fotToken), address(otherToken), 1 ether);
        assertEq(fees.buyFeeBps, buyFee);
        assertEq(fees.sellFeeBps, sellFee);
        assertEq(fees.hasExternalFees, false);
    }

    function testTransferFailsErrorPassthrough() public {
        MockFotToken fotToken = new MockFotToken(10001, 10001);
        MockToken otherToken = new MockToken();
        address pair = factory.deployPair(address(fotToken), address(otherToken));
        fotToken.setPair(pair);
        fotToken.mint(pair, 100 ether);
        otherToken.mint(pair, 100 ether);
        IUniswapV2Pair(pair).sync();

        vm.expectRevert(stdError.arithmeticError);
        detector.validate(address(fotToken), address(otherToken), 1 ether);
    }
}
