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
    bytes32 public constant INIT_ROLE = keccak256("INIT_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");


    struct sellOrder {
        address user;
        uint256 targetTokenAmount;
        uint8 sellType;
    }

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

    // map requestID to sell order
    mapping(uint256 => sellOrder) private pendingOrder;
    mapping(uint256 => uint256) public randoms;

    address public basicToken;
    address public targetToken;

    uint112 public basicTokenReserve;
    uint112 public targetTokenReserve;
    uint256 private k;

    uint256 public win_optional_sell_probability;
    uint256 public reward_win_optional_sell;
    uint256 public lose_optional_sell_swap_rate;
    
    //5%
    uint256 public market_sell_rate;


    event GetRandoms(uint256 indexed requestId, uint256 indexed randomnessm, address user, uint256 sellAmount, uint8 sellType);
    event SellSuceesfully(address indexed user, uint256 sellTargetTokenAmount, uint8 sellType, uint256 preGetTargetTokenAmount,uint256 finalTargetTokenAmount);
  
    constructor(uint256 subscriptionId,address icoContract, address _operator, uint256 _win_optional_sell_probability, uint256 _reward_win_optional_sell ,uint256 _lose_optional_sell_swap_rate,uint256 _market_sell_rate) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_subscriptionId = subscriptionId;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(INIT_ROLE,msg.sender);
        _grantRole(INIT_ROLE, icoContract);
        _grantRole(OPERATOR_ROLE, _operator);
        win_optional_sell_probability = _win_optional_sell_probability;
        reward_win_optional_sell = _reward_win_optional_sell;
        lose_optional_sell_swap_rate = _lose_optional_sell_swap_rate;
        market_sell_rate = _market_sell_rate;
    }

    function Init(address _targetToken, address _basicToken) public onlyRole(INIT_ROLE)  {
        basicToken = _basicToken;
        targetToken = _targetToken;
        balanceK();   
    }

    function balanceK() internal {
        basicTokenReserve = uint112(IERC20(basicToken).balanceOf(address(this)));
        targetTokenReserve = uint112(IERC20(targetToken).balanceOf(address(this)));
        k = uint256(basicTokenReserve) * uint256(targetTokenReserve);
    }

    function UpdateConf(uint256 _win_optional_sell_probability, uint256 _reward_win_optional_sell ,uint256 _lose_optional_sell_swap_rate,uint256 _market_sell_rate) public onlyRole(DEFAULT_ADMIN_ROLE) {
        win_optional_sell_probability = _win_optional_sell_probability;
        reward_win_optional_sell = _reward_win_optional_sell;
        lose_optional_sell_swap_rate = _lose_optional_sell_swap_rate;
        market_sell_rate = _market_sell_rate;
    }

    function SellResultOfTargetAmount(
        uint256 _targetTokenAmount,
        uint8 _sellType
    ) 
        public 
        view 
        returns (uint256, uint256, uint256)
    {
        uint pre_out_basic_token = k / _targetTokenAmount;
        if (_sellType == 0) {
            return  (pre_out_basic_token * (10000 - market_sell_rate) /10000 , pre_out_basic_token , pre_out_basic_token * (10000 +  market_sell_rate) /10000);
        } else {
            return  (pre_out_basic_token * lose_optional_sell_swap_rate  / 10000, pre_out_basic_token, pre_out_basic_token * (10000+ reward_win_optional_sell) / 10000);
        }
    }


    function Settle(
        uint256 requestId, 
        uint256 persentage,
        bool win
    ) 
        public onlyRole(OPERATOR_ROLE) 
    {   
        sellOrder memory order = pendingOrder[requestId];
        require(order.targetTokenAmount != 0,"Invalid request id");
        uint pre_out_basic_token = k / order.targetTokenAmount;
		uint real_out_basic_token;
		if (order.sellType == 0) {
            if (win) {
                real_out_basic_token = pre_out_basic_token * (10000+ reward_win_optional_sell) / 10000;
            } else {
                real_out_basic_token = pre_out_basic_token * lose_optional_sell_swap_rate  / 10000;
            }
        } else {
            real_out_basic_token = pre_out_basic_token * persentage  / 10000;
        }
        IERC20(basicToken).transfer(order.user,real_out_basic_token);
        emit SellSuceesfully(order.user, order.targetTokenAmount,  order.sellType, pre_out_basic_token,real_out_basic_token);
        balanceK();
    }
    
    function Sell(
        uint256 _targetTokenAmount,
        uint8 _sellType 
    ) public onlyOwner returns (uint256 requestId) {
        IERC20(targetToken).transferFrom(msg.sender, address(this), _targetTokenAmount);
        require(_sellType == 0 || _sellType == 1, "Invalid Sell Type");
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
        pendingOrder[requestId] = sellOrder({
            user: msg.sender,
            targetTokenAmount: _targetTokenAmount,
            sellType: _sellType
        });
    }


    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
       randoms[requestId] = randomWords[0];
       sellOrder memory order = pendingOrder[requestId];
       emit  GetRandoms(requestId, randomWords[0], order.user,  order.targetTokenAmount, order.sellType);
    }    
}