// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IFeeCollector} from "./interfaces/IFeeCollector.sol";

/// @notice The collector of protocol fees that will be used to swap and send to a fee recipient address.
contract FeeCollector is Owned, IFeeCollector {
    using SafeTransferLib for ERC20;

    error CallFailed();

    address public feeRecipient;
    /// @notice the amount of fee token that must be paid per token
    uint256 public feeTokenAmount;
    /// @notice the token to receive fees in
    ERC20 private immutable feeToken;

    constructor(address _owner, address _feeToken, uint256 _feeTokenAmount) Owned(_owner) {
        feeToken = ERC20(_feeToken);
        feeTokenAmount = _feeTokenAmount;
    }

    /// @notice allow anyone to take the full balance of any arbitrary tokens
    /// @dev as long as they pay `feeTokenAmount` per token taken to the `feeRecipient`
    ///     this creates a competitive auction as the balances of this contract increase
    ///     to find the optimal path for the swap
    function swapBalances(ERC20[] memory tokens, bytes calldata call) external {
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].safeTransfer(msg.sender, tokens[i].balanceOf(address(this)));
        }
        (bool success,) = msg.sender.call(call);
        if (!success) {
            revert CallFailed();
        }

        feeToken.safeTransferFrom(msg.sender, feeRecipient, feeTokenAmount * tokens.length);
    }

    /// @inheritdoc IFeeCollector
    function withdrawToken(ERC20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function setFeeTokenAmount(uint256 _feeTokenAmount) external onlyOwner {
        feeTokenAmount = _feeTokenAmount;
    }

    receive() external payable {}
}
