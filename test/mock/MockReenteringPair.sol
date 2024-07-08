// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.19;

contract MockReenteringPair {
    fallback() external {
        // re-enter the caller
        (bool success,) = address(msg.sender).call(
            abi.encodeWithSignature("validate(address,address,uint256)", address(0), address(1), 0)
        );
        require(success, "re-enter failed");
    }
}
