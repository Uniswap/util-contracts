// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import {Owned} from "solmate/src/auth/Owned.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {IUniversalRouter} from "universal-router/contracts/interfaces/IUniversalRouter.sol";
import {IFeeCollector} from "./interfaces/IFeeCollector.sol";

contract FeeCollector is Owned, IFeeCollector {
    using SafeTransferLib for ERC20;

    IUniversalRouter immutable universalRouter;
    address immutable usdcRecipient;
    ERC20 immutable usdc;

    constructor(address _owner, IUniversalRouter _universalRouter, address _usdcRecipient, address _usdc)
        Owned(_owner)
    {
        universalRouter = _universalRouter;
        usdcRecipient = _usdcRecipient;
        usdc = ERC20(_usdc);
    }

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

    function withdrawUSDC() external onlyOwner {
        uint256 balance = usdc.balanceOf(address(this));
        if (balance > 0) {
            usdc.safeTransfer(usdcRecipient, balance);
        }
    }
}
