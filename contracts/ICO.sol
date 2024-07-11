// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
// import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";

// interface IERC20 {
//     function balanceOf(address account) external view returns (uint256);
//     function transfer(address recipient, uint256 amount) external returns (bool);
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
//     function mint(address to, uint256 amount) public;
//     function decimals() public view returns (uint8) ;
// }

// contract AMM is VRFConsumerBaseV2Plus,AccessControl {
//     address public amm;

//     address public basicToken;
//     address public targetToken;
    
//     uint256 public mintAMMTargetTokenAmount;

//     uint256 public basicTokenRaised;
//     uint256 public basicTokenRaisedTarget;
//     uint256 public targetTokenMint;
//     uint256 public price;



//     event Buy(address user, uint256 basicToken, uint256 targetToken);
//     event ICOFinished(uint256 basicToken, uint256 targetToken);
  
//     constructor() {
//     }

//     function Init(address _amm, address _basicToken, address _targetToken, uint256 _basicTokenRaisedTarget,uint256 mintAMMTargetTokenAmount) public onlyRole(DEFAULT_ADMIN_ROLE) {
//         amm = _amm;
//         basicToken = _basicToken;
//         targetToken = _targetToken;
//         basicTokenRaisedTarget = _basicTokenRaisedTarget;
//         price = _price;
//     }

//     function Buy(uint256 targetAmount) public{
//         uint256 basicAmount = price * targetAmount;
//         require(basicAmount+basicTokenRaised <= basicTokenRaisedTarget, "The basic token received has Exceed ico up bound");
//         IERC20(basicToken).transferFrom(msg.sender, address(this),basicAmount);
//         uint8 tagetTokenDecimals =  IERC20(targetToken).decimals();
//         IERC20(targetToken).mint(msg.sender, targetAmount * uint256(tagetTokenDecimals));
//         basicTokenRaised += basicAmount;
//         targetTokenMint += targetAmount * uint256(tagetTokenDecimals);
//         emit Buy(msg.sender,basicAmount,targetAmount,basicTokenRaised);
//         if (basicTokenRaised == basicTokenRaisedTarget) {
//             emit ICOFinished(basicTokenRaised,targetTokenMint);
//             IERC20(targetToken).mint(amm, mintAMMTargetTokenAmount);

//         }
//     } 

// }