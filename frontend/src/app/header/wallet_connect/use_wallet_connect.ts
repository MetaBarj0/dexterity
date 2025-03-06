import { BrowserProvider, JsonRpcSigner } from "ethers";
import { ethers } from "ethers";
import { Dispatch, SetStateAction } from "react";

export type NetworkInfo = {
  name: string,
  chainId: bigint
};

export default function (states: States) {
  return {
    connectAndPlugWallet: async () => {
      await switchWalletNetworkToSepolia();
      plugBrowserWallet();
    },
    updateWalletStates: () => {
      (async () => {
        if (!states.provider)
          return;

        const network = await states.provider.getNetwork();
        const signers = await states.provider.listAccounts();

        // It may fail because of disconnected wallet
        if (signers.length === 0)
          return;

        const signer = signers[0];
        const address = await signer.getAddress();
        const balance = await states.provider.getBalance(signer);

        states.setConnectedAccount(formatAddress(address));
        states.setConnectedNetwork({ name: network.name, chainId: network.chainId });
        states.setAccountBalance(formatBalance(balance));
        states.setSigner(signer);
      })();
    },
    plugWallet: () => { plugBrowserWallet(); }
  };

  function plugBrowserWallet() {
    if (!window.ethereum) {
      // TODO: error handling
      // props.setErrorMessage("You need to install a MetaMask compatible wallet");

      return;
    }

    // Plug the wallet as it is, disconnected or connected
    states.setProvider(new ethers.BrowserProvider(window.ethereum));
  }

  async function switchWalletNetworkToSepolia() {
    if (!window.ethereum) {
      // TODO: error handling
      // props.setErrorMessage("You need to install a MetaMask compatible wallet");

      return;
    }

    if (states.connectedNetwork?.chainId === 11155111n)
      return;

    try {
      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{
          chainId: `0x${11155111n.toString(16)}`
        }]
      });
    }
    catch (error) {
      if (error instanceof Object && "message" in error && typeof error.message === "string") {
        // props.setErrorMessage(error.message);
      }
    }
  }
};

function formatAddress(address: string): string {
  return `${address.slice(0, 6)}...${address.slice(-4)}`
}

function formatBalance(amount: bigint): string {
  return `${ethers.formatEther(amount)} ETH`;
}

type States = {
  provider: BrowserProvider | undefined,
  setProvider: Dispatch<SetStateAction<BrowserProvider | undefined>>,
  setConnectedAccount: Dispatch<SetStateAction<string>>,
  connectedNetwork: NetworkInfo | undefined,
  setConnectedNetwork: Dispatch<SetStateAction<NetworkInfo>>,
  setAccountBalance: Dispatch<SetStateAction<string>>,
  setSigner: Dispatch<SetStateAction<JsonRpcSigner | undefined>>
};
