// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";
import "v2-core/interfaces/IUniswapV2Pair.sol";

contract MockSellReentrancyFotToken is ERC20 {
    uint256 public taxBps;
    address public pair;

    constructor(uint256 _taxBps) ERC20("MockSellReentrancyFotToken", "MSFOT", 18) {
        taxBps = _taxBps;
    }

    function setPair(address _pair) external {
        pair = _pair;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    // this token re-enters the pair on sells only (since buys lock the pair)
    function transfer(address to, uint256 amount) public override returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        uint256 feeAmount;
        unchecked {
            if (to == pair || msg.sender == pair) {
                uint256 feeAmount = amount * taxBps / 10000;
                balanceOf[to] += amount - feeAmount;
                balanceOf[address(this)] += feeAmount;
            } else {
                balanceOf[to] += amount;
            }
        }

        // Only add in extra swap for sells
        if (to == pair) {
            IUniswapV2Pair(pair).token0() == address(this)
                ? IUniswapV2Pair(pair).swap(0, 0, address(this), new bytes(0))
                : IUniswapV2Pair(pair).swap(0, 0, address(this), new bytes(0));
        }

        emit Transfer(msg.sender, to, amount - feeAmount);

        return true;
    }
}
