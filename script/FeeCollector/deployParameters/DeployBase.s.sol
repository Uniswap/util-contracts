// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {DeployFeeCollector, DeployParameters} from "../DeployFeeCollector.s.sol";

contract DeployBase is DeployFeeCollector {
    function setUp() public override {
        params = DeployParameters({
            owner: OWNER,
            universalRouter: 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD,
            permit2: PERMIT2,
            feeToken: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
        });
    }
}
