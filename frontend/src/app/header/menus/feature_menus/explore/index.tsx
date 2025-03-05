import { States } from "../use_feature_menus"

export default (states: States) => {
  return (
    <div
      className="bg-gray-100 rounded-md h-full text-center content-center"
      onMouseOver={() => {
        states.setDisplayedDropdown("Explore");
      }}>
      explore
    </div>
  );
}
