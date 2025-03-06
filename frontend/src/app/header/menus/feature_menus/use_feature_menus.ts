import { Dispatch, SetStateAction } from "react";

export type DisplayedDropdown = "Explore" | "Pool" | "Trade";

export type Props = {
  setDisplayedDropdown: Dispatch<SetStateAction<DisplayedDropdown | undefined>>
};
