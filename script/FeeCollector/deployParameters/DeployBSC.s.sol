// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeployFeeCollector, DeployParameters} from "../DeployFeeCollector.s.sol";

contract DeployBSC is DeployFeeCollector {
    function setUp() public override {
        params = DeployParameters({
            owner: OWNER,
            universalRouter: 0x4Dae2f939ACf50408e13d58534Ff8c2776d45265,
            permit2: PERMIT2,
            feeToken: 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d
        });
    }
}
