pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

//import "./Interfaces.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract UniTest {

    ISwapRouter public immutable swapRouter;
    address public constant DAI =  0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735;
    address public constant WETH9 = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    function swapExactInputSingle(uint256 amountIn) external returns (uint256 amountOut) {
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amountIn);
        TransferHelper.safeApprove(DAI, address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: DAI,
                tokenOut: WETH9,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(params);
    }
}
