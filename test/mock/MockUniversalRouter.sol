// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

interface IMockUniversalRouter {
    function execute(bytes calldata swapData) external;
}

contract MockUniversalRouter {
    using SafeTransferLib for ERC20;

    constructor() {}

    function execute(bytes calldata swapData) external payable {
        (address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut) =
            abi.decode(swapData, (address, address, uint256, uint256));

        if (tokenIn != address(0)) {
            ERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        }

        ERC20(tokenOut).safeTransfer(msg.sender, amountOut);
    }
}
