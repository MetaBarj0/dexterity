import Menus from "./menus";
import WalletConnect from "./wallet_connect";

export default function Header() {
  return (
    <>
      <div className="grid grid-cols-2">
        <Menus />
        <WalletConnect />
      </div>
    </>);
}
