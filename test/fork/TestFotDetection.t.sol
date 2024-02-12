// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {TokenFees, FeeOnTransferDetector} from "../../src/FeeOnTransferDetector.sol";

contract FotDetectionTest is Test {
    FeeOnTransferDetector detector;
    address constant factoryV2 = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function setUp() public {
        vm.createSelectFork(vm.envString("FORK_URL"));
        detector = new FeeOnTransferDetector(factoryV2);
    }

    function testBulletToken() public {
        address token = 0x8ef32a03784c8Fd63bBf027251b9620865bD54B6;
        uint256 expectedBuyFeeBps = 500;
        uint256 expectedSellFeeBps = 500;

        TokenFees memory fees = detector.validate(token, WETH, 10000);
        assertEq(fees.buyFeeBps, expectedBuyFeeBps);
        assertEq(fees.sellFeeBps, expectedSellFeeBps);
    }

    function testXToken() public {
        address token = 0xaBeC00542D141BDdF58649bfe860C6449807237c;
        uint256 expectedBuyFeeBps = 100;
        uint256 expectedSellFeeBps = 100;

        TokenFees memory fees = detector.validate(token, WETH, 10000);
        assertEq(fees.buyFeeBps, expectedBuyFeeBps);
        assertEq(fees.sellFeeBps, expectedSellFeeBps);
    }

    function testKukuToken() public {
        address token = 0x27206F5a9AFD0C51dA95F20972885545D3B33647;
        uint256 expectedBuyFeeBps = 200;
        uint256 expectedSellFeeBps = 200;

        TokenFees memory fees = detector.validate(token, WETH, 10000);
        assertEq(fees.buyFeeBps, expectedBuyFeeBps);
        assertEq(fees.sellFeeBps, expectedSellFeeBps);
    }

    function testCocoToken() public {
        address token = 0xcB50350aB555Ed5d56265E096288536E8Cac41Eb;
        uint256 expectedBuyFeeBps = 200;
        uint256 expectedSellFeeBps = 200;

        TokenFees memory fees = detector.validate(token, WETH, 10000);
        assertEq(fees.buyFeeBps, expectedBuyFeeBps);
        assertEq(fees.sellFeeBps, expectedSellFeeBps);
    }

    function testHarryPotter() public {
        address token = 0x2577944fD4b556A99cC5aA0f072e4B944Aa088DF;
        uint256 expectedBuyFeeBps = 100;
        uint256 expectedSellFeeBps = 100;

        TokenFees memory fees = detector.validate(token, WETH, 10000);
        assertEq(fees.buyFeeBps, expectedBuyFeeBps);
        assertEq(fees.sellFeeBps, expectedSellFeeBps);
    }

    function testPaypal() public {
        address token = 0xe0A8ED732658832Fac18141AA5AD3542e2EB503B;
        uint256 expectedBuyFeeBps = 100;
        uint256 expectedSellFeeBps = 100;

        TokenFees memory fees = detector.validate(token, WETH, 10000);
        assertEq(fees.buyFeeBps, expectedBuyFeeBps);
        assertEq(fees.sellFeeBps, expectedSellFeeBps);
    }

    function testUSDT() public {
        address token = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        uint256 expectedBuyFeeBps = 0;
        uint256 expectedSellFeeBps = 0;

        TokenFees memory fees = detector.validate(token, WETH, 10000);
        assertEq(fees.buyFeeBps, expectedBuyFeeBps);
        assertEq(fees.sellFeeBps, expectedSellFeeBps);
    }
}
