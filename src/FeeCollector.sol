// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IFeeCollector} from "./interfaces/IFeeCollector.sol";
import {IPermit2} from "./external/IPermit2.sol";

/// @notice The collector of protocol fees that will be used to swap and send to a fee recipient address.
contract FeeCollector is Owned, IFeeCollector {
    using SafeTransferLib for ERC20;

    error InvalidUniversalRouterCalldata();

    address private immutable universalRouter;
    address private immutable feeRecipient;
    ERC20 private immutable feeToken;
    IPermit2 private immutable permit2;

    constructor(address _owner, address _universalRouter, address _permit2, address _feeRecipient, address _feeToken)
        Owned(_owner)
    {
        universalRouter = _universalRouter;
        feeRecipient = _feeRecipient;
        feeToken = ERC20(_feeToken);
        permit2 = IPermit2(_permit2);
    }

    /// @inheritdoc IFeeCollector
    function swapBalance(ERC20[] calldata tokensToApprove, bytes calldata swapData) external payable onlyOwner {
        for (uint256 i = 0; i < tokensToApprove.length; i++) {
            tokensToApprove[i].safeApprove(address(permit2), type(uint256).max);
            permit2.approve(address(tokensToApprove[i]), universalRouter, type(uint160).max, type(uint48).max);
        }

        (bool success,) = universalRouter.call{value: msg.value}(swapData);
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
