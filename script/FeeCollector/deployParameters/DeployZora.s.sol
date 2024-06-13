// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeployFeeCollector, DeployParameters} from "../DeployFeeCollector.s.sol";

contract DeployZora is DeployFeeCollector {
    function setUp() public override {
        params = DeployParameters({
            owner: OWNER,
            universalRouter: 0x2986d9721A49838ab4297b695858aF7F17f38014,
            permit2: PERMIT2,
            feeToken: 0xCccCCccc7021b32EBb4e8C08314bD62F7c653EC4
        });
    }
}
