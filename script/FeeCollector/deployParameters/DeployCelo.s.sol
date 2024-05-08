// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeployFeeCollector, DeployParameters} from "../DeployFeeCollector.s.sol";

contract DeployCelo is DeployFeeCollector {
    function setUp() public override {
        params = DeployParameters({
            owner: OWNER,
            universalRouter: 0x643770E279d5D0733F21d6DC03A8efbABf3255B4,
            permit2: PERMIT2,
            feeToken: 0xcebA9300f2b948710d2653dD7B07f33A8B32118C
        });
    }
}
