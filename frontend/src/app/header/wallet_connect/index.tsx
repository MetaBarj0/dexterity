"use client";

import { BrowserProvider, JsonRpcSigner } from "ethers";
import { useEffect, useRef, useState } from "react";
import useWalletConnect, { NetworkInfo } from "./use_wallet_connect";

export default function WalletConnect() {
  const [provider, setProvider] = useState<BrowserProvider>();
  const [connectedNetwork, setConnectedNetwork] = useState<NetworkInfo>({ name: "Disconnected", chainId: 0n });
  const [connectedAccount, setConnectedAccount] = useState("Connect");
  const [, setAccountBalance] = useState("0 ETH");
  const [, setSigner] = useState<JsonRpcSigner>();

  const use = useWalletConnect({
    provider, setProvider,
    setConnectedAccount,
    connectedNetwork, setConnectedNetwork,
    setAccountBalance,
    setSigner
  });
  const plugWalletRef = useRef(use.plugWallet);

  useEffect(() => { plugWalletRef.current = use.plugWallet; }, [use]);
  useEffect(() => { plugWalletRef.current() }, []);
  useEffect(() => use.updateWalletStates(), [use, provider]);

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

