"use client";

import { forwardRef } from "react";
import { Props } from "../use_feature_menus";

export default forwardRef<HTMLDivElement, Props>((props: Props, ref) => {
  // TODO: pointer cursor for all menu
  return (
    <div ref={ref}
      className="bg-[var(--menu-button-background)] rounded-md h-full text-center content-center"
      onMouseOver={() => {
        props.setDisplayedDropdown("Trade");
      }}>
      trade
    </div>
  );
});
