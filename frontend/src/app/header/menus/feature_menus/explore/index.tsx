import { forwardRef } from "react";
import { Props } from "../use_feature_menus"

export default forwardRef<HTMLDivElement, Props>(function Explore(props: Props, ref) {
  return (
    <div
      ref={ref}
      className="bg-[var(--menu-button-background)] rounded-md h-full text-center content-center cursor-pointer"
      onMouseOver={() => { props.setDisplayedDropdown("Explore"); }}
      onMouseOut={() => { props.setDisplayedDropdown(undefined); }}
    >
      explore
    </div>
  );
});
