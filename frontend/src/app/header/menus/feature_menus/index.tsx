"use client";

import { useEffect, useRef, useState } from "react";
import Explore from "./explore";
import ExploreDropdown from "./explore_dropdown";
import Pool from "./pool";
import PoolDropdown from "./pool_dropdown";
import Trade from "./trade";
import TradeDropdown from "./trade_dropdown";
import { DropdownPosition } from "./trade_dropdown/use_trade_dropdown";
import { DisplayedDropdown, setupDropdownPositionUpdates } from "./use_feature_menus";

export default () => {
  const [displayedDropdown, setDisplayedDropdown] = useState<DisplayedDropdown>();
  const [dropdownPosition, setDropdownPosition] = useState<DropdownPosition>();

  const parentMenuRef = useRef<HTMLDivElement>(undefined!);

  useEffect(setupDropdownPositionUpdates({ parentMenuRef, setDropdownPosition }), []);

  return (
    <div className="ml-8 flex">
      <div className="grid grid-cols-3 gap-4 mt-1 font-black">
        <Trade ref={parentMenuRef} setDisplayedDropdown={setDisplayedDropdown} />
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
