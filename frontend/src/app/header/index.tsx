import Menus from "./menus";
import WalletConnect from "./wallet_connect";

export default () => (
  <>
    <div className="grid grid-cols-2">
      <Menus />
      <WalletConnect />
    </div>
  </>);
