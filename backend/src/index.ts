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
      },
      {
        path: '/traders',
        description: 'return users of the protocol'
      },
      {
        path: '/holders',
        description: 'return depositors of the protocol'
      }
    ]
  });
});

app.get('/tokens', async (_req, res) => {
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

app.get('/traders', async (_req, res) => {
  const swappedFilter = dexterity.filters.Swapped();
  const filterLog = await dexterity.queryFilter(swappedFilter);
  const swappedEvents = filterLog as ethers.EventLog[];

  const traderAddressSet = new Set<string>(swappedEvents.reduce((acc: string[], e) => {
    return [...acc, e.args[0]];
  }, []));
  const traderAddresses = Array.from(traderAddressSet).map(address => address.toLowerCase());

  res.send(traderAddresses);
});

app.get('/holders', async (_req, res) => {
  const depositedFilter = dexterity.filters.Deposited();
  const filterLog = await dexterity.queryFilter(depositedFilter);
  const depositedEvents = filterLog as ethers.EventLog[];

  const holderAddressSet = new Set<string>(depositedEvents.reduce((acc: string[], e) => {
    return [...acc, e.args[0]];
  }, []));
  const traderAddresses = Array.from(holderAddressSet).map(address => address.toLowerCase());

  res.send(traderAddresses);
});

app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
  console.log(err);

  res.status(500);
  res.send(err);
});

app.listen(port, () => {
  const provider = ethers.getDefaultProvider("http://localhost:8545");

  const dexterityAddress =
    latestRunJson.transactions.filter((item) => item.contractName === "Dexterity").at(0)?.contractAddress;

  const dexterityAbi = latestOutDexterityJson.abi;
  dexterity = new ethers.Contract(dexterityAddress!, dexterityAbi, provider);

  console.log(`Listening on ${port}`)
})
