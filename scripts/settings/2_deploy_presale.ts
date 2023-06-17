import { ethers } from "hardhat";
import {transferTokensToPresaleContract} from "../helpers/helpers";

let mortgageFactoryAddress = process.env.MORTGAGE_FACTORY || "";
let aqaroTokenAddress = process.env.AQARO_TOKEN || "";

if (mortgageFactoryAddress === "") {
  throw new Error("Environment variables MORTGAGE_FACTORY must be present");
}
if (aqaroTokenAddress === "") {
  throw new Error("Environment variables AQARO_TOKEN must be present");
}


async function main() {
  // get signers
  const [deployer] = await ethers.getSigners();

  //aqaro presale contract
  const aqaroPresaletFactory = await ethers.getContractFactory("AqaroPresale");
  const aqaroPresale = await aqaroPresaletFactory.deploy(deployer.address, aqaroTokenAddress);
  await aqaroPresale.deployed();
  console.log(`aqaroPresale: ${aqaroPresale.address}`);
  await transferTokensToPresaleContract(deployer, aqaroTokenAddress, 10_000_000, aqaroPresale.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
