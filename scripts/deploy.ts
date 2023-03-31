import { ethers } from "hardhat";

async function main() {
  // get signers
  const [deployer] = await ethers.getSigners();

  const contractFactory = await ethers.getContractFactory("Aqaro");
  const contract = await contractFactory.deploy(deployer.address);

  await contract.deployed();

  console.log(`aqaro: ${contract.address}`);

  const mortgageFactory = await ethers.getContractFactory("MortgagePool");
  const mortgage = await mortgageFactory.deploy(deployer.address);
  await mortgage.deployed();
  console.log(`mortgage: ${mortgage.address}`);


  // token has to be deployed on main net when aqaro is in alpha
  // presale will be sold on main net for 0.0003ETH per token, selling 10M tokens
  // to raise 3000ETH
  const aqaroTokenFactory = await ethers.getContractFactory("AqaroToken");
  const aqaroToken = await aqaroTokenFactory.deploy(deployer.address);
  await aqaroToken.deployed();
  console.log(`aqaroToken: ${aqaroToken.address}`);

  const aqaroPresaletFactory = await ethers.getContractFactory("AqaroPresale");
  const aqaroPresale = await aqaroPresaletFactory.deploy(deployer.address, aqaroToken.address);
  await aqaroPresale.deployed();
  console.log(`aqaroPresale: ${aqaroPresale.address}`);

  await transferTokensToPresaleContract(aqaroToken.address, aqaroPresale.address);
}

async function transferTokensToPresaleContract(tokenAddress: string, presaleAddress: string) {
  // transfer 10M tokens to presale contract
  const aqaroTokenFactory = await ethers.getContractFactory("AqaroToken");
  const aqaroToken = await aqaroTokenFactory.attach(tokenAddress);
  await aqaroToken.transfer(presaleAddress, ethers.utils.parseUnits("10000000", 18));

  console.log("transferred 10M tokens to presale contract");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
