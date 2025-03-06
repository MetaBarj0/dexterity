import { Dispatch, RefObject, SetStateAction } from "react";

export type DisplayedDropdown = "Explore" | "Pool" | "Trade";

export type DropdownPosition = {
  top: number,
  left: number
};

export type Props = {
  setDisplayedDropdown: Dispatch<SetStateAction<DisplayedDropdown | undefined>>
};

export const setupAllDropdownsPositionUpdates = (dropdownPositioners: DropdownPositioner[]) => {
  return () => {
    const updateOneDropdownPosition = (
      parentRef: RefObject<HTMLDivElement>,
      setDropdownPosition: Dispatch<SetStateAction<DropdownPosition | undefined>>
    ) => {
      if (!parentRef.current)
        return;

      const rect = parentRef.current.getBoundingClientRect();

      setDropdownPosition({ top: rect.bottom + window.scrollY, left: rect.left });
    }

    const updateAllDropdownPositions = () => {
      dropdownPositioners.forEach(({ setDropdownPosition: dropdownPosition, parentMenuRef }) => {
        updateOneDropdownPosition(parentMenuRef, dropdownPosition);
      });
    };

    updateAllDropdownPositions();

    window.addEventListener("resize", updateAllDropdownPositions);
    window.addEventListener("scroll", updateAllDropdownPositions);

    return () => {
      window.removeEventListener("resize", updateAllDropdownPositions);
      window.removeEventListener("scroll", updateAllDropdownPositions);
    };
  }
};

type DropdownPositioner = {
  setDropdownPosition: Dispatch<SetStateAction<DropdownPosition | undefined>>,
  parentMenuRef: RefObject<HTMLDivElement>
};
