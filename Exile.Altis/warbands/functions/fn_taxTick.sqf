if (!isServer) exitWith {};
#include "..\config\WB_CfgEconomy.hpp"
#include "..\systems\WB_Treasury.sqf"

private _sec = WB_TAX_TICK_MINUTES * 60;
while { true } do {
    {
        private _fid = _x select 0;
        private _zones = WB_zones select { (_x select 3) isEqualTo _fid };
        private _yield = 0;
        { private _tier = _x select 2; private _mult = WB_zoneTierMultiplier select (_tier-1 max 0 min 2); _yield = _yield + round (WB_baseTaxRatePerZone * _mult); } forEach _zones;
        if (_yield > 0) then { [_fid,_yield] call WB_addTreasury; };
    } forEach WB_factions;
    uiSleep _sec;
};
