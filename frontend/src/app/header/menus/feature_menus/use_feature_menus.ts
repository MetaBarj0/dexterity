import { Dispatch, RefObject, SetStateAction } from "react";
import { DropdownPosition } from "./trade_dropdown/use_trade_dropdown";

export type DisplayedDropdown = "Explore" | "Pool" | "Trade";

export type Props = {
  setDisplayedDropdown: Dispatch<SetStateAction<DisplayedDropdown | undefined>>
};

export const setupDropdownPositionUpdates = (args: {
  parentMenuRef: RefObject<HTMLDivElement>,
  setDropdownPosition: Dispatch<SetStateAction<DropdownPosition | undefined>>
}) => {
  return () => {
    const updateDropdownPosition = () => {
      if (!args.parentMenuRef.current)
        return;

      const rect = args.parentMenuRef.current.getBoundingClientRect();

      args.setDropdownPosition({ top: rect.bottom + window.scrollY, left: rect.left });
    }

    updateDropdownPosition();

    window.addEventListener("resize", updateDropdownPosition);
    window.addEventListener("scroll", updateDropdownPosition);

    return () => {
      window.removeEventListener("resize", updateDropdownPosition);
      window.removeEventListener("scroll", updateDropdownPosition);
    };
  }
}
