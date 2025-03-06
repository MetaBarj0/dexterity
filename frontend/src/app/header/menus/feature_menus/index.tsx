"use client";

import { useEffect, useRef, useState } from "react";
import Explore from "./explore";
import ExploreDropdown from "./explore_dropdown";
import Pool from "./pool";
import PoolDropdown from "./pool_dropdown";
import Trade from "./trade";
import TradeDropdown from "./trade_dropdown";
import { DisplayedDropdown } from "./use_feature_menus"
import { DropdownPosition } from "./trade_dropdown/use_trade_dropdown";

export default () => {
  const [displayedDropdown, setDisplayedDropdown] = useState<DisplayedDropdown>();
  const [dropdownPosition, setDropdownPosition] = useState<DropdownPosition>();

  const menuRef = useRef<HTMLDivElement>(undefined!);

  useEffect(() => {
    const updateDropdownPosition = () => {
      if (!menuRef.current)
        return;

      const rect = menuRef.current.getBoundingClientRect();

      setDropdownPosition({ top: rect.bottom + window.scrollY, left: rect.left });
    }

    updateDropdownPosition();

    window.addEventListener("resize", updateDropdownPosition);
    window.addEventListener("scroll", updateDropdownPosition);

    return () => {
      window.removeEventListener("resize", updateDropdownPosition);
      window.removeEventListener("scroll", updateDropdownPosition);
    };
  }, []);

  return (
    <div className="ml-8 flex">
      <div className="grid grid-cols-3 gap-4 mt-1 font-black">
        <Trade ref={menuRef} setDisplayedDropdown={setDisplayedDropdown} />
        <Explore setDisplayedDropdown={setDisplayedDropdown} />
        <Pool setDisplayedDropdown={setDisplayedDropdown} />

        {displayedDropdown === "Trade" &&
          <TradeDropdown setDisplayedDropdown={setDisplayedDropdown} position={dropdownPosition} />}

        {displayedDropdown === "Explore" &&
          <ExploreDropdown setDisplayedDropdown={setDisplayedDropdown} />}

        {displayedDropdown === "Pool" &&
          <PoolDropdown setDisplayedDropdown={setDisplayedDropdown} />}
      </div>
    </div>
  );
}
