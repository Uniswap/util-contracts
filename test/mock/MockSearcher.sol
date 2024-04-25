// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {FeeCollector} from "../../src/FeeCollector.sol";

contract MockSearcher {
    FeeCollector public immutable feeCollector;

    constructor(address payable _feeCollector) {
        feeCollector = FeeCollector(_feeCollector);
        // approve feeCollector to spend feeToken from this contract
        ERC20(feeCollector.feeToken()).approve(address(feeCollector), type(uint256).max);
    }

    function swapBalances(ERC20[] memory tokens, bytes calldata call) external {
        feeCollector.swapBalances(tokens, call);
    }

    fallback() external {
        if (msg.sender != address(feeCollector)) {
            revert("Unauthorized");
        }
    }
}
