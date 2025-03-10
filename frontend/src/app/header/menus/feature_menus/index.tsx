"use client";

import { useEffect, useRef, useState } from "react";
import Explore from "./explore";
import ExploreDropdown from "./explore_dropdown";
import Pool from "./pool";
import PoolDropdown from "./pool_dropdown";
import Trade from "./trade";
import TradeDropdown from "./trade_dropdown";
import { DisplayedDropdown, DropdownPosition, setupAllDropdownsPositionUpdates } from "./use_feature_menus";

export default function FeatureMenus() {
  const [displayedDropdown, setDisplayedDropdown] = useState<DisplayedDropdown>();
  const [tradeDropdownPosition, setTradeDropdownPosition] = useState<DropdownPosition>();
  const [exploreDropdownPosition, setExploreDropdownPosition] = useState<DropdownPosition>();
  const [poolDropdownPosition, setPoolDropdownPosition] = useState<DropdownPosition>();

  const tradeMenuRef = useRef<HTMLDivElement>(undefined!);
  const exploreMenuRef = useRef<HTMLDivElement>(undefined!);
  const poolMenuRef = useRef<HTMLDivElement>(undefined!);

  useEffect(() => {
    setupAllDropdownsPositionUpdates(
      [
        { setDropdownPosition: setTradeDropdownPosition, parentMenuRef: tradeMenuRef },
        { setDropdownPosition: setExploreDropdownPosition, parentMenuRef: exploreMenuRef },
        { setDropdownPosition: setPoolDropdownPosition, parentMenuRef: poolMenuRef }
      ]
    )
  }, []);

  return (
    <div className="ml-8 flex">
      <div className="grid grid-cols-3 gap-4 mt-1 font-black">
        <Trade ref={tradeMenuRef} setDisplayedDropdown={setDisplayedDropdown} />
        <Explore ref={exploreMenuRef} setDisplayedDropdown={setDisplayedDropdown} />
        <Pool ref={poolMenuRef} setDisplayedDropdown={setDisplayedDropdown} />

        {displayedDropdown === "Trade" &&
          <TradeDropdown setDisplayedDropdown={setDisplayedDropdown} position={tradeDropdownPosition} />}

        {displayedDropdown === "Explore" &&
          <ExploreDropdown setDisplayedDropdown={setDisplayedDropdown} position={exploreDropdownPosition} />}

        {displayedDropdown === "Pool" &&
          <PoolDropdown setDisplayedDropdown={setDisplayedDropdown} position={poolDropdownPosition} />}
      </div>
    </div>
  );
}
