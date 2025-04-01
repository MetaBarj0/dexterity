import { glob, readFile } from "node:fs/promises";
import express from "express";
import { ethers } from "ethers";

import latestRunJson from "../../contracts/broadcast/DepositsAndSwaps.s.sol/1/run-latest.json";
import latestOutDexterityJson from "../../contracts/out/Dexterity.sol/Dexterity.json";

const [app, port] = [express(), 3000];

app.get('/', (_req, res) => {
  res.send({
    name: "Dexterity backend",
    routes: [
      {
        path: '/',
        description: 'display backend title'
      },
      {
        path: '/tokens',
        description: 'display existing tokens in dexterity'
      }
    ]
  });
});

app.get('/tokens', async (_req, res) => {
  // connect to the local blockchain
  const provider = ethers.getDefaultProvider("http://localhost:8545");

  // create the Dexterity contract
  const dexterityAddress =
    latestRunJson.transactions.filter((item) => item.contractName === "Dexterity").at(0)?.contractAddress;

  if (!dexterityAddress) {
    res.status(500);
    res.send("Cannot get the Dexterity smart contract address");

    return;
  }

  const dexterityAbi = latestOutDexterityJson.abi;
  const dexterity = new ethers.Contract(dexterityAddress, dexterityAbi, provider);

  // collect all PoolCreated events to get all token addresses
  const poolCreatedFilter = dexterity.filters.PoolCreated(undefined, undefined, undefined);
  const filterLog = await dexterity.queryFilter(poolCreatedFilter);
  const poolCreatedEvents = filterLog as ethers.EventLog[];
  const tokenAddressSet = new Set<string>(poolCreatedEvents.reduce((acc: string[], e) => {
    return [...acc, e.args[0], e.args[1]];
  }, []));
  const tokensAddresses = Array.from(tokenAddressSet).map(address => address.toLowerCase());

  const contractNames = tokensAddresses.map(address => {
    return latestRunJson.transactions.filter(tx => {
      return tx.transactionType === "CREATE" && tx.contractAddress === address;
    }).at(0)?.contractName;
  });

  console.log(contractNames);

  res.send(contractNames);
});

app.listen(port, () => {
  console.log(`Listening on ${port}`)
})
