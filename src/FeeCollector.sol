// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IFeeCollector} from "./interfaces/IFeeCollector.sol";

/// @notice The collector of protocol fees that will be used to swap and send to a fee recipient address.
contract FeeCollector is Owned, IFeeCollector {
    using SafeTransferLib for ERC20;

    error CallFailed();

    struct Call {
        address to;
        bytes data;
    }

    address public feeRecipient;
    uin256 public feeTokenAmount;
    ERC20 private immutable feeToken;

    constructor(address _owner, address _feeToken, uint256 _feeTokenAmount) Owned(_owner) {
        feeToken = ERC20(_feeToken);
        feeTokenAmount = _feeTokenAmount;
    }

    /// @notice allow anyone to make any arbitrary calls from this address
    /// @dev as long as they pay `feeTokenAmount` to the `feeRecipient`
    ///     this creates a competitive auction as the balances of this contract increase
    ///     to find the optimal path for the swap
    function swapBalances(Call[] calldata calls) external {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, ) = calls[i].to.call(calls[i].data);
            if (!success) {
                revert CallFailed();
            }
        }

        feeToken.safeTransferFrom(msg.sender, feeRecipient, feeTokenAmount);
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function setFeeToken(uint256 _feeTokenAmount) external onlyOwner {
        feeTokenAmount = _feeTokenAmount;
    }

    function setFeeTokenAmount(uint256 _feeTokenAmount) external onlyOwner {
        feeTokenAmount = _feeTokenAmount;
    }

    receive() external payable {}
}
