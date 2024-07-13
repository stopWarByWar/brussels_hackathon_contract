import { ethers } from "hardhat";
import { string } from "hardhat/internal/core/params/argumentTypes";
import { BasicToken__factory, TargetToken__factory} from "../typechain-types/factories/contracts/";
import {AMM__factory} from "../typechain-types/factories/contracts/AMM.sol/AMM__factory"
import {BigNumberish } from "ethers";




async function deploy(_win_optional_sell_probability: BigNumberish,_optional_down_bound:BigNumberish,_optional_up_bound:BigNumberish,_market_swap_rate: BigNumberish) : Promise<[string,string,string]> {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying contract with account:',deployer.address);


  const BasicToken = await ethers.getContractFactory("BasicToken",deployer);
  const basicToken = await BasicToken.deploy(
    deployer.address,
    deployer.address
  );


  const addr1 = basicToken.getAddress();
  await basicToken.waitForDeployment();
  console.log('basic token contract address:', addr1 )

  const TargetToken = await ethers.getContractFactory("TargetToken",deployer);
  const targetToken = await TargetToken.deploy(
    deployer.address,
    deployer.address
  );
  const addr2 = targetToken.getAddress();
  await targetToken.waitForDeployment();
  console.log('target token contract address:', addr2)



  const subscriptionId = "111199725596137296145697140297308239442849385428777531318641813055372418231896";


  const AMM = await ethers.getContractFactory("AMM",deployer);
  const amm = await AMM.deploy(
        subscriptionId,
        deployer.address,
        _win_optional_sell_probability,
        _optional_down_bound,
        _optional_up_bound,
        _market_swap_rate,
        addr2,
        addr1
  );    
  const addr = amm.getAddress();
  await amm.waitForDeployment();
  console.log('amm contract address:', addr )
  

  const res  = await Promise.all([addr,addr1,addr2])
  return res
 
};

async function interact(ammAddr:string,basicTokenAddr:string,targetTokenAddr:string, ammBasicTokenInitAmount: BigNumberish, targetTokenInitAmount:BigNumberish, targetTokenMint2User:BigNumberish) {
  const [signer] = await ethers.getSigners();

  const basicToken = BasicToken__factory.connect(basicTokenAddr,signer);
  const mintBTesp = await basicToken.mint(ammAddr, ammBasicTokenInitAmount);
  await mintBTesp.wait();
  console.log(`mint basic token to amm contract in tx: ${mintBTesp.hash}`);

  const targetToken = TargetToken__factory.connect(targetTokenAddr,signer);
  const mintT2AMMResp = await targetToken.mint(ammAddr, targetTokenInitAmount)
  await mintT2AMMResp.wait();
  console.log(`mint target token to amm contract in tx: ${mintT2AMMResp.hash}`);


  // const mintT2UResp = await targetToken.mint(signer.address,targetTokenMint2User)
  // await mintT2UResp.wait();
  // console.log(`mint target token to user in tx: ${mintT2UResp.hash}`);


  const approveBResp = await basicToken.approve(ammAddr, targetTokenMint2User)
  await approveBResp.wait();
  console.log(`approve target token of user to amm contract in tx: ${approveBResp.hash}`);

  const approveTResp = await targetToken.approve(ammAddr, targetTokenMint2User)
  await approveTResp.wait();
  console.log(`approve target token of user to amm contract in tx: ${approveTResp.hash}`);

  const amm = AMM__factory.connect(ammAddr,signer);
  const initResp = await amm.BalanceK();
  console.log(`init amm in tx: ${initResp.hash}`);

}

async function main() {
  const _win_optional_sell_probability = 5000;
  const _optional_down_bound = 8500;
  const optional_up_bound = 10500;
  const _market_swap_rate = 1000;


  const [ammAddr,basicTokenAddr,targetTokenAddr] = await deploy(_win_optional_sell_probability,_optional_down_bound,optional_up_bound,_market_swap_rate);
  const ammBasicTokenInitAmount = 100000_000000000000000000n;
  const targetTokenInitAmount = 100000_000000000000000000n;
  const targetTokenMint2User= 100000_000000000000000000n
  await interact(ammAddr,basicTokenAddr,targetTokenAddr,ammBasicTokenInitAmount,targetTokenInitAmount,targetTokenMint2User);
}
  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  