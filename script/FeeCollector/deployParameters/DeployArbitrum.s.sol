// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeployFeeCollector, DeployParameters} from "../DeployFeeCollector.s.sol";

contract DeployArbitrum is DeployFeeCollector {
    function setUp() public override {
        params = DeployParameters({
            owner: 0xbE84D31B2eE049DCb1d8E7c798511632b44d1b55,
            universalRouter: 0x5E325eDA8064b456f4781070C0738d849c824258,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            feeToken: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831
        });
    }
}
