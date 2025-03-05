import RootMenu from "./root_menu"
import FeatureMenus from "./feature_menus"

export default () => {
  return (
    <div className="flex">
      <RootMenu />
      <FeatureMenus />
    </div>
  );
}
