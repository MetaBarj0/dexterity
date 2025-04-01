import { ethers } from "ethers";
import express, { NextFunction, Request, Response } from "express";

import latestRunJson from "../../contracts/broadcast/DepositsAndSwaps.s.sol/1/run-latest.json";
import latestOutDexterityJson from "../../contracts/out/Dexterity.sol/Dexterity.json";

const [app, port] = [express(), 3000];
let dexterity: ethers.Contract;

app.get('/', (_req, res) => {
  res.send({
    name: "Dexterity backend",
    routes: [
      {
        path: '/',
        description: 'return backend title'
      },
      {
        path: '/tokens',
        description: 'return existing tokens in dexterity'
      },
      {
        path: '/swaps',
        description: 'return swap count that have bee executed in dexterity'
      }
    ]
  });
});

app.get('/tokens', async (_req, res) => {
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

  res.send(contractNames);
});

app.get('/swaps', async (_req, res) => {
  // collect all PoolCreated events to get all token addresses
  const swappedFilter = dexterity.filters.Swapped();
  const filterLog = await dexterity.queryFilter(swappedFilter);

  res.send(filterLog.length);
});

app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
  console.log(err);

  res.status(500);
  res.send(err);
});

app.listen(port, () => {
  // connect to the local blockchain
  const provider = ethers.getDefaultProvider("http://localhost:8545");

  // create the Dexterity contract
  const dexterityAddress =
    latestRunJson.transactions.filter((item) => item.contractName === "Dexterity").at(0)?.contractAddress;

  if (!dexterityAddress) {
    throw new Error("Cannot get the Dexterity smart contract address");
  }

  const dexterityAbi = latestOutDexterityJson.abi;
  dexterity = new ethers.Contract(dexterityAddress, dexterityAbi, provider);

  console.log(`Listening on ${port}`)
})
