// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.16;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IUniversalRouter} from "../external/IUniversalRouter.sol";
import {IPermit2} from "permit2/interfaces/IPermit2.sol";
import {IAllowanceTransfer} from "permit2/interfaces/IAllowanceTransfer.sol";

/// @notice The recipient of protocol fees that will swap them for USDC
contract FeeCollector is Owned {
    /// @notice thrown if swap is called with a non-allowlisted caller
    error CallerNotAllowlisted();

    IUniversalRouter private immutable universalRouter;
    IAllowanceTransfer private immutable allowanceTransfer;
    IPermit2 private immutable permit2;
    address private immutable allowlistedCaller;
    address private immutable usdcRecipient;
    ERC20 private immutable usdc;

    modifier onlyAllowlistedCaller() {
        if (msg.sender != allowlistedCaller) {
            revert CallerNotAllowlisted();
        }
        _;
    }

    constructor(
        address _allowlistedCaller,
        IUniversalRouter _universalRouter,
        IPermit2 _permit2,
        IAllowanceTransfer _allowanceTransfer,
        address _usdcRecipient,
        address _usdc
    ) Owned(owner) {
        allowlistedCaller = _allowlistedCaller;
        universalRouter = _universalRouter;
        permit2 = _permit2;
        usdcRecipient = _usdcRecipient;
        allowanceTransfer = _allowanceTransfer;
        usdc = ERC20(_usdc);
    }

    function approveAndPermit(ERC20[] calldata tokensToApprove, uint8 v, bytes32 r, bytes32 s)
        external
        onlyAllowlistedCaller
    {
        for (uint256 i = 0; i < tokensToApprove.length; i++) {
            tokensToApprove[i].approve(address(permit2), type(uint256).max);

            (,, uint48 nonce) =
                permit2.allowance(address(this), address(tokensToApprove[i]), address(allowanceTransfer));

            permit2.permit(
                address(this),
                IAllowanceTransfer.PermitSingle({
                    details: IAllowanceTransfer.PermitDetails({
                        token: address(tokensToApprove[i]),
                        amount: type(uint160).max,
                        expiration: type(uint48).max,
                        nonce: nonce
                    }),
                    spender: address(allowanceTransfer),
                    sigDeadline: type(uint48).max
                }),
                abi.encodePacked(r, s, v)
            );
        }
    }

    function transferUSDC() external onlyAllowlistedCaller {
        uint256 balance = usdc.balanceOf(address(this));
        if (balance > 0) {
            SafeTransferLib.safeTransfer(usdc, usdcRecipient, balance);
        }
    }
}
