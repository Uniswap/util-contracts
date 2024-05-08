// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeployFeeCollector, DeployParameters} from "../DeployFeeCollector.s.sol";

contract DeployArbitrum is DeployFeeCollector {
    function setUp() public override {
        params = DeployParameters({
            owner: OWNER,
            universalRouter: 0x5E325eDA8064b456f4781070C0738d849c824258,
            permit2: PERMIT2,
            feeToken: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
        });
    }
}
