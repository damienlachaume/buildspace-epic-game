const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory("MyEpicGame");
  const gameContract = await gameContractFactory.deploy(
    ["Elf", "Human", "Dwarf"], // Names
    [
      "ipfs://bafybeibnwbnaunuf3zbnnfye4f6rcre26gietfi3rdyhquirthd37yhera/elf.png",
      "ipfs://bafybeibnwbnaunuf3zbnnfye4f6rcre26gietfi3rdyhquirthd37yhera/human.png",
      "ipfs://bafybeibnwbnaunuf3zbnnfye4f6rcre26gietfi3rdyhquirthd37yhera/dwarf.png",
    ],
    [200, 300, 150], // HP values
    [75, 100, 50], // Attack damage values
    "Troll",
    "ipfs://bafybeibnwbnaunuf3zbnnfye4f6rcre26gietfi3rdyhquirthd37yhera/troll.png",
    10000, // Troll hp
    50 // Troll attack damage
  );

  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);

  let txn;

  txn = await gameContract.mintCharacterNFT(2);
  await txn.wait();

  txn = await gameContract.attackTroll();
  await txn.wait();

  txn = await gameContract.attackTroll();
  await txn.wait();

  txn = await gameContract.attackTroll();
  await txn.wait();

  txn = await gameContract.attackTroll();
  await txn.wait();

  console.log("Done!");
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();
