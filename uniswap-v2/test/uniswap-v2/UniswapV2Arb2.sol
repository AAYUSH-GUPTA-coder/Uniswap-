// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IUniswapV2Pair} from "../../src/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import {IERC20} from "../../src/interfaces/IERC20.sol";

contract UniswapV2Arb2 {
    struct FlashSwapData {
        // Caller of flashSwap (msg.sender inside flashSwap)
        address caller;
        // Pair to flash swap from
        address pair0;
        // Pair to swap from
        address pair1;
        // True if flash swap is token0 in and token1 out
        bool isZeroForOne;
        // Amount in to repay flash swap
        uint256 amountIn;
        // Amount to borrow from flash swap
        uint256 amountOut;
        // Revert if profit is less than this minimum
        uint256 minProfit;
    }

    // Exercise 1
    // - Flash swap to borrow tokenOut
    /**
     * @param pair0 Pair contract to flash swap
     * @param pair1 Pair contract to swap
     * @param isZeroForOne True if flash swap is token0 in and token1 out.
     * if we are borrowing token 1 and then later repaying back token0, then isZeroForOne is TRUE
     * @param amountIn Amount in to repay flash swap
     * @param minProfit Minimum profit that this arbitrage must make
     */
    function flashSwap(
        address pair0,
        address pair1,
        bool isZeroForOne,
        uint256 amountIn,
        uint256 minProfit
    ) external {
        // Write your code here
        // Don’t change any other code

        // get the reserve of the token0 and token1 in pair0
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair0)
            .getReserves();

        // Hint - use getAmountOut to calculate amountOut to borrow

        // get amountOut = amount you want to borrow from FlashSwap
        uint256 amountOut = isZeroForOne
            ? getAmountOut(amountIn, reserve0, reserve1)
            : getAmountOut(amountIn, reserve1, reserve0);

        // encode data, to be used in flashswap and business logic
        bytes memory data = abi.encode(
            FlashSwapData({
                caller: msg.sender,
                pair0: pair0,
                pair1: pair1,
                isZeroForOne: isZeroForOne,
                amountIn: amountIn,
                amountOut: amountOut,
                minProfit: minProfit
            })
        );

        // initiate the flashswap
        /// @note if we are borrowing token 1 and then later repaying back token0, then isZeroForOne is TRUE
        IUniswapV2Pair(pair0).swap({
            amount0Out: isZeroForOne ? 0 : amountOut,
            amount1Out: isZeroForOne ? amountOut : 0,
            to: address(this),
            data: data
        });
    }

    // Uniswap V2 callback
    function uniswapV2Call(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) external {
        // Write your code here
        // Don’t change any other code

        // NOTE - anyone can call

        // decoding the encodind data, to be used in business logic
        FlashSwapData memory params = abi.decode(data, (FlashSwapData));

        // Token in and token out from flash swap
        address token0 = IUniswapV2Pair(params.pair0).token0();
        address token1 = IUniswapV2Pair(params.pair0).token1();

        /// @note if we are borrowing token 1 and then later repaying back token0, then isZeroForOne is TRUE
        (address tokenIn, address tokenOut) = params.isZeroForOne
            ? (token0, token1)
            : (token1, token0);

        // get token0 and token1 reserves
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(params.pair1)
            .getReserves();

        // calculate amountOut
        uint256 amountOut = params.isZeroForOne
            ? getAmountOut(params.amountOut, reserve1, reserve0)
            : getAmountOut(params.amountOut, reserve0, reserve1);

        // transfer the tokenOut amount to Different pair. in our case second AMM
        IERC20(tokenOut).transfer(params.pair1, params.amountOut);

        // Call the swap function of second AMM
        /// @note if we are borrowing token 1 and then later repaying back token0, then isZeroForOne is TRUE
        /// @note now the scenerio changes,
        IUniswapV2Pair(params.pair1).swap({
            amount0Out: params.isZeroForOne ? amountOut : 0,
            amount1Out: params.isZeroForOne ? 0 : amountOut,
            to: address(this),
            data: ""
        });

        // NOTE - no need to calculate flash swap fee
        IERC20(tokenIn).transfer(params.pair0, params.amountIn);

        uint256 profit = amountOut - params.amountIn;
        require(profit >= params.minProfit, "profit < min");
        IERC20(tokenIn).transfer(params.caller, profit);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
