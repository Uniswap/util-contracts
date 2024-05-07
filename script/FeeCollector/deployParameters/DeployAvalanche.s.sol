// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeployFeeCollector, DeployParameters} from "../DeployFeeCollector.s.sol";

contract DeployAvalanche is DeployFeeCollector {
    function setUp() public override {
        params = DeployParameters({
            owner: 0xbE84D31B2eE049DCb1d8E7c798511632b44d1b55,
            universalRouter: 0x4Dae2f939ACf50408e13d58534Ff8c2776d45265,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            feeToken: 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E
        });
    }
}