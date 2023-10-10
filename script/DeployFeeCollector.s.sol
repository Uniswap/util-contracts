// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {FeeCollector} from "../src/FeeCollector.sol";

contract DeployFeeCollector is Script {
    function setUp() public {}

    function run() public returns (FeeCollector collector) {
        uint256 privateKey = vm.envUint("FOUNDRY_FEE_COLLECTOR_PRIVATE_KEY");
        address owner = vm.envAddress("FOUNDRY_FEE_COLLECTOR_OWNER_ADDRESS");
        address universalRouter = vm.envAddress("FOUNDRY_FEE_COLLECTOR_UNIVERSAL_ROUTER_ADDRESS");
        address permit2 = vm.envAddress("FOUNDRY_FEE_COLLECTOR_PERMIT2_ADDRESS");
        address feeToken = vm.envAddress("FOUNDRY_FEE_COLLECTOR_FEE_TOKEN_ADDRESS");

        vm.startBroadcast(privateKey);
        collector = new FeeCollector{salt: 0x00}(owner, universalRouter, permit2, feeToken);
        vm.stopBroadcast();

        console2.log("Successfully deployed FeeCollector", address(collector));
        console2.log("owner", collector.owner());
    }
}
