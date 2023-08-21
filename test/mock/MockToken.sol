// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.19;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MT", 18) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
