import { ethers } from "hardhat";
import { string } from "hardhat/internal/core/params/argumentTypes";
import { BasicToken__factory, TargetToken__factory} from "../typechain-types/factories/contracts/";
import {AMM__factory} from "../typechain-types/factories/contracts/AMM.sol/AMM__factory"


async function deploy() : Promise<[string,string,string]> {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying Data Pool contract with account:',deployer.address);

  const subscriptionId = "111199725596137296145697140297308239442849385428777531318641813055372418231896";
  const _win_optional_sell_probability = 1;
  const _reward_win_optional_sell = 10000;
  const _lose_optional_sell_swap_rate = 9500;
  const _market_sell_rate = 1000;

  const AMM = await ethers.getContractFactory("AMM",deployer);
  const amm = await AMM.deploy(
        subscriptionId,
        deployer.address,
        deployer.address,
        _win_optional_sell_probability,
        _reward_win_optional_sell,
        _lose_optional_sell_swap_rate,
        _market_sell_rate
  );    
  const addr = amm.getAddress();
  await amm.waitForDeployment();
  console.log('amm contract address:', addr )


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
  const res  = await Promise.all([addr,addr1,addr2])
  return res
};

async function interact() {
  const [signer] = await ethers.getSigners();
  const [ammAddr,basicTokenAddr,targetTokenAddr] = await deploy();

  const basicToken = BasicToken__factory.connect(basicTokenAddr,signer);
  const mintBTesp = await basicToken.mint(ammAddr, 80_000000000);
  await mintBTesp.wait();
  console.log(`mint basic token to amm contract in tx: ${mintBTesp.hash}`);

  const targetToken = TargetToken__factory.connect(targetTokenAddr,signer);
  const mintT2AMMResp = await targetToken.mint(ammAddr,1_000_000_000_000000000n)
  await mintT2AMMResp.wait();
  console.log(`mint target token to amm contract in tx: ${mintT2AMMResp.hash}`);


  const mintT2UResp = await targetToken.mint(signer.address,100_000_000000000n)
  await mintT2UResp.wait();
  console.log(`mint target token to user in tx: ${mintT2UResp.hash}`);


  const approveResp = await targetToken.approve(ammAddr, 1_000_000_000_000000000n)
  await approveResp.wait();
  console.log(`approve target token of user to amm contract in tx: ${approveResp.hash}`);


  const amm = AMM__factory.connect(ammAddr,signer);
  const initResp = await amm.Init(
    targetTokenAddr,
    basicTokenAddr
  );
  await initResp.wait();
  console.log(`init amm contract in tx: ${initResp.hash}`);
  
}

async function main() {
  // await deploy();
  await interact();
}
  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  