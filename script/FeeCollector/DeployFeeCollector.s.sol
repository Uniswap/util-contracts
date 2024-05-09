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

    address public constant OWNER = 0xbE84D31B2eE049DCb1d8E7c798511632b44d1b55;
    address public constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    // For mainnet parameters, deploys the FeeCollector to 0x000000fee2Ab0fF8Dc826D3d7f45328e9Cc0471f
    bytes32 constant SALT = bytes32(uint256(0x0000000000000000000000000000000000000000e6a691a183251100795200f0));

    function setUp() public virtual {}

    function run() public returns (FeeCollector collector) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        // require all parameters to be set
        require(params.owner != address(0), "owner not set");
        require(params.universalRouter != address(0), "universalRouter not set");
        require(params.permit2 != address(0), "permit2 not set");
        require(params.feeToken != address(0), "feeToken not set");
        
        vm.startBroadcast(privateKey);
        collector = new FeeCollector{salt: SALT}(params.owner, params.universalRouter, params.permit2, params.feeToken);
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
