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

  const vaultFactory = await ethers.getContractFactory("StakeVault");
  const stakeVault = await vaultFactory.deploy(
    aqaroTokenAddress,
    deployer.address,
  );

  await stakeVault.deployed();
  console.log(`'stakeVault address:': ${stakeVault.address}`);

  const distributorFactory = await ethers.getContractFactory("StakeVaultDistributor");
  const stakeVaultDistributor = await distributorFactory.deploy(
    aqaroTokenAddress,
    deployer.address,
    stakeVault.address
  );

  console.log(`'stakeVaultDistributor address:': ${stakeVaultDistributor.address}`);

  await stakeVault.setFeeDistributor(stakeVaultDistributor.address);

  await transferTokensToPresaleContract(deployer, aqaroTokenAddress, 2_000_000, stakeVaultDistributor.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
