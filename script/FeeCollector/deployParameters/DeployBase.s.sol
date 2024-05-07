// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeployFeeCollector, DeployParameters} from "../DeployFeeCollector.s.sol";

contract DeployBase is DeployFeeCollector {
    function setUp() public override {
        params = DeployParameters({
            owner: 0xbE84D31B2eE049DCb1d8E7c798511632b44d1b55,
            universalRouter: 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD,
            permit2: 0x000000000022D473030F116dDEE9F6B43aC78BA3,
            feeToken: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
        });
    }
}
