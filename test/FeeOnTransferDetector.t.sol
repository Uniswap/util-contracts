// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
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
        assertEq(fees.sellFeeBps, 200);
        assertEq(fees.buyFeeBps, 500);
    }
}
