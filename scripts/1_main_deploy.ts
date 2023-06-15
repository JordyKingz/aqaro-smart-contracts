import { ethers } from "hardhat";

async function main() {
  // get signers
  const [deployer] = await ethers.getSigners();

  const contractFactory = await ethers.getContractFactory("Aqaro");
  const contract = await contractFactory.deploy(deployer.address);

  await contract.deployed();

  console.log(`aqaro: ${contract.address}`);

  const mortgagePool = await ethers.getContractFactory("MortgagePool");
  const mortgage = await mortgagePool.deploy(deployer.address);
  await mortgage.deployed();
  console.log(`mortgage pool: ${mortgage.address}`);

  const mortgageFactory = await ethers.getContractFactory("MortgageFactory");
  const mortgageFactoryContract = await mortgageFactory.deploy(deployer.address);
  await mortgageFactoryContract.deployed();
  console.log(`mortgage factory: ${mortgageFactoryContract.address}`);

  // token has to be deployed on main net when aqaro is in alpha
  // presale will be sold on main net for 0.0003ETH per token, selling 10M tokens
  // to raise 3000ETH
  const aqaroTokenFactory = await ethers.getContractFactory("AqaroToken");
  const aqaroToken = await aqaroTokenFactory.deploy(deployer.address);
  await aqaroToken.deployed();
  console.log(`aqaroToken: ${aqaroToken.address}`);

  // aqaro early sale contract
  const aqaroEarlySaleFactory = await ethers.getContractFactory("AqaroEarlySale");
  const aqaroEarlySale = await aqaroEarlySaleFactory.deploy(deployer.address, aqaroToken.address);
  await aqaroEarlySale.deployed();
  console.log(`aqaroEarlySale: ${aqaroEarlySale.address}`);

  await transferTokensToPresaleContract(aqaroToken.address, 3_000_000, aqaroEarlySale.address);


  // aqaro presale contract
  // const aqaroPresaletFactory = await ethers.getContractFactory("AqaroPresale");
  // const aqaroPresale = await aqaroPresaletFactory.deploy(deployer.address, aqaroToken.address);
  // await aqaroPresale.deployed();
  // console.log(`aqaroPresale: ${aqaroPresale.address}`);

  // await transferTokensToPresaleContract(aqaroToken.address, 10_000_000, aqaroPresale.address);
}

async function transferTokensToPresaleContract(tokenAddress: string, tokenAmount: number, smartContractAddress: string) {
  // transfer 10M tokens to presale contract
  const aqaroTokenFactory = await ethers.getContractFactory("AqaroToken");
  const aqaroToken = await aqaroTokenFactory.attach(tokenAddress);
  await aqaroToken.transfer(smartContractAddress, ethers.utils.parseUnits(`${tokenAmount}`, 18));

  console.log(`transferred ${tokenAmount} tokens to contract`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
