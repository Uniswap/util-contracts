// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract MockFotTokenWithExternalFees is ERC20 {
    uint256 public taxBps;
    address public pair;

    constructor(uint256 _taxBps) ERC20("MockFotToken", "MFOT", 18) {
        taxBps = _taxBps;
    }

    function setPair(address _pair) external {
        pair = _pair;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    // this token takes fees on ALL transfers, treating transfers to other addresses as sells
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

        emit Transfer(msg.sender, to, amount - feeAmount);

        return true;
    }
}
