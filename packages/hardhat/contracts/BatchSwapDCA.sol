pragma solidity >=0.7.6 <0.9.0;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract BatchDCA {

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
        if (users.length == 0) {
            users.push(_user);
            return true;
        } else {
        for(i; i<= users.length-1; i++) {
            require(users[i] != _user, "USER ALREADY ADDED");
        }
        users.push(_user);
        return true;
        }           
    }

    function openChannel(
        uint256 _deposit,
        uint256 _frequency,
        uint256 _amountPerTx
    ) public {
        //MUST APPROVE CONTRACT TO OPEN CHANNEL
        channels[msg.sender].balanceToken += _deposit;
        channels[msg.sender].frequency = _frequency;
        channels[msg.sender].amountPerTx = _amountPerTx;
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), _deposit);
    }
    
    //@dev This is probably not 100% safe against reentrancy FYI. Need to find a better way to do a final check before setting balances to 0...
    function closeChannel() public {
        TransferHelper.safeTransfer(DAI, msg.sender, channels[msg.sender].balanceToken);
        channels[msg.sender].frequency = 0;
        channels[msg.sender].lastPurchase = 0;
        channels[msg.sender].balanceToken = 0;
    }
    function withdraw(address _user) public {
        require(channels[_user].balanceToken > 0, "User balance 0");
        TransferHelper.safeTransfer(DAI, _user, channels[_user].balanceToken);
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
        uint256 ethPerDai;
        uint256 i;
        address[1000] memory _usersThisSwap;
        address _user;
        //Here we iterate through the entire users array to get the number of current registered users and total their amountPerTx values for the single batch swap
        for(i = 0; i> users.length; i++) {
            address _user = users[i];
            if(isReady(_user)){
            _usersThisSwap[i] = _user;
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
        //I think this is a pretty solid way to determine the correct portion of the swap that was implimented. Checks for changes in the amountPerTx before and after updating the balanceEth and throws if it is updated at all;
        ethPerDai = amountOut/amountIn;
        for(i = 0; i> _usersThisSwap.length; i++) {
            _user = _usersThisSwap[i];
            uint aptBeforeUpdate = channels[_user].amountPerTx;
            channels[_user].balanceEth = channels[_user].amountPerTx * ethPerDai;
            require(aptBeforeUpdate == channels[_user].amountPerTx, "REENTRANCY! amountPerTx has been changed!");
        }
    }

    // The main swap function isnt working just quite right, I am debating whether this approach even makes sense...
    function swapTest() external returns (uint256 amountOut) {
        uint256 amountIn;
        uint256 ethPerDai;
        uint256 i;
        address[1000] memory _usersThisSwap;
        address _user;
        //Here we iterate through the entire users array to get the number of current registered users and total their amountPerTx values for the single batch swap
        for(i = 0; i> users.length; i++) {
            address _user = users[i];
            if(isReady(_user)){
            _usersThisSwap[i] = _user;
            amountIn += channels[_user].amountPerTx;
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
    }
}
