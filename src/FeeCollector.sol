// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IUniversalRouter} from "./external/IUniversalRouter.sol";
import {IFeeCollector} from "./interfaces/IFeeCollector.sol";

/// @notice The collector of protocol fees that will be used to swap and send to a fee recipient address.
contract FeeCollector is Owned, IFeeCollector {
    using SafeTransferLib for ERC20;

    IUniversalRouter private immutable universalRouter;
    address private immutable feeRecipient;
    ERC20 private immutable feeToken;

    constructor(address _owner, address _universalRouter, address _feeRecipient, address _feeToken) Owned(_owner) {
        universalRouter = IUniversalRouter(_universalRouter);
        feeRecipient = _feeRecipient;
        feeToken = ERC20(_feeToken);
    }

    /// @inheritdoc IFeeCollector
    function swapBalance(address[] calldata tokens, bytes calldata commands, bytes[] calldata inputs, uint48 deadline)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                token.safeTransfer(address(universalRouter), balance);
            }
        }

        universalRouter.execute(commands, inputs, deadline);
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
