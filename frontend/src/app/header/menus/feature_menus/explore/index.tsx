import { forwardRef } from "react";
import { Props } from "../use_feature_menus"

export default forwardRef<HTMLDivElement, Props>((props: Props, ref) => {
  return (
    <div
      ref={ref}
      className="bg-[var(--menu-button-background)] rounded-md h-full text-center content-center cursor-pointer"
      onMouseOver={() => {
        props.setDisplayedDropdown("Explore");
      }}>
      explore
    </div>
  );
});
