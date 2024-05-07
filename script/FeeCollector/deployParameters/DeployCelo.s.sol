// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeployFeeCollector, DeployParameters} from "../DeployFeeCollector.s.sol";

contract DeployCelo is DeployFeeCollector {
    function setUp() public override {
        params = DeployParameters({
            owner: 0xbE84D31B2eE049DCb1d8E7c798511632b44d1b55,
            universalRouter: 0x643770E279d5D0733F21d6DC03A8efbABf3255B4,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            feeToken: 0xcebA9300f2b948710d2653dD7B07f33A8B32118C
        });
    }
}
