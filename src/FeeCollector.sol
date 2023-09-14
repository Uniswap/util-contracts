// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IFeeCollector} from "./interfaces/IFeeCollector.sol";

/// @notice The collector of protocol fees that will be used to swap and send to a fee recipient address.
contract FeeCollector is Owned, IFeeCollector {
    using SafeTransferLib for ERC20;

    error InvalidUniversalRouterCalldata();

    address private universalRouter;
    address private immutable feeRecipient;
    ERC20 private immutable feeToken;

    constructor(address _owner, address _universalRouter, address _feeRecipient, address _feeToken) Owned(_owner) {
        universalRouter = _universalRouter;
        feeRecipient = _feeRecipient;
        feeToken = ERC20(_feeToken);
    }

    function approveAndPermit(ERC20[] calldata tokensToApprove) external onlyOwner {
        for (uint256 i = 0; i < tokensToApprove.length; i++) {
            tokensToApprove[i].approve(address(universalRouter), type(uint256).max);
            tokensToApprove[i].permit(address(this), address(universalRouter), type(uint256).max, type(uint256).max);
        }
    }

    /// @inheritdoc IFeeCollector
    function swapBalance(bytes calldata universalRouterCalldata) external payable onlyOwner {
        (bool success,) = universalRouter.call{value: msg.value}(universalRouterCalldata);
        if (!success) revert InvalidUniversalRouterCalldata();
    }

    /// @inheritdoc IFeeCollector
    function withdrawFeeToken() external onlyOwner {
        uint256 balance = feeToken.balanceOf(address(this));
        if (balance > 0) {
            feeToken.safeTransfer(feeRecipient, balance);
        }
    }

    receive() external payable {}
}
