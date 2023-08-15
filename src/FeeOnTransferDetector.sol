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
    string internal constant FOT_REVERT_STRING = "FOT";
    // https://github.com/Uniswap/v2-core/blob/1136544ac842ff48ae0b1b939701436598d74075/contracts/UniswapV2Pair.sol#L46
    string internal constant STF_REVERT_STRING_SUFFIX = "TRANSFER_FAILED";
    address internal immutable factoryV2;

    constructor(address _factoryV2) {
        factoryV2 = _factoryV2;
    }

    function batchValidate(address[] calldata tokens, address[] calldata baseTokens, uint256 amountToBorrow)
        public
        override
        returns (TokenFees[] memory fotResults)
    {
        fotResults = new TokenFees[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            fotResults[i] = validate(tokens[i], baseTokens, amountToBorrow);
        }
    }

    function validate(address token, address[] calldata baseTokens, uint256 amountToBorrow)
        public
        override
        returns (TokenFees memory)
    {
        for (uint256 i = 0; i < baseTokens.length; i++) {
            return _validate(token, baseTokens[i], amountToBorrow);
        }
    }

    function _validate(address token, address baseToken, uint256 amountToBorrow) internal returns (TokenFees memory) {
        if (token == baseToken) {
            return TokenFees(0, 0);
        }

        address pairAddress = UniswapV2Library.pairFor(this.factoryV2(), token, baseToken);

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
        catch Error(string memory reason) {
            return abi.decode(bytes(reason), (TokenFees));
        }

        // Swap always reverts so should never reach.
        revert("Unexpected error");
    }

    function isFotFailed(string memory reason) internal pure returns (bool) {
        return keccak256(bytes(reason)) == keccak256(bytes(FOT_REVERT_STRING));
    }

    function isTransferFailed(string memory reason) internal pure returns (bool) {
        // We check the suffix of the revert string so we can support forks that
        // may have modified the prefix.
        string memory stf = STF_REVERT_STRING_SUFFIX;

        uint256 reasonLength = bytes(reason).length;
        uint256 suffixLength = bytes(stf).length;
        if (reasonLength < suffixLength) {
            return false;
        }

        uint256 ptr;
        uint256 offset = 32 + reasonLength - suffixLength;
        bool transferFailed;
        assembly {
            ptr := add(reason, offset)
            let suffixPtr := add(stf, 32)
            transferFailed := eq(keccak256(ptr, suffixLength), keccak256(suffixPtr, suffixLength))
        }

        return transferFailed;
    }

    function uniswapV2Call(address, uint256 amount0, uint256, bytes calldata data) external view override {
        IUniswapV2Pair pair = IUniswapV2Pair(msg.sender);
        (address token0, address token1) = (pair.token0(), pair.token1());

        ERC20 tokenBorrowed = ERC20(amount0 > 0 ? token0 : token1);

        (uint256 balanceBeforeLoan, uint256 amountRequestedToBorrow) = abi.decode(data, (uint256, uint256));
        uint256 amountBorrowed = tokenBorrowed.balanceOf(address(this)) - balanceBeforeLoan;

        uint256 sellTax = amountBorrowed - amountRequestedToBorrow;
        balanceBeforeLoan = tokenBorrowed.balanceOf(address(pair));
        tokenBorrowed.transfer(address(pair), amountBorrowed);
        uint256 buyTax = tokenBorrowed.balanceOf(address(pair)) - balanceBeforeLoan - amountBorrowed;
        revert(
            abi.encode(
                TokenFees({
                    buyTaxBps: buyTax * 10000 / amountRequestedToBorrow,
                    sellTaxBps: sellTax * 10000 / amountBorrowed
                })
            )
        );
    }
}
