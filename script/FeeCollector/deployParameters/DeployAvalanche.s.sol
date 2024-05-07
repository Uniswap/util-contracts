// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeployFeeCollector, DeployParameters} from "../DeployFeeCollector.s.sol";

contract DeployAvalanche is DeployFeeCollector {
    function setUp() public override {
        params = DeployParameters({
            owner: OWNER,
            universalRouter: 0x4Dae2f939ACf50408e13d58534Ff8c2776d45265,
            permit2: PERMIT2,
            feeToken: 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E
        });
    }
}
