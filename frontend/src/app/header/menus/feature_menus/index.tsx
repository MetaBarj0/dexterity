"use client";

import { useState } from "react";
import Explore from "./explore";
import ExploreDropdown from "./explore_dropdown";
import Pool from "./pool";
import PoolDropdown from "./pool_dropdown";
import Trade from "./trade";
import TradeDropdown from "./trade_dropdown";
import { DisplayedDropdown } from "./use_feature_menus"

export default () => {
  const [displayedDropdown, setDisplayedDropdown] = useState<DisplayedDropdown>();

  return (
    <div className="ml-8 flex">
      <div className="grid grid-cols-3 gap-4 mt-1 font-black">
        <Trade setDisplayedDropdown={setDisplayedDropdown} />
        <Explore setDisplayedDropdown={setDisplayedDropdown} />
        <Pool setDisplayedDropdown={setDisplayedDropdown} />

        {displayedDropdown === "Trade" &&
          <TradeDropdown setDisplayedDropdown={setDisplayedDropdown} />}

        {displayedDropdown === "Explore" &&
          <ExploreDropdown setDisplayedDropdown={setDisplayedDropdown} />}

        {displayedDropdown === "Pool" &&
          <PoolDropdown setDisplayedDropdown={setDisplayedDropdown} />}
      </div>
    </div>
  );
}
