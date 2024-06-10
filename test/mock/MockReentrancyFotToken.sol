// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";
import "v2-core/interfaces/IUniswapV2Pair.sol";

contract MockReentrancyFotToken is ERC20 {
    uint256 public taxBps;
    address public pair;

    constructor(uint256 _taxBps) ERC20("MockReentrancyFotToken", "MFOT", 18) {
        taxBps = _taxBps;
    }

    function setPair(address _pair) external {
        pair = _pair;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    // this token takes a fee on all transfers, swapping it to ETH on the V2 pair
    function transfer(address to, uint256 amount) public override returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        uint256 feeAmount;
        unchecked {
            feeAmount = amount * taxBps / 10000;
            balanceOf[to] += amount - feeAmount;
            balanceOf[address(this)] += feeAmount;
        }

        // Only add in extra swap if is not buy/sell on the pair
        if (to != pair && msg.sender != pair) {
            IUniswapV2Pair(pair).token0() == address(this)
                ? IUniswapV2Pair(pair).swap(0, feeAmount, address(this), new bytes(0))
                : IUniswapV2Pair(pair).swap(feeAmount, 0, address(this), new bytes(0));
        }

        emit Transfer(msg.sender, to, amount - feeAmount);

        return true;
    }
}
