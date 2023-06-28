import {ethers} from "hardhat";


let aqaroAddress: string; // propertyFactory
let mortgagePoolAddress: string;
let mortgageFactoryAddress: string;
let aqaroTokenAddress: string;
let aqaroEarlySaleAddress: string;
let aqaroPresaleAddress: string;

aqaroAddress = process.env.AQARO || "";
mortgagePoolAddress = process.env.MORTGAGE_POOL || "";
mortgageFactoryAddress = process.env.MORTGAGE_FACTORY || "";
aqaroTokenAddress = process.env.AQARO_TOKEN || "";
aqaroEarlySaleAddress = process.env.AQARO_EARLY_SALE || "";
aqaroPresaleAddress = process.env.AQARO_PRESALE || "";

if (aqaroAddress === "") {
  throw new Error("Environment variables AQARO must be present");
}
else if (mortgagePoolAddress === "") {
  throw new Error("Environment variables MORTGAGE_POOL must be present");
}
else if (mortgageFactoryAddress === "") {
  throw new Error("Environment variables MORTGAGE_FACTORY must be present");
}
else if (aqaroTokenAddress === "") {
  throw new Error("Environment variables AQARO_TOKEN must be present");
}
else if (aqaroPresaleAddress === "") {
  throw new Error("Environment variables AQARO_PRESALE must be present");
}

let aqaro: any;
let mortgagePool: any;
let aqaroToken: any;
let aqaroPresale: any;
let mortgageFactoryInstance: any;
let aqaroEarlySale: any;

async function main() {
  // get signers
  const [
    deployer,
    alice,
    bob,
    charlie,
    dave,
    eve] = await ethers.getSigners();

  // list property
  const aqaroFactory = await ethers.getContractFactory("Aqaro");
  aqaro = await aqaroFactory.attach(`${aqaroAddress}`);

  const createProp = {
    service_id: "1234-123-1234-1234",
    addr: {
      street: "Poelestraat 4",
      city: "Groningen",
      state: "Groningen",
      country: "nl",
      zip: "9710"
    },
    seller: {
      wallet: deployer.address,
      name: "John Doe",
      email: "info@aqaro.app",
      status: 0
    },
    askingPrice: 137,
    price: 256000*1e6, // $256.000
    description: "Welcome to your new home!\n" +
      "                                This stunning 3-bedroom apartment offers over 100m² of luxurious living space in the heart of downtown.\n" +
      "                                The bright and airy open plan living area is perfect for relaxing or entertaining guests, while the fully equipped kitchen features high-quality finishes and fittings.\n" +
      "                                Step outside onto your private balcony and enjoy the peaceful view of the beautifully landscaped garden.\n" +
      "                                With three spacious bedrooms, this apartment is perfect for families or professionals seeking a comfortable and convenient living experience.\n" +
      "                                Don't miss your chance to own this exceptional property - schedule a viewing today and make it yours!"
  }

  let createdAddress = "";
  // check emit PropertyCreated event
  aqaro.on("PropertyCreated", (propertyAddress: any, owner: any, propertyId: any, askingPrice: any) => {
    console.log(`PropertyCreated: ${propertyAddress}`);
    createdAddress = propertyAddress;
    console.log(`owner: ${owner}`);
    console.log(`propertyCount: ${propertyId.toString()}`);
    console.log(`askingPrice: ${askingPrice.toString()}`);

    // createMortgageRequest(propertyAddress, dave);
  });
  // await aqaro.connect(charlie).createProperty(createProp);
}

async function createMortgageRequest(propAddress: string, user: any) {
  const mortgageRequest = {
    name: "John Doe",
    incomeYearly: 300001e6,
    incomeMonthly: 25001e6,
    KYCVerified: false
  }

  const ETH_PRICE = 1900;

  const mortgagePayment = {
    amountETH: 100,
    amountUSD: 100 * ETH_PRICE,
    totalPayments: 266,
    endDate: new Date(2443548980).getTime(),
    interestRate: 25000 // 2.5%
  }

  const mortgageFactory = await ethers.getContractFactory("MortgageFactory");
  mortgageFactoryInstance = await mortgageFactory.attach(`${mortgageFactoryAddress}`);

  // check emit MortgageRequested event
  mortgageFactoryInstance.on("MortgageRequested", (mortgageContract: string, propertyContract: string, owner: string) => {
    console.log(`mortgageAddress: ${mortgageContract}`);
    console.log(`propertyAddress: ${propertyContract}`);
    console.log(`sender: ${owner}`);
  });

  await mortgageFactoryInstance.connect(user).requestMortgage(propAddress, mortgageRequest, mortgagePayment);
}

async function addMortgageLiquidity(user: any, amount: number) {
  await mortgagePool
    .connect(user)
    .provideMortgageLiquidity({value: ethers.utils.parseEther(`${amount}`)});

  console.log(`added ${amount} ETH to mortgage pool by ${user.address}`);
}

async function buyEarlySaleTokens(user: any, amount: number) {
  const tokenPrice = 0.000125;
  const ethPrice = Number(amount * tokenPrice).toFixed(4);

  await aqaroEarlySale
    .connect(user)
    .investInAqaro(
      ethers.utils.parseUnits(`${amount}`, 18),
      {value: ethers.utils.parseEther(`${ethPrice}`)}
    );

  console.log(`bought ${amount} AQARO tokens by ${user.address}`);
}

async function buyPresaleTokens(user: any, amount: number) {
  const tokenPrice = 0.0003;
  const ethPrice = Number(amount * tokenPrice).toFixed(4);

  await aqaroPresale
    .connect(user)
    .buyAqaroToken(
      amount,
      {value: ethers.utils.parseEther(`${ethPrice}`)}
    );

  console.log(`bought ${amount} AQARO tokens by ${user.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
