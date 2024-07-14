// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract AMM is VRFConsumerBaseV2Plus,AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 private  constant ROLL_IN_PROGRESS = 42;

    // Your subscription ID.
    uint256 public s_subscriptionId;

    // Sepolia coordinator. For other networks,
    // see https://docs.chain.link/vrf/v2-5/supported-networks#configurations
    address public vrfCoordinator = 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/vrf/v2-5/supported-networks#configurations
    bytes32 public s_keyHash =
        0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 40,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 public callbackGasLimit = 40000;

    // The default is 3, but you can set this higher.
    uint16 public requestConfirmations = 3;

    // For this example, retrieve 1 random value in one request.
    // Cannot exceed VRFCoordinatorV2_5.MAX_NUM_WORDS.
    uint32 public numWords = 1;


    struct Order {
        address user;
        uint256 targetTokenAmount;
        uint256 basicTokenAmount;
        uint8 swapType;
    }

    // map requestID to sell order
    mapping(uint256 => Order) private pendingOrder;
    mapping(uint256 => uint256) public randoms;
    mapping(uint256 => uint256) public settleResult;

    address public basicToken;
    address public targetToken;

    uint112 public basicTokenReserve;
    uint112 public targetTokenReserve;
    uint256 public k;

    uint256 public win_optional_probability;
    uint256 public optional_down_bound;
    uint256 public optional_up_bound;
    
    //5%
    uint256 public market_swap_rate;


    event GetRandoms(uint256 indexed requestId, uint256 indexed randomness, address user,uint8 sellType,uint256 basicToken, uint256 targetToken);
    event SwapSuceesfully(uint256 indexed requestId, address indexed user, uint256 InTokenAmount, uint8 swapType, uint256 preOutTokenAmount,uint256 finalOutTokenAmount);
  
    constructor(uint256 subscriptionId, address _operator, uint256 _win_optional_probability, uint256 _optional_down_bound ,uint256 _optional_up_bound,uint256 _market_swap_rate,address _targetToken, address _basicToken) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_subscriptionId = subscriptionId;
        _grantRole(OPERATOR_ROLE, _operator);
        win_optional_probability = _win_optional_probability;
        optional_down_bound = _optional_down_bound;
        optional_up_bound = _optional_up_bound;
        market_swap_rate = _market_swap_rate;

        basicToken = _basicToken;
        targetToken = _targetToken;
        balanceK();   
    }

    function BalanceK() public {
        balanceK();
    }


    function balanceK() internal {
        basicTokenReserve = uint112(IERC20(basicToken).balanceOf(address(this)));
        targetTokenReserve = uint112(IERC20(targetToken).balanceOf(address(this)));
        k = uint256(basicTokenReserve) * uint256(targetTokenReserve);
    }

    function UpdateConf(uint256 _win_optional_probability, uint256 _optional_down_bound ,uint256 _optional_up_bound,uint256 _market_swap_rate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        win_optional_probability = _win_optional_probability;
        optional_down_bound = _optional_down_bound;
        optional_up_bound = _optional_up_bound;
        market_swap_rate = _market_swap_rate;
    }

    function SwapResultOfTargetAmount(uint256 _targetTokenAmount,uint256 _basicTokenAmount,uint8 _sellType) public view returns (uint256, uint256, uint256){
        require(_targetTokenAmount == 0 || _basicTokenAmount == 0, "One of input should be 0");
        uint256 preOutToken;
        if (_targetTokenAmount != 0) {
            preOutToken = basicTokenReserve - k / (_targetTokenAmount + targetTokenReserve);
        } else if (_basicTokenAmount != 0){
            preOutToken =  targetTokenReserve - k / (basicTokenReserve + _basicTokenAmount);
        }
        if (_sellType == 1) {
            return  (preOutToken * (10000 - market_swap_rate) /10000 , preOutToken , preOutToken * (10000 +  market_swap_rate) /10000);
        } else {
            return  (preOutToken * optional_down_bound  / 10000, preOutToken, preOutToken *  optional_up_bound/ 10000);
        }
    }


    function Settle(uint256 requestId, uint256 persentage) public onlyRole(OPERATOR_ROLE) {   
        Order memory order = pendingOrder[requestId];
        require(order.targetTokenAmount != 0,"Invalid request id");
        require( settleResult[requestId] == 0, "The order has been settled");

        uint256 preOutToken;
        uint256 inToken;
        if (order.targetTokenAmount != 0) { 
            preOutToken = basicTokenReserve - k / (order.targetTokenAmount + targetTokenReserve);
            inToken = order.targetTokenAmount;
            IERC20(basicToken).transfer(order.user,preOutToken * persentage / 10000);
        } else if (order.basicTokenAmount != 0){
            preOutToken =  targetTokenReserve - k / (basicTokenReserve + order.basicTokenAmount);
            inToken = order.basicTokenAmount;
            IERC20(targetToken).transfer(order.user,preOutToken * persentage / 10000);
        }
        emit SwapSuceesfully(requestId,order.user, inToken,  order.swapType, preOutToken,preOutToken * persentage / 10000);
        balanceK();
        settleResult[requestId] = persentage;
    }
    
    function Swap(
        uint256 _targetTokenAmount,
        uint256 _basicTokenAmount,
        uint8 _swapType
    ) public returns (uint256 requestId) {
        require(_targetTokenAmount == 0 || _basicTokenAmount == 0, "Can not swap 2 token at the same time");
        require(_swapType == 0 || _swapType == 1, "Invalid Sell Type");

        if (_targetTokenAmount != 0) {
            IERC20(targetToken).transferFrom(msg.sender, address(this), _targetTokenAmount);
        } else if (_basicTokenAmount != 0){
            IERC20(basicToken).transferFrom(msg.sender, address(this), _basicTokenAmount);
        }
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        require(pendingOrder[requestId].user == address(0), "Already Query Random");
        pendingOrder[requestId] = Order({
            user: msg.sender,
            targetTokenAmount: _targetTokenAmount,
            basicTokenAmount: _basicTokenAmount,
            swapType: _swapType
        });
    }


    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
       randoms[requestId] = randomWords[0];
       Order memory order = pendingOrder[requestId];
       emit  GetRandoms(requestId, randomWords[0], order.user,order.swapType,order.basicTokenAmount,order.targetTokenAmount);
    }    

    function getConfInfo() view public returns (uint256, uint256, uint256, uint256) {
        return(win_optional_probability,optional_down_bound,optional_up_bound,market_swap_rate);
    }
}