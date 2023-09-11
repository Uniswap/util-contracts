// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.16;

import {Owned} from "solmate/auth/Owned.sol";
import {IUniversalRouter} from "../external/IUniversalRouter.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

/// @notice The recipient of protocol fees that will swap them for USDC
contract FeeCollector is Owned {
    /// @notice thrown if swap is called with a non-allowlisted caller
    error CallerNotAllowlisted();

    IUniversalRouter private immutable universalRouter;
    address private immutable allowlistedCaller;

    modifier onlyWhitelistedCaller() {
        if (msg.sender != allowlistedCaller) {
            revert CallerNotAllowlisted();
        }
        _;
    }

    constructor(address _allowlistedCaller, IUniversalRouter _universalRouter, IPermit2 _permit2) Owned(owner) {
        allowlistedCaller = _allowlistedCaller;
        universalRouter = _universalRouter;
    }

    function approveAndPermit
}
