// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IUniversalRouter} from "./external/IUniversalRouter.sol";

/// @notice The collector of protocol fees that will be used to swap and send to a fee recipient address.
contract FeeCollector is Owned {
    /// @notice thrown if swap is called with a non-allowlisted caller
    error CallerNotAllowlisted();

    IUniversalRouter private immutable universalRouter;
    address private immutable allowlistedCaller;
    address private immutable usdcRecipient;
    ERC20 private immutable usdc;

    modifier onlyAllowlistedCaller() {
        if (msg.sender != allowlistedCaller) {
            revert CallerNotAllowlisted();
        }
        _;
    }

    constructor(address _allowlistedCaller, IUniversalRouter _universalRouter, address _usdcRecipient, address _usdc)
        Owned(owner)
    {
        allowlistedCaller = _allowlistedCaller;
        universalRouter = _universalRouter;
        usdcRecipient = _usdcRecipient;
        usdc = ERC20(_usdc);
    }

    /// @notice Swaps the token balances via universal router.
    /// @param tokens An array of token addresses for which balances will be swapped.
    /// @param commands Bytes data that specifies the arbitrary logic to execute in the universal router.
    /// @param inputs Array of bytes data to serve as inputs for each command executed by the universal router.
    /// @param deadline A timestamp indicating the latest time the operation is valid for.
    function swapBalance(address[] calldata tokens, bytes calldata commands, bytes[] calldata inputs, uint48 deadline)
        external
        onlyAllowlistedCaller
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                SafeTransferLib.safeTransfer(token, address(universalRouter), balance);
            }
        }

        universalRouter.execute(commands, inputs, deadline);
    }

    /// @notice Transfers the USDC balance from this contract to the USDC recipient.
    function withdrawUSDC() external onlyAllowlistedCaller {
        uint256 balance = usdc.balanceOf(address(this));
        if (balance > 0) {
            SafeTransferLib.safeTransfer(usdc, usdcRecipient, balance);
        }
    }
}
