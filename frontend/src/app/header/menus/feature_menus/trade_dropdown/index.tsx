import { States } from "../use_feature_menus";

export default (states: States) => {
  return (
    <div className="fixed top-15" onMouseOut={() => { states.setDisplayedDropdown(undefined); }}>
      <h1>trade dropdown</h1>
    </div>
  );
}
