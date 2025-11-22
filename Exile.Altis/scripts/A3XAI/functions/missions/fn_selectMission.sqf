/*
    A3XAI Elite - Select Mission
    Selects a mission type based on weighted probabilities

    Parameters:
        None

    Returns:
        STRING - Mission type: "convoy", "crash", "camp", "hunter", "cache", "outpost", "supplyDrop"

    v3.0: Replaced "rescue" with "cache" (no CIVILIAN hostages = no faction conflicts)
*/

// Define mission weights if not already defined
if (isNil "A3XAI_missionWeights") then {
    A3XAI_missionWeights = createHashMapFromArray [
        ["convoy", 0.20],
        ["crash", 0.20],
        ["camp", 0.15],
        ["hunter", 0.10],
        ["cache", 0.15],           // Replaces rescue - weapons cache
        ["outpost", 0.10],
        ["supplyDrop", 0.10]
    ];
};

// Build weighted array
private _weightedMissions = [];

{
    private _missionType = _x;
    private _weight = _y;

    // Add mission multiple times based on weight (0.0-1.0 converted to 0-100)
    private _count = floor(_weight * 100);

    for "_i" from 1 to _count do {
        _weightedMissions pushBack _missionType;
    };
} forEach A3XAI_missionWeights;

// Select random mission from weighted array
private _selectedMission = if (count _weightedMissions > 0) then {
    selectRandom _weightedMissions
} else {
    // Fallback to equal probability
    selectRandom ["convoy", "crash", "camp", "hunter", "cache", "outpost", "supplyDrop"]
};

_selectedMission
