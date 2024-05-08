// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {FeeOnTransferDetector} from "../../src/FeeOnTransferDetector.sol";

contract DeployScript is Script {
    address private constant V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    function setUp() public {}

    function run() public {
        vm.broadcast();
        address detector = address(new FeeOnTransferDetector{salt: 0x00}(V2_FACTORY));

        console2.log("Successfully deployed", detector);
    }
}
