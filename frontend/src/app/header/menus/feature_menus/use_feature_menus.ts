import { Dispatch, SetStateAction } from "react";

export type DisplayedDropdown = "Explore" | "Pool" | "Trade";

export type States = {
  setDisplayedDropdown: Dispatch<SetStateAction<DisplayedDropdown | undefined>>
};
