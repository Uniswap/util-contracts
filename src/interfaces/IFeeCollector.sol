// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice The collector of protocol fees that will be used to swap and send to a fee recipient address.
interface IFeeCollector {
    /// @notice Swaps the token balances via universal router.
    /// @param tokensToApprove An array of ERC20 tokens to approve for spending by UniversalRouter.
    /// @param swapData The bytes call data to be forwarded to UniversalRouter.
    function swapBalance(ERC20[] calldata tokensToApprove, bytes calldata swapData) external payable;

    /// @notice Transfers the fee token balance from this contract to the fee recipient.
    function withdrawFeeToken() external;
}
