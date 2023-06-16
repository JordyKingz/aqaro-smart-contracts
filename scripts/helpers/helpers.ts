import {ethers} from "hardhat";

export async function transferTokensToPresaleContract(sender: any, tokenAddress: string, tokenAmount: number, smartContractAddress: string) {
  // transfer 10M tokens to presale contract
  const aqaroTokenFactory = await ethers.getContractFactory("AqaroToken");
  const aqaroToken = await aqaroTokenFactory.attach(tokenAddress);
  await aqaroToken.connect(sender).transfer(smartContractAddress, ethers.utils.parseUnits(`${tokenAmount}`, 18));

  console.log(`transferred ${tokenAmount} tokens to contract`);
};