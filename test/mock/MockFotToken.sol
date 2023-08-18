// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract MockFotToken is ERC20 {
    uint256 public buyTaxBps;
    uint256 public sellTaxBps;
    address public pair;

    constructor(uint256 _buyTaxBps, uint256 _sellTaxBps) ERC20("MockFotToken", "MFOT", 18) {
        buyTaxBps = _buyTaxBps;
        sellTaxBps = _sellTaxBps;
    }

    function setPair(address _pair) external {
        pair = _pair;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

   function transfer(address to, uint256 amount) public override returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            if (to == pair) {
                uint256 feeAmount = amount * sellTaxBps / 10000;
                balanceOf[to] += amount - feeAmount;
                balanceOf[address(this)] += feeAmount;
            } else if (msg.sender == pair) {
                uint256 feeAmount = amount * buyTaxBps / 10000;
                balanceOf[to] += amount - feeAmount;
                balanceOf[address(this)] += feeAmount;
            } else {
                balanceOf[to] += amount;
            }
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }
}
