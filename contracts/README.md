# Dexterity smart contracts

Built with [foundry](https://github.com/foundry-rs/foundry).

## setup

`make .env` to create all necessary environment variables.
Edit this file to set all values.

## testing

### contracts

`make test` everything should be green.

## backend

### blockchain setup

First, run a local blockchain with `make run_local_blockchain`.
Then, run the the `DepositsAndSwaps.s.sol` script with
`make run script=DepositsAndSwaps`

### backend setup

First go to to the `../backend/` directory
Then, run `npm run start` to start the server

### client side

Open your browser and navigate to (<http://localhost:3000>)
You can query:

- `/tokens` to get a list of all supported tokens in this Dexterity instance in
  the local blockchin you spun earlier.
- `/swaps` to get the number of swap that have been done.
- `/traders` to get an array of all traders that have done swaps.
- `/providers` to get an array of all liquidity providers.
