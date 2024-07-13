import { ethers } from "hardhat";
import { AMM__factory } from "../typechain-types/factories/contracts/AMM.sol/AMM__factory";
import {BigNumberish } from "ethers";


// async function approve(basicTokenAmount, targetTokenAmount) {
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

async function Swap(targetToken:BigNumberish,basicToken:BigNumberish,SwapSType:BigNumberish)
{
  const [signer] = await ethers.getSigners();
  console.log('Swap with account:',signer.address);

  const amm_addr = "0x72600cB76bB67b6Ae4264C5d10ceE73966E82fB6"
  const amm = AMM__factory.connect(amm_addr,signer);
  const sellResp = await amm.Swap(
    targetToken,
    basicToken,
    SwapSType
  );
  await sellResp.wait();
  console.log(`Swap amm contract in tx: ${sellResp.hash}`);
}

async function Settle() {
  const [signer] = await ethers.getSigners();
  console.log('Settle with account:',signer.address);

  const amm_addr = "0x72600cB76bB67b6Ae4264C5d10ceE73966E82fB6"
  const amm = AMM__factory.connect(amm_addr,signer);
  const sellResp = await amm.Settle(
    110362072673275486240168669071546578611991718927397692217477536313108042034371n,
    90,
  );
  await sellResp.wait();
  console.log(`settle amm contract in tx: ${sellResp.hash}`);
}

async function getSwapAmount() {
  const [signer] = await ethers.getSigners();
  console.log('Swap with account:',signer.address);

  const amm_addr = "0x72600cB76bB67b6Ae4264C5d10ceE73966E82fB6"
  const amm = AMM__factory.connect(amm_addr,signer);

  const k = await amm.k()
  console.log("current k is:",k)

  const resp = await amm.SwapResultOfTargetAmount(
    0,
    1_000_000_000_000_000_000n,
    0
  )

  console.log(resp[0]/1_000_000_000_000n, resp[1]/1_000_000_000_000n,resp[2]/1_000_000_000_000n)
}


async function main() {
  // await getSwapAmount()
  await Swap(1_000_000_000_000_000_000n,0,0);
  // await Settle()
}

  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  