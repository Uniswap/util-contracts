// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeployFeeCollector, DeployParameters} from "../DeployFeeCollector.s.sol";

contract DeployZksync is DeployFeeCollector {
    function setUp() public override {
        params = DeployParameters({
            owner: OWNER,
            universalRouter: 0x28731BCC616B5f51dD52CF2e4dF0E78dD1136C06,
            // while it looks similar, this is not the same Permit2 as other chains
            permit2: 0x0000000000225e31D15943971F47aD3022F714Fa,
            feeToken: 0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4
        });
    }
}
