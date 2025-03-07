import { Props as ParentProps } from "../use_feature_menus";
import { Props } from "./use_explore_dropdown";

export default (props: ParentProps & Props) => {
  const top = props.position?.top;
  const left = props.position?.left;

  return (
    <div
      className="fixed cursor-pointer"
      style={{ top: `${top}px`, left: `${left}px` }}
      onMouseOver={() => { props.setDisplayedDropdown("Explore"); }}
      onMouseOut={() => { props.setDisplayedDropdown(undefined); }}>
      <h1>explore dropdown</h1>
    </div>
  );
}
