// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice The collector of protocol fees that will be used to swap and send to a fee recipient address.
interface IFeeCollector {
    /// @notice 
    function swapBalances(ERC20[] memory tokens, bytes calldata call) external;

    /// @notice Transfers amount of token to a caller specified recipient.
    /// @param token The token to withdraw.
    /// @param to The address to send to
    /// @param amount The amount to withdraw.
    function withdrawToken(ERC20 token, address to, uint256 amount) external;
}
