// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {TokenFees, FeeOnTransferDetector} from "../src/FeeOnTransferDetector.sol";
import {MockV2Factory} from "./mock/MockV2Factory.sol";
import {MockFotToken} from "./mock/MockFotToken.sol";
import {MockFotTokenWithExternalFees} from "./mock/MockFotTokenWithExternalFees.sol";
import {MockReentrancyFotToken} from "./mock/MockReentrancyFotToken.sol";
import {MockSellReentrancyFotToken} from "./mock/MockSellReentrancyFotToken.sol";
import {MockToken} from "./mock/MockToken.sol";
import {MockReenteringPair} from "./mock/MockReenteringPair.sol";

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
        assertEq(fees.feeTakenOnTransfer, false);
        assertEq(fees.externalTransferFailed, false);
        assertEq(fees.sellReverted, false);
    }

    function testBasicFotTokenNoPrecisionLoss() public {
        MockFotToken fotToken = new MockFotToken(200, 500);
        MockToken otherToken = new MockToken();
        address pair = factory.deployPair(address(fotToken), address(otherToken));
        fotToken.setPair(pair);
        fotToken.mint(pair, 100 ether);
        otherToken.mint(pair, 100 ether);
        IUniswapV2Pair(pair).sync();

        // previously used to fail due to precision loss from integer division
        TokenFees memory fees = detector.validate(address(fotToken), address(otherToken), 9999);
        assertEq(fees.buyFeeBps, 200);
        assertEq(fees.sellFeeBps, 500);
        assertEq(fees.feeTakenOnTransfer, false);
        assertEq(fees.externalTransferFailed, false);
        assertEq(fees.sellReverted, false);
    }

    function testBasicFotTokenWithExternalFees() public {
        MockFotTokenWithExternalFees fotToken = new MockFotTokenWithExternalFees(500);
        MockToken otherToken = new MockToken();
        address pair = factory.deployPair(address(fotToken), address(otherToken));
        fotToken.setPair(pair);
        fotToken.mint(pair, 100 ether);
        otherToken.mint(pair, 100 ether);
        IUniswapV2Pair(pair).sync();

        TokenFees memory fees = detector.validate(address(fotToken), address(otherToken), 1 ether);
        assertEq(fees.buyFeeBps, 500);
        assertEq(fees.sellFeeBps, 500);
        assertEq(fees.feeTakenOnTransfer, true);
        assertEq(fees.externalTransferFailed, false);
        assertEq(fees.sellReverted, false);
    }

    function testReentrancyFotToken() public {
        MockReentrancyFotToken fotToken = new MockReentrancyFotToken(500);
        MockToken otherToken = new MockToken();
        address pair = factory.deployPair(address(fotToken), address(otherToken));
        fotToken.setPair(pair);
        fotToken.mint(pair, 100 ether);
        otherToken.mint(pair, 100 ether);
        IUniswapV2Pair(pair).sync();

        TokenFees memory fees = detector.validate(address(fotToken), address(otherToken), 1 ether);
        assertEq(fees.buyFeeBps, 500);
        assertEq(fees.sellFeeBps, 500);
        assertEq(fees.feeTakenOnTransfer, false);
        assertEq(fees.externalTransferFailed, true);
        assertEq(fees.sellReverted, false);
    }

    function testSellReentrancyFotToken() public {
        MockSellReentrancyFotToken fotToken = new MockSellReentrancyFotToken(500);
        MockToken otherToken = new MockToken();
        address pair = factory.deployPair(address(fotToken), address(otherToken));
        fotToken.setPair(pair);
        fotToken.mint(pair, 100 ether);
        otherToken.mint(pair, 100 ether);
        IUniswapV2Pair(pair).sync();

        TokenFees memory fees = detector.validate(address(fotToken), address(otherToken), 1 ether);
        assertEq(fees.buyFeeBps, 500);
        assertEq(fees.sellFeeBps, 500);
        assertEq(fees.feeTakenOnTransfer, false);
        assertEq(fees.externalTransferFailed, false);
        assertEq(fees.sellReverted, true);
    }

    function testBasicFotTokenFuzz(uint16 buyFee, uint16 sellFee) public {
        // detector.validate() will revert if the fee is 0, so we need to bound the fee to 1-9999
        sellFee = uint16(bound(sellFee, 1, 9999));
        buyFee = uint16(bound(buyFee, 1, 9999));
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
        assertEq(fees.feeTakenOnTransfer, false);
        assertEq(fees.externalTransferFailed, false);
        assertEq(fees.sellReverted, false);
    }

    function testBasicFotTokenWithExternalFeesFuzz(uint16 fee) public {
        // detector.validate() will revert if the fee is 0, so we need to bound the fee to 1-9999
        fee = uint16(bound(fee, 0, 9999));
        MockFotTokenWithExternalFees fotToken = new MockFotTokenWithExternalFees(fee);
        MockToken otherToken = new MockToken();
        address pair = factory.deployPair(address(fotToken), address(otherToken));
        fotToken.setPair(pair);
        fotToken.mint(pair, 100 ether);
        otherToken.mint(pair, 100 ether);
        IUniswapV2Pair(pair).sync();

        TokenFees memory fees = detector.validate(address(fotToken), address(otherToken), 1 ether);
        assertEq(fees.buyFeeBps, fee);
        assertEq(fees.sellFeeBps, fee);
        bool feeTakenOnTransfer = (fee == 0 && fee == 0) ? false : true;
        assertEq(fees.feeTakenOnTransfer, feeTakenOnTransfer);
        assertEq(fees.externalTransferFailed, false);
        assertEq(fees.sellReverted, false);
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

    function testNoPairReentrancy() public {
        MockFotToken fotToken = new MockFotToken(10001, 10001);
        MockToken otherToken = new MockToken();
        address pair = factory.deployPair(address(fotToken), address(otherToken));

        MockReenteringPair reenteringPair = new MockReenteringPair();

        vm.etch(pair, address(reenteringPair).code);
        fotToken.setPair(pair);

        vm.expectRevert();
        detector.validate(address(fotToken), address(otherToken), 1 ether);
    }
}
