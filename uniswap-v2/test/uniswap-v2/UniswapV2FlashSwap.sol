// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IUniswapV2Pair} from "../../src/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import {IERC20} from "../../src/interfaces/IERC20.sol";

error ONLY_PAIR_CAN_CALL();
error SENDER_IS_NOT_THIS_ADDRESS();

contract UniswapV2FlashSwap {
    IUniswapV2Pair private immutable pair;
    address private immutable token0;
    address private immutable token1;

    constructor(address _pair) {
        pair = IUniswapV2Pair(_pair);
        token0 = pair.token0();
        token1 = pair.token1();
    }

    function flashSwap(address token, uint256 amount) external {
        require(token == token0 || token == token1, "invalid token");

        // Write your code here
        // Don’t change any other code

        // 1. Determine amount0Out and amount1Out
        // (uint256 amount0Out, uint256 amount1Out) = (0, 0);
        (uint256 amount0Out, uint256 amount1Out) = token == token0
            ? (amount, uint256(0))
            : (uint256(0), amount);

        // 2. Encode token and msg.sender as bytes
        bytes memory data = abi.encode(token, msg.sender);

        // 3. Call pair.swap
        pair.swap(amount0Out, amount1Out, address(this), data);
    }

    // Uniswap V2 callback
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        // Write your code here
        // Don’t change any other code

        // 1. Require msg.sender is pair contract
        if (address(pair) != msg.sender) revert ONLY_PAIR_CAN_CALL();
        // 2. Require sender is this contract
        if (sender != address(this)) revert SENDER_IS_NOT_THIS_ADDRESS();
        // Alice -> FlashSwap ---- to = FlashSwap ----> UniswapV2Pair
        //                    <-- sender = FlashSwap --
        // Eve ------------ to = FlashSwap -----------> UniswapV2Pair
        //          FlashSwap <-- sender = Eve --------

        // 3. Decode token and caller from data
        // (address token, address caller) = (address(0), address(0));
        (address token, address caller) = abi.decode(data, (address, address));
        // 4. Determine amount borrowed (only one of them is > 0)
        // uint256 amount = 0;
        uint256 amount = amount0 > 0 ? amount0 : amount1;

        // 5. Calculate flash swap fee and amount to repay
        // fee = borrowed amount * 3 / 997 + 1 to round up
        // uint256 fee = 0;
        uint256 fee = (amount * 3) / 997 + 1;
        // uint256 amountToRepay = 0;
        uint256 amountToRepay = amount + fee;

        // 6. Get flash swap fee from caller
        IERC20(token).transferFrom(caller, address(this), fee);
        // 7. Repay Uniswap V2 pair
        IERC20(token).transfer(address(pair), amountToRepay);
    }
}
