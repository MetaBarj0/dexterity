import RootMenu from "./root_menu"
import FeatureMenus from "./feature_menus"

export default function Menu() {
  return (
    <div className="flex">
      <RootMenu />
      <FeatureMenus />
    </div>
  );
}
