// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice The collector of protocol fees that will be used to swap and send to a fee recipient address.
interface IFeeCollector {
    /// @notice Swaps the token balances via universal router.
    /// @param universalRouterCalldata The bytes call data to be forwarded to UniversalRouter.
    function swapBalance(bytes calldata universalRouterCalldata) external payable;

    function approveAndPermit(ERC20[] calldata tokensToApprove) external;

    /// @notice Transfers the USDC balance from this contract to the USDC recipient.
    function withdrawFeeToken() external;
}
