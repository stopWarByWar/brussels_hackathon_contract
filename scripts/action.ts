import { ethers } from "hardhat";
import { AMM__factory } from "../typechain-types/factories/contracts/AMM.sol/AMM__factory";

// async function init() {
//   const [signer] = await ethers.getSigners();
//   console.log('Init with account:',signer.address);

//   const amm_addr = "0x65c0C15c466BBbc0d8193CAb206f7699dA4a451E"
//   const targetTokenAddr = "0x59F6e5a97266D1d8Cd042E625d094D1a6f5392e4"
//   const basicTokenAddr  = "0xb253D739dAE22B3418304E9f91dc05999093cD2F"


//   const amm = AMM__factory.connect(amm_addr,signer)
//   const initResp = await amm.Init(
//     targetTokenAddr,
//     basicTokenAddr
//   );
//   await initResp.wait();
//   console.log(`init amm contract in tx: ${initResp.hash}`);
// }

async function Sell() {
  const [signer] = await ethers.getSigners();
  console.log('Sell with account:',signer.address);

  const amm_addr = "0x65c0C15c466BBbc0d8193CAb206f7699dA4a451E"
  const amm = AMM__factory.connect(amm_addr,signer);
  const sellResp = await amm.Swap(
    1_000_000_000_000000000n,
    0,
    0
  );
  await sellResp.wait();
  console.log(`sell amm contract in tx: ${sellResp.hash}`);
}

async function Settle() {
  const [signer] = await ethers.getSigners();
  console.log('Settle with account:',signer.address);

  const amm_addr = "0x65c0C15c466BBbc0d8193CAb206f7699dA4a451E"
  const amm = AMM__factory.connect(amm_addr,signer);
  const sellResp = await amm.Settle(
    110362072673275486240168669071546578611991718927397692217477536313108042034371n,
    90,
  );
  await sellResp.wait();
  console.log(`settle amm contract in tx: ${sellResp.hash}`);
}


async function main() {
  // await init()
  // await Sell()
  await Settle()
}



  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  