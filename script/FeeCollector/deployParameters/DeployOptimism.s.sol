// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeployFeeCollector, DeployParameters} from "../DeployFeeCollector.s.sol";

contract DeployOptimism is DeployFeeCollector {
    function setUp() public override {
        params = DeployParameters({
            owner: 0xbE84D31B2eE049DCb1d8E7c798511632b44d1b55,
            universalRouter: 0xCb1355ff08Ab38bBCE60111F1bb2B784bE25D7e8,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            feeToken: 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85
        });
    }
}
