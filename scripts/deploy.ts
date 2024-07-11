import { ethers } from "hardhat";
import { string } from "hardhat/internal/core/params/argumentTypes";
import { BasicToken__factory, TargetToken__factory} from "../typechain-types/factories/contracts/";
import {AMM__factory} from "../typechain-types/factories/contracts/AMM.sol/AMM__factory"
import {BigNumberish } from "ethers";


async function deploy() : Promise<[string,string,string]> {
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
  const _win_optional_sell_probability = 1;
  const _optional_sell_down_bound = 10000;
  const _optional_sell_up_bound = 9500;
  const _market_sell_rate = 1000;


  const AMM = await ethers.getContractFactory("AMM",deployer);
  const amm = await AMM.deploy(
        subscriptionId,
        deployer.address,
        _win_optional_sell_probability,
        _optional_sell_down_bound,
        _optional_sell_up_bound,
        _market_sell_rate,
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


  const mintT2UResp = await targetToken.mint(signer.address,targetTokenMint2User)
  await mintT2UResp.wait();
  console.log(`mint target token to user in tx: ${mintT2UResp.hash}`);


  const approveResp = await targetToken.approve(ammAddr, 1_000_000_000_000000000n)
  await approveResp.wait();
  console.log(`approve target token of user to amm contract in tx: ${approveResp.hash}`);

}

async function main() {
  const [ammAddr,basicTokenAddr,targetTokenAddr] = await deploy();
  await interact(ammAddr,basicTokenAddr,targetTokenAddr,80_000000000,1_000_000_000_000000000n,100_000_000000000n);
}
  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  