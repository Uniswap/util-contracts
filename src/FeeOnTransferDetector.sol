// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.19;
pragma abicoder v2;

import "solmate/tokens/ERC20.sol";
import "v2-core/interfaces/IUniswapV2Pair.sol";
import "./UniswapV2Library.sol";

struct TokenFees {
    uint256 buyTaxBps;
    uint256 sellTaxBps;
}

/// @notice Detects the buy and sell tax for a fee-on-transfer token
contract FeeOnTransferDetector {
    address internal immutable factoryV2;

    constructor(address _factoryV2) {
        factoryV2 = _factoryV2;
    }

    function batchValidate(address[] calldata tokens, address baseToken, uint256 amountToBorrow)
        public
        returns (TokenFees[] memory fotResults)
    {
        fotResults = new TokenFees[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            fotResults[i] = _validate(tokens[i], baseToken, amountToBorrow);
        }
    }

    function _validate(address token, address baseToken, uint256 amountToBorrow) internal returns (TokenFees memory) {
        if (token == baseToken) {
            return TokenFees(0, 0);
        }

        address pairAddress = UniswapV2Library.pairFor(factoryV2, token, baseToken);

        // If the token/baseToken pair exists, get token0.
        // Must do low level call as try/catch does not support case where contract does not exist.
        (, bytes memory returnData) = address(pairAddress).call(abi.encodeWithSelector(IUniswapV2Pair.token0.selector));

        if (returnData.length == 0) {
            return TokenFees(0, 0);
        }

        address token0Address = abi.decode(returnData, (address));

        // Flash loan {amountToBorrow}
        (uint256 amount0Out, uint256 amount1Out) =
            token == token0Address ? (amountToBorrow, uint256(0)) : (uint256(0), amountToBorrow);

        uint256 balanceBeforeLoan = ERC20(token).balanceOf(address(this));

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        try pair.swap(amount0Out, amount1Out, address(this), abi.encode(balanceBeforeLoan, amountToBorrow)) {}
        catch (bytes memory reason) {
            return parseRevertReason(reason);
        }

        // Swap always reverts so should never reach.
        revert("Unexpected error");
    }

    function parseRevertReason(bytes memory reason) private pure returns (TokenFees memory) {
        if (reason.length != 256 * 2) {
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

        uint256 sellTax = amountBorrowed - amountRequestedToBorrow;
        balanceBeforeLoan = tokenBorrowed.balanceOf(address(pair));
        tokenBorrowed.transfer(address(pair), amountBorrowed);
        uint256 buyTax = tokenBorrowed.balanceOf(address(pair)) - balanceBeforeLoan - amountBorrowed;

        bytes memory fees = abi.encode(
            TokenFees({
                buyTaxBps: buyTax * 10000 / amountRequestedToBorrow,
                sellTaxBps: sellTax * 10000 / amountBorrowed
            })
        );
        assembly {
            revert(add(32, fees), mload(fees))
        }
    }
}
