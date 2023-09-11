// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.16;

import {IUniversalRouter} from "../external/IUniversalRouter.sol";

/// @notice The recipient of protocol fees that will swap them for USDC
contract FeeCollector {
    IUniversalRouter private immutable universalRouter;
}
