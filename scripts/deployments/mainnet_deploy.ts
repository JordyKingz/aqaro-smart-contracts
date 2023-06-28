import { ethers } from "hardhat";
import {transferTokensToPresaleContract} from "../helpers/helpers";

async function main() {
  // get signers
  const [deployer] = await ethers.getSigners();

  // token has to be deployed on main net when aqaro is in alpha
  const aqaroTokenFactory = await ethers.getContractFactory("AqaroToken");
  const aqaroToken = await aqaroTokenFactory.deploy(deployer.address);
  await aqaroToken.deployed();
  console.log(`aqaroToken: ${aqaroToken.address}`);

  // aqaro early sale contract
  const aqaroEarlySaleFactory = await ethers.getContractFactory("AqaroEarlySale");
  const aqaroEarlySale = await aqaroEarlySaleFactory.deploy(deployer.address, aqaroToken.address);
  await aqaroEarlySale.deployed();
  console.log(`aqaroEarlySale: ${aqaroEarlySale.address}`);

  await transferTokensToPresaleContract(deployer, aqaroToken.address, 3_000_000, aqaroEarlySale.address);

  const vaultFactory = await ethers.getContractFactory("StakeVault");
  const stakeVault = await vaultFactory.deploy(
    aqaroToken.address,
    deployer.address,
  );

  await stakeVault.deployed();
  console.log(`stakeVault address: ${stakeVault.address}`);

  const distributorFactory = await ethers.getContractFactory("StakeVaultDistributor");
  const stakeVaultDistributor = await distributorFactory.deploy(
    aqaroToken.address,
    deployer.address,
    stakeVault.address
  );

  console.log(`stakeVaultDistributor address: ${stakeVaultDistributor.address}`);

  await stakeVault.setRewardDistributor(stakeVaultDistributor.address);

  await transferTokensToPresaleContract(deployer, aqaroToken.address, 2_000_000, stakeVaultDistributor.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
