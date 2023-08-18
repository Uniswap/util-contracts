
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {TokenFees, FeeOnTransferDetector} from "../../src/FeeOnTransferDetector.sol";

contract FotDetectionTest is Test{
    FeeOnTransferDetector detector;
    address constant factoryV2 = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function setUp() public {
        vm.createSelectFork(vm.envString("FORK_URL"), 17900000);
        detector = new FeeOnTransferDetector(factoryV2);
    }

    function testBulletToken() public {
        address bulletToken = 0x8ef32a03784c8Fd63bBf027251b9620865bD54B6;
        uint256 expectedBuyFeeBps = 500;
        uint256 expectedSellFeeBps = 500;

        TokenFees memory fees = detector.validate(bulletToken, WETH, 10000000000);
        assertEq(fees.buyFeeBps, expectedBuyFeeBps);
        assertEq(fees.sellFeeBps, expectedSellFeeBps);
    }
}
