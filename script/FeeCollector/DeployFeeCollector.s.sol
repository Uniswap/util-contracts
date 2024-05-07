// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {FeeCollector} from "../../src/FeeCollector.sol";

struct DeployParameters {
    address owner;
    address universalRouter;
    address permit2;
    address feeToken;
}

abstract contract DeployFeeCollector is Script {
    DeployParameters internal params;

    function setUp() public virtual {}

    function run() public returns (FeeCollector collector) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        // require all parameters to be set
        require(params.owner != address(0), "owner not set");
        require(params.universalRouter != address(0), "universalRouter not set");
        require(params.permit2 != address(0), "permit2 not set");
        require(params.feeToken != address(0), "feeToken not set");

        vm.startBroadcast(privateKey);
        collector = new FeeCollector{salt: 0x00}(params.owner, params.universalRouter, params.permit2, params.feeToken);
        vm.stopBroadcast();

        console2.log("Successfully deployed FeeCollector", address(collector));
        console2.log("owner", collector.owner());
    }

    function logParams() internal view {
        console2.log("permit2:", params.permit2);
        console2.log("feeToken:", params.feeToken);
        console2.log("universalRouter:", params.universalRouter);
        console2.log("owner:", params.owner);
    }
}
