"use client";

import { Props as ParentProps } from "../use_feature_menus";
import { Props } from "./use_trade_dropdown";

export default (props: ParentProps & Props) => {
  const top = props.position?.top;
  const left = props.position?.left;

  return (
    <div
      className="fixed"
      style={{ top: `${top}px`, left: `${left}px` }}
      onMouseOut={() => { props.setDisplayedDropdown(undefined); }}>
      <h1>trade dropdown</h1>
    </div >
  )
};
