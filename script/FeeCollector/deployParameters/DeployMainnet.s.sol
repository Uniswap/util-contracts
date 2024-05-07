// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeployFeeCollector, DeployParameters} from "../DeployFeeCollector.s.sol";

contract DeployMainnet is DeployFeeCollector {
    function setUp() public override {
        params = DeployParameters({
            owner: 0xbE84D31B2eE049DCb1d8E7c798511632b44d1b55,
            universalRouter: 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            feeToken: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        });
    }
}
