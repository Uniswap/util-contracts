// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.19;
pragma abicoder v2;

import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";
import "v2-core/interfaces/IUniswapV2Pair.sol";
import "./lib/UniswapV2Library.sol";

struct TokenFees {
    uint256 buyFeeBps;
    uint256 sellFeeBps;
    bool hasExternalFees;
}

/// @notice Detects the buy and sell fee for a fee-on-transfer token
contract FeeOnTransferDetector {
    using SafeTransferLib for ERC20;

    error SameToken();
    error PairLookupFailed();

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
        (, bytes memory returnData) = address(pairAddress).call(abi.encodeWithSelector(IUniswapV2Pair.token0.selector));

        if (returnData.length == 0) {
            revert PairLookupFailed();
        }

        address token0Address = abi.decode(returnData, (address));

        // Flash loan {amountToBorrow}
        (uint256 amount0Out, uint256 amount1Out) =
            token == token0Address ? (amountToBorrow, uint256(0)) : (uint256(0), amountToBorrow);

        uint256 balanceBeforeLoan = ERC20(token).balanceOf(address(this));

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        try pair.swap(amount0Out, amount1Out, address(this), abi.encode(balanceBeforeLoan, amountToBorrow)) {}
        catch (bytes memory reason) {
            result = parseRevertReason(reason);
        }
    }

    function parseRevertReason(bytes memory reason) private pure returns (TokenFees memory) {
        if (reason.length != 96) {
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

        (uint256 balanceBeforeLoan, uint256 amountRequestedToBorrow) = abi.decode(data, (uint256, uint256));
        uint256 amountBorrowed = tokenBorrowed.balanceOf(address(this)) - balanceBeforeLoan;

        uint256 buyFeeBps = (amountRequestedToBorrow - amountBorrowed) * BPS / amountRequestedToBorrow;

        // check to see if token has external transfer fees
        bool hasExternalFees;
        balanceBeforeLoan = tokenBorrowed.balanceOf(msg.sender);
        try this.callTransfer(tokenBorrowed, msg.sender, amountBorrowed, balanceBeforeLoan + amountBorrowed) {} 
        catch (bytes memory) {
            hasExternalFees = abi.decode(data, (bool));
        }

        balanceBeforeLoan = tokenBorrowed.balanceOf(address(pair));
        uint256 sellFeeBps;
        try this.callTransfer(tokenBorrowed, address(pair), amountBorrowed) {
            uint256 sellFee = amountBorrowed - (tokenBorrowed.balanceOf(address(pair)) - balanceBeforeLoan);
            sellFeeBps = sellFee * BPS / amountBorrowed;
        } catch (bytes memory) {
            sellFeeBps = buyFeeBps;
        }

        bytes memory fees = abi.encode(TokenFees({buyFeeBps: buyFeeBps, sellFeeBps: sellFeeBps, hasExternalFees: hasExternalFees}));

        // revert with the abi encoded fees
        assembly {
            revert(add(32, fees), mload(fees))
        }
    }

    // external wrapper around safeTransfer
    // because try/catch does not handle calling libraries
    function callTransfer(ERC20 token, address to, uint256 amount) external {
        token.safeTransfer(to, amount);
    }

    function callTransfer(ERC20 token, address to, uint256 amount, uint256 expectedBalance) external {
        token.safeTransfer(to, amount);
        bytes memory reason = token.balanceOf(to) == expectedBalance ? abi.encode(false) : abi.encode(true);
        assembly {
            revert(add(32, reason), mload(reason))
        }
    }
}
