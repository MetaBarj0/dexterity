"use client";

import useWalletConnect from "./use_wallet_connect"

export default () => {
  const use = useWalletConnect();

  return (
    <div className="flex justify-self-end
      bg-[var(--wallet-connect-disconnected-background)] mr-1 mt-1 rounded-md
      p-1 items-center justify-center cursor-pointer"
      onClick={use.handleClick}>
      Connect
    </div>
  );
}

