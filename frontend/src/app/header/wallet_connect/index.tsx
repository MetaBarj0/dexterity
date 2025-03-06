"use client";

import { BrowserProvider, JsonRpcSigner } from "ethers";
import { useEffect, useState } from "react";
import useWalletConnect, { NetworkInfo } from "./use_wallet_connect";

export default () => {
  const [provider, setProvider] = useState<BrowserProvider>();
  const [connectedNetwork, setConnectedNetwork] = useState<NetworkInfo>({ name: "Disconnected", chainId: 0n });
  const [connectedAccount, setConnectedAccount] = useState("Connect");
  const [accountBalance, setAccountBalance] = useState("0 ETH");
  const [signer, setSigner] = useState<JsonRpcSigner>();

  const use = useWalletConnect({
    provider, setProvider,
    setConnectedAccount,
    connectedNetwork, setConnectedNetwork,
    setAccountBalance,
    setSigner
  });

  useEffect(use.plugWallet, []);
  useEffect(use.updateWalletStates, [provider]);

  return (
    <div className="flex justify-self-end
      bg-[var(--wallet-connect-disconnected-background)] mr-1 mt-1 rounded-md
      p-1 items-center justify-center cursor-pointer"
      style={{ backgroundColor: `var(--wallet-connect-${connectedNetwork.chainId ? 'connected' : 'disconnected'}-background)` }}
      onClick={use.connectAndPlugWallet}>
      {connectedAccount}
    </div>
  );
}

