pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

//import "./Interfaces.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract YourContract {
    //data values
    ISwapRouter public immutable swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    uint24 public constant poolFee = 3000;
    address DAI = 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735;
    address wETH = 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15;
    mapping(address => Channel) public channels;
    struct Channel {
        uint256 balance;
        uint256 frequency;
        uint256 lastPurchase;
        uint256 amountPerTx;
    }

    function openChannel(
        uint256 _deposit,
        uint256 _frequency,
        uint256 _amountPerTx
    ) public {
        //require(IERC20(DAI).approve(address(this), _deposit), "approval failed");
        require(
            IERC20(DAI).transferFrom(msg.sender, address(this), _deposit),
            "transferFrom failed, check approvals"
        );
        channels[msg.sender].balance += _deposit;
        channels[msg.sender].frequency = _frequency;
        channels[msg.sender].amountPerTx = _amountPerTx;
    }
    function swapExactInputSingle(address _user)
        external
        returns (uint256 amountOut)
    {
        uint amountIn = channels[_user].amountPerTx;
        /*
        TransferHelper.safeTransferFrom(
            DAI,
            msg.sender,
            address(this),
            amountIn
        );
        */
        TransferHelper.safeApprove(DAI, address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        .ExactInputSingleParams({
            tokenIn: DAI,
            tokenOut: wETH,
            fee: poolFee,
            recipient: _user,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        amountOut = swapRouter.exactInputSingle(params);
    }

    function closeChannel() public {
        IERC20(DAI).transfer(msg.sender, channels[msg.sender].balance);
        channels[msg.sender].balance = 1;
        channels[msg.sender].frequency = 0;
        channels[msg.sender].lastPurchase = 0;
    }
    /*
    function swap(address _user, uint amountOutMin) public {
        require(IERC20(DAI).approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, channels[_user].amountPerTx));
        address[] memory path;
        path[0] = DAI;
        path[1] = wETH;
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).swapExactTokensForETHSupportingFeeOnTransferTokens(channels[_user].amountPerTx, amountOutMin, path, _user, 1626912445);
    }
    */
}
