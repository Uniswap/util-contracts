// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

interface FeeCollectorEvents {
    /// @notice Emitted when the UniversalRouter address is changed.
    /// @param oldUniversalRouter The old router address.
    /// @param newUniversalRouter The new router address.
    event UniversalRouterChanged(address oldUniversalRouter, address newUniversalRouter);
}
