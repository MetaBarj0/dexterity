import { Props as ParentProps } from "../use_feature_menus";
import { Props } from "./use_pool_dropdown";

export default function PoolDropdown(props: ParentProps & Props) {
  const top = props.position?.top;
  const left = props.position?.left;

  return (
    <div
      className="fixed cursor-pointer"
      style={{ top: `${top}px`, left: `${left}px` }}
      onMouseOver={() => { props.setDisplayedDropdown("Pool"); }}
      onMouseOut={() => { props.setDisplayedDropdown(undefined); }}>
      <h1>pool dropdown</h1>
    </div>
  );
}
