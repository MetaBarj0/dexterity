import { Props } from "../use_feature_menus"

export default (props: Props) => {
  return (
    <div
      className="bg-[var(--menu-button-background)] rounded-md h-full text-center content-center"
      onMouseOver={() => {
        props.setDisplayedDropdown("Pool");
      }}>
      pool
    </div>
  );
}

