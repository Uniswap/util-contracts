// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeployFeeCollector, DeployParameters} from "../DeployFeeCollector.s.sol";

contract DeployBase is DeployFeeCollector {
    function setUp() public override {
        params = DeployParameters({
            owner: 0xbE84D31B2eE049DCb1d8E7c798511632b44d1b55,
            universalRouter: 0xec7BE89e9d109e7e3Fec59c222CF297125FEFda2,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            feeToken: 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359
        });
    }
}