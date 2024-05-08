// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeployFeeCollector, DeployParameters} from "../DeployFeeCollector.s.sol";

contract DeployPolygon is DeployFeeCollector {
    function setUp() public override {
        params = DeployParameters({
            owner: OWNER,
            universalRouter: 0xec7BE89e9d109e7e3Fec59c222CF297125FEFda2,
            permit2: PERMIT2,
            feeToken: 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359
        });
    }
}
