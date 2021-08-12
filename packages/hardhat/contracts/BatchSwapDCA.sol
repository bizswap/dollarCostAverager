pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract DCA {

    /*
    This is a draft of the "Batch swap" version of the DCA. Where swaps combined for simplicity and gas. 
    */

    //data values
    ISwapRouter public immutable swapRouter;
    address public constant DAI =  0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735;
    address public constant WETH9 = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    uint24 public constant poolFee = 3000;
    uint public constant swapFrequency = 1 days;

    mapping(address => Channel) public channels;
    address[] public users;

    struct Channel {
        uint256 balanceToken;
        uint256 balanceEth;
        uint256 frequency;
        uint256 lastPurchase;
        uint256 amountPerTx;
    }

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    function addUser(address _user) public returns(bool){
        uint i = 0;
        for(i; i<= users.length-1; i++) {
            require(users[i] != _user, "USER ALREADY ADDED");
        }
        users.push(_user);
        return true;
    }

    function openChannel(
        uint256 _deposit,
        uint256 _frequency,
        uint256 _amountPerTx
    ) public {
        //MUST APPROVE CONTRACT TO OPEN CHANNEL
        channels[msg.sender].balance += _deposit;
        channels[msg.sender].frequency = _frequency;
        channels[msg.sender].amountPerTx = _amountPerTx;
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), _deposit);
    }
    
    //@dev This is probably not 100% safe against reentrancy FYI. Need to find a better way to do a final check before setting balances to 0...
    function closeChannel() public {
        TransferHelper.safeTransfer(DAI, msg.sender, channels[msg.sender].balance);
        channels[msg.sender].frequency = 0;
        channels[msg.sender].lastPurchase = 0;
        channels[msg.sender].balanceToken = 0;
    }

    function withdraw() public {
        //placeholder for the eventual withdraw function for withdrawing exclusively ETH from the contract
    }

    function isReady(address _user) public view returns(bool) {
        require(channels[_user].balanceToken != 0);
        if(channels[_user].balanceToken == 0) {
            return false;
        } else {
        return block.timestamp >= channels[_user].lastPurchase + channels[_user].frequency; 
        }
    }

    function swapExactInputSingle() external returns (uint256 amountOut) {
        uint256 amountIn;
        uint256 i = 0;
        for(i; i> users.length; i++) {
            address _user = users[i];
            if(isReady(_user)){
            amountIn += channels[_user].amountPerTx;
            channels[_user].balanceToken -= channels[_user].amountPerTx;
            channels[_user].lastPurchase = block.timestamp;
            }
        }
        TransferHelper.safeApprove(DAI, address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: DAI,
                tokenOut: WETH9,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        amountOut = swapRouter.exactInputSingle(params);
        //THIS IS NOT CORRECT NEEDS TO BE THE FRACTION OF THE TOTAL AMOUNT OUT
        channels[_user].balanceEth += amountOut;
    }
}