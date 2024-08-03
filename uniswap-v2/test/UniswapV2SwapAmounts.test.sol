// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "../../src/interfaces/IERC20.sol";
import {IWETH} from "../../src/interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../../src/interfaces/IUniswapV2Router02.sol";
import {DAI, WETH, MKR, UNISWAP_V2_ROUTER_02} from "../../src/Constants.sol";

contract UniswapV2SwapAmountsTest is Test {
    IWETH private constant weth = IWETH(WETH);
    IERC20 private constant dai = IERC20(DAI);
    IERC20 private constant mkr = IERC20(MKR);

    IUniswapV2Router02 private constant router =
        IUniswapV2Router02(UNISWAP_V2_ROUTER_02);

    // This test give us the amount of path[1], path[2], path[n] token we will get when swap x amount of path[0] token.
    // User WETH is swapped to DAI and then swapped to MKR
    // swapped means here, gives conversion rate
    function test_getAmountsOut() public {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountIn = 1e18;
        uint256[] memory amounts = router.getAmountsOut(amountIn, path);

        console2.log("WETH", amounts[0]);
        console2.log("DAI", amounts[1]);
        console2.log("MKR", amounts[2]);
    }

    //     WETH 1000000000000000000
    //   DAI 2957025828476064353307
    //   MKR 1223852775972498071

    // Give us the amount of token A we will get if we swap X amount of token B. for example get 1e18 MKR we will need to swap 2,416 amount of DAI.
    // User WETH is swapped to DAI and then swapped to MKR
    function test_getAmountsIn() public {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountOut = 1e18;
        uint256[] memory amounts = router.getAmountsIn(amountOut, path);

        console2.log("WETH", amounts[0]);
        console2.log("DAI", amounts[1]);
        console2.log("MKR", amounts[2]);
    }
}

// WETH 817022521691710738
//   DAI 2416144897248354520007
//   MKR 1000000000000000000
