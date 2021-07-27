pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

//import "./Interfaces.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract DCA {

    //data values
    ISwapRouter public immutable swapRouter;
    address public constant DAI =  0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735;
    address public constant WETH9 = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    uint24 public constant poolFee = 3000;

    mapping(address => Channel) public channels;
    struct Channel {
        uint256 balance;
        uint256 frequency;
        uint256 lastPurchase;
        uint256 amountPerTx;
    }

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    function openChannel(
        uint256 _deposit,
        uint256 _frequency,
        uint256 _amountPerTx
    ) public {
        //MUST APPROVE CONTRACT TO OPEN CHANNEL
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), _deposit);
        channels[msg.sender].balance += _deposit;
        channels[msg.sender].frequency = _frequency;
        channels[msg.sender].amountPerTx = _amountPerTx;
    }
    
    function closeChannel() public {
        TransferHelper.safeTransfer(DAI, msg.sender, channels[msg.sender].balance);
        channels[msg.sender].balance = 0;
        channels[msg.sender].frequency = 0;
        channels[msg.sender].lastPurchase = 0;
    }

    function swapExactInputSingle(address _user) external returns (uint256 amountOut) {
        uint256 amountIn = channels[_user].amountPerTx;
        TransferHelper.safeApprove(DAI, address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: DAI,
                tokenOut: WETH9,
                fee: poolFee,
                recipient: _user,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(params);
    }
}
