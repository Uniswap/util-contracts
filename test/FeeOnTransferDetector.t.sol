// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/FeeOnTransferDetector.sol";

contract FeeOnTransferDetectorTest is Test {
    FeeOnTransferDetector public detector;

    function setUp() public {
        detector = new FeeOnTransferDetector(address(0));
    }
}
