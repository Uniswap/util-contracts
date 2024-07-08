// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.19;
pragma abicoder v2;

import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "v2-core/interfaces/IUniswapV2Pair.sol";
import "./lib/UniswapV2Library.sol";

struct TokenFees {
    uint256 buyFeeBps;
    uint256 sellFeeBps;
    bool feeTakenOnTransfer;
    bool externalTransferFailed;
    bool sellReverted;
}

/// @notice Detects the buy and sell fee for a fee-on-transfer token
contract FeeOnTransferDetector {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    error SameToken();
    error PairLookupFailed();
    error UnknownExternalTransferFailure(string reason);

    uint256 constant BPS = 10_000;
    address internal immutable factoryV2;

    constructor(address _factoryV2) {
        factoryV2 = _factoryV2;
    }

    /// @notice detects FoT fees for a single token
    function validate(address token, address baseToken, uint256 amountToBorrow)
        public
        returns (TokenFees memory fotResult)
    {
        return _validate(token, baseToken, amountToBorrow);
    }

    /// @notice detects FoT fees for a batch of tokens
    function batchValidate(address[] calldata tokens, address baseToken, uint256 amountToBorrow)
        public
        returns (TokenFees[] memory fotResults)
    {
        fotResults = new TokenFees[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            fotResults[i] = _validate(tokens[i], baseToken, amountToBorrow);
        }
    }

    function _validate(address token, address baseToken, uint256 amountToBorrow)
        internal
        returns (TokenFees memory result)
    {
        if (token == baseToken) {
            revert SameToken();
        }

        address pairAddress = UniswapV2Library.pairFor(factoryV2, token, baseToken);

        // If the token/baseToken pair exists, get token0.
        // Must do low level call as try/catch does not support case where contract does not exist.
        (, bytes memory returnData) =
            address(pairAddress).staticcall(abi.encodeWithSelector(IUniswapV2Pair.token0.selector));

        if (returnData.length == 0) {
            revert PairLookupFailed();
        }

        address token0Address = abi.decode(returnData, (address));

        // Flash loan {amountToBorrow}
        (uint256 amount0Out, uint256 amount1Out) =
            token == token0Address ? (amountToBorrow, uint256(0)) : (uint256(0), amountToBorrow);

        uint256 detectorBalanceBeforeLoan = ERC20(token).balanceOf(address(this));

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        try pair.swap(amount0Out, amount1Out, address(this), abi.encode(detectorBalanceBeforeLoan, amountToBorrow)) {}
        catch (bytes memory reason) {
            result = parseRevertReason(reason);
        }
    }

    function parseRevertReason(bytes memory reason) private pure returns (TokenFees memory) {
        if (reason.length != 160) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        } else {
            return abi.decode(reason, (TokenFees));
        }
    }

    function uniswapV2Call(address, uint256 amount0, uint256, bytes calldata data) external {
        IUniswapV2Pair pair = IUniswapV2Pair(msg.sender);
        (address token0, address token1) = (pair.token0(), pair.token1());

        ERC20 tokenBorrowed = ERC20(amount0 > 0 ? token0 : token1);

        (uint256 detectorBalanceBeforeLoan, uint256 amountRequestedToBorrow) = abi.decode(data, (uint256, uint256));
        uint256 amountBorrowed = tokenBorrowed.balanceOf(address(this)) - detectorBalanceBeforeLoan;

        uint256 buyFeeBps = _calculateBuyFee(amountRequestedToBorrow, amountBorrowed);

        (bool feeTakenOnTransfer, bool externalTransferFailed) =
            tryExternalTransferAndRevert(tokenBorrowed, amountBorrowed);

        (uint256 sellFeeBps, bool sellReverted) = _calculateSellFee(pair, tokenBorrowed, amountBorrowed, buyFeeBps);

        bytes memory fees = abi.encode(
            TokenFees({
                buyFeeBps: buyFeeBps,
                sellFeeBps: sellFeeBps,
                feeTakenOnTransfer: feeTakenOnTransfer,
                externalTransferFailed: externalTransferFailed,
                sellReverted: sellReverted
            })
        );

        // revert with the abi encoded fees
        assembly {
            revert(add(32, fees), mload(fees))
        }
    }

    /// @notice simple helper function to calculate the buy fee in bps
    function _calculateBuyFee(uint256 amountRequestedToBorrow, uint256 amountBorrowed)
        internal
        pure
        returns (uint256 buyFeeBps)
    {
        buyFeeBps = (amountRequestedToBorrow - amountBorrowed).mulDivUp(BPS, amountRequestedToBorrow);
    }

    /// @notice helper function to calculate the sell fee in bps
    /// - in the case where the transfer fails, we set the sell fee to be the same as the buy fee
    function _calculateSellFee(IUniswapV2Pair pair, ERC20 tokenBorrowed, uint256 amountBorrowed, uint256 buyFeeBps)
        internal
        returns (uint256 sellFeeBps, bool sellReverted)
    {
        uint256 pairBalanceBeforeSell = tokenBorrowed.balanceOf(address(pair));
        try this.callTransfer(tokenBorrowed, address(pair), amountBorrowed) {
            uint256 amountSold = tokenBorrowed.balanceOf(address(pair)) - pairBalanceBeforeSell;
            uint256 sellFee = amountBorrowed - amountSold;
            sellFeeBps = sellFee.mulDivUp(BPS, amountBorrowed);
        } catch (bytes memory) {
            sellFeeBps = buyFeeBps;
            sellReverted = true;
        }
    }

    /// @notice some tokens take fees even when not buy/selling to the pair,
    ///         or they fail when transferred within the context of an existing swap
    /// @return feeTakenOnTransfer boolean indicating whether or not a fee is taken on transfers not involving the pair
    /// @return externalTransferFailed boolean indicating whether or not the external transfer failed
    function tryExternalTransferAndRevert(ERC20 tokenBorrowed, uint256 amountBorrowed)
        internal
        returns (bool feeTakenOnTransfer, bool externalTransferFailed)
    {
        uint256 balanceBeforeLoan = tokenBorrowed.balanceOf(factoryV2);
        try this.callTransfer(tokenBorrowed, factoryV2, amountBorrowed, balanceBeforeLoan + amountBorrowed) {}
        catch (bytes memory revertData) {
            if (revertData.length > 32) {
                // transfer itself failed so we did not return abi-encoded `feeTakenOnTransfer` boolean variable
                assembly {
                    revertData := add(revertData, 0x04)
                }
                string memory reason = abi.decode(revertData, (string));
                if (keccak256(bytes(reason)) == keccak256(bytes("TRANSFER_FAILED"))) {
                    externalTransferFailed = true;
                } else {
                    revert UnknownExternalTransferFailure(reason);
                }
            } else {
                feeTakenOnTransfer = abi.decode(revertData, (bool));
            }
        }
    }

    // external wrapper around safeTransfer
    // because try/catch does not handle calling libraries
    function callTransfer(ERC20 token, address to, uint256 amount) external {
        token.safeTransfer(to, amount);
    }

    // function that reverts with a boolean indicating whether or not a fee is taken on the token transfer
    // bubbles up any reverts from the token transfer
    function callTransfer(ERC20 token, address to, uint256 amount, uint256 expectedBalance) external {
        try this.callTransfer(token, to, amount) {}
        catch (bytes memory revertData) {
            if (revertData.length < 68) revert();
            assembly {
                revertData := add(revertData, 0x04)
            }
            revert(abi.decode(revertData, (string)));
        }
        bytes memory feeTakenOnTransfer = abi.encode(token.balanceOf(to) != expectedBalance);
        assembly {
            revert(add(32, feeTakenOnTransfer), mload(feeTakenOnTransfer))
        }
    }
}
