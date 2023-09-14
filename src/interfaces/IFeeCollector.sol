// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

/// @notice The collector of protocol fees.
interface IFeeCollector {
    /// @notice Swaps the token balances via universal router.
    /// @param tokens An array of token addresses for which balances will be swapped.
    /// @param commands Bytes data that specifies the arbitrary logic to execute in the universal router.
    /// @param inputs Array of bytes data to serve as inputs for each command executed by the universal router.
    /// @param deadline A timestamp indicating the latest time the operation is valid for.
    function swapBalance(address[] calldata tokens, bytes calldata commands, bytes[] calldata inputs, uint48 deadline)
        external;

    /// @notice Transfers the USDC balance from this contract to the USDC recipient.
    function withdrawFeeToken() external;
}
