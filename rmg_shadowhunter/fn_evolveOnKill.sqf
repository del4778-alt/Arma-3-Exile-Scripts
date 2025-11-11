
params ["_unit", "_victim"];

SHW_accuracy = SHW_accuracy + 0.02;
SHW_aggression = SHW_aggression + 20;
SHW_loadoutTier = SHW_loadoutTier + 1 min 5;

SHW_lastKnownHotspots pushBack (getPosATL _victim);
if (count SHW_lastKnownHotspots > 5) then {
    SHW_lastKnownHotspots deleteAt 0;
};

publicVariable "SHW_accuracy";
publicVariable "SHW_aggression";
publicVariable "SHW_loadoutTier";
publicVariable "SHW_lastKnownHotspots";
