/**
 * Warbands XM8 Application
 * Mount & Blade style faction management for Exile
 */

private _display = uiNameSpace getVariable ["RscExileXM8", displayNull];
if (isNull _display) exitWith {};

// Player's current warbands data
_playerFaction = player getVariable ["WB_Faction", ""];
_playerRank = player getVariable ["WB_Rank", 0];
_playerRenown = player getVariable ["WB_Renown", 0];
_playerHonor = player getVariable ["WB_Honor", 0];
_playerCompanions = player getVariable ["WB_Companions", []];
_playerTroops = player getVariable ["WB_Troops", 0];

// Clear the slide
(_display displayCtrl 4007) ctrlSetStructuredText parseText "";
(_display displayCtrl 4008) ctrlSetStructuredText parseText "";

// Create Warbands header
_html = "<t size='1.4' font='PuristaMedium' color='#ff8c00'>WARBANDS</t><br/>";
_html = _html + "<t size='0.8' color='#888888'>Mount & Blade Faction System</t><br/><br/>";

// Show player status
if (_playerFaction != "") then {
    _factionName = switch (_playerFaction) do {
        case "WEST": {"Kingdom of Altis"};
        case "EAST": {"Eastern Empire"};
        case "GUER": {"Free Companies"};
        case "CIV": {"Merchant Guild"};
        default {"Unknown"};
    };

    _rankName = switch (_playerRank) do {
        case 0: {"Recruit"};
        case 1: {"Soldier"};
        case 2: {"Veteran"};
        case 3: {"Elite"};
        case 4: {"Commander"};
        case 5: {"Lord/Lady"};
        default {"Unknown"};
    };

    _html = _html + "<t size='1.1' color='#4CAF50'>Your Status</t><br/>";
    _html = _html + format["<t color='#ffffff'>Faction: </t><t color='#ff8c00'>%1</t><br/>", _factionName];
    _html = _html + format["<t color='#ffffff'>Rank: </t><t color='#FFD700'>%1</t><br/>", _rankName];
    _html = _html + format["<t color='#ffffff'>Renown: </t><t color='#4CAF50'>%1</t><br/>", _playerRenown];
    _html = _html + format["<t color='#ffffff'>Honor: </t><t color='#2196F3'>%1</t><br/>", _playerHonor];
    _html = _html + format["<t color='#ffffff'>Troops: </t><t color='#FF5722'>%1</t><br/><br/>", _playerTroops];
} else {
    _html = _html + "<t size='1' color='#F44336'>Not in a Faction</t><br/>";
    _html = _html + "<t size='0.8' color='#888888'>Join a faction to begin your conquest</t><br/><br/>";
};

// Faction information
_html = _html + "<t size='1.1' color='#4CAF50'>Available Factions</t><br/>";

_factions = [
    ["WEST", "Kingdom of Altis", "Democratic kingdom controlling western territories"],
    ["EAST", "Eastern Empire", "Military empire from the east"],
    ["GUER", "Free Companies", "Independent mercenary bands"],
    ["CIV", "Merchant Guild", "Wealthy traders and craftsmen"]
];

{
    _x params ["_id", "_name", "_desc"];
    _factionTreasury = missionNamespace getVariable [format["WB_Treasury_%1", _id], 0];
    _factionTerritories = {(_x select 2) == _id} count (missionNamespace getVariable ["WB_Zones", []]);

    _html = _html + format["<t color='#ff8c00'>%1</t><br/>", _name];
    _html = _html + format["<t size='0.8' color='#cccccc'>%1</t><br/>", _desc];
    _html = _html + format["<t size='0.7' color='#888888'>Treasury: %1 | Territories: %2</t><br/><br/>", _factionTreasury, _factionTerritories];
} forEach _factions;

(_display displayCtrl 4007) ctrlSetStructuredText parseText _html;

// Second column - Actions
_html2 = "<t size='1.1' color='#4CAF50'>Actions</t><br/><br/>";

// Faction actions
if (_playerFaction != "") then {
    _html2 = _html2 + "<t size='1' color='#ffffff'>Faction Commands</t><br/>";
    _html2 = _html2 + "<execute expression='[] call WB_fnc_viewTreasury'>View Treasury</execute><br/>";
    _html2 = _html2 + "<execute expression='[] call WB_fnc_viewContracts'>Available Contracts</execute><br/>";
    _html2 = _html2 + "<execute expression='[] call WB_fnc_recruitTroops'>Recruit Troops</execute><br/>";
    _html2 = _html2 + "<execute expression='[] call WB_fnc_managePrisoners'>Manage Prisoners</execute><br/>";
    _html2 = _html2 + "<execute expression='[] call WB_fnc_leaveFaction'>Leave Faction</execute><br/><br/>";

    _html2 = _html2 + "<t size='1' color='#ffffff'>Kingdom Actions</t><br/>";
    _html2 = _html2 + "<execute expression='[] call WB_fnc_declareWar'>Declare War</execute><br/>";
    _html2 = _html2 + "<execute expression='[] call WB_fnc_proposePeace'>Propose Peace</execute><br/>";
    _html2 = _html2 + "<execute expression='[] call WB_fnc_upgradeVillage'>Upgrade Village</execute><br/>";

    if (_playerRank >= 4) then {
        _html2 = _html2 + "<execute expression='[] call WB_fnc_orderSiege'>Order Siege</execute><br/>";
        _html2 = _html2 + "<execute expression='[] call WB_fnc_sendCaravan'>Send Caravan</execute><br/>";
    };
} else {
    _html2 = _html2 + "<t size='1' color='#ffffff'>Join a Faction</t><br/>";
    _html2 = _html2 + "<execute expression=\"['WEST'] call WB_fnc_joinFaction\">Join Kingdom of Altis</execute><br/>";
    _html2 = _html2 + "<execute expression=\"['EAST'] call WB_fnc_joinFaction\">Join Eastern Empire</execute><br/>";
    _html2 = _html2 + "<execute expression=\"['GUER'] call WB_fnc_joinFaction\">Join Free Companies</execute><br/>";
    _html2 = _html2 + "<execute expression=\"['CIV'] call WB_fnc_joinFaction\">Join Merchant Guild</execute><br/><br/>";
};

// Arena
_html2 = _html2 + "<br/><t size='1' color='#ffffff'>Arena</t><br/>";
_html2 = _html2 + "<execute expression='[] call WB_fnc_joinArena'>Join Arena Queue</execute><br/>";
_html2 = _html2 + "<execute expression='[] call WB_fnc_spectateArena'>Spectate Arena</execute><br/>";

// Skills
_html2 = _html2 + "<br/><t size='1' color='#ffffff'>Character</t><br/>";
_html2 = _html2 + "<execute expression='[] call WB_fnc_viewSkills'>View Skills</execute><br/>";
_html2 = _html2 + "<execute expression='[] call WB_fnc_viewCompanions'>Manage Companions</execute><br/>";

(_display displayCtrl 4008) ctrlSetStructuredText parseText _html2;

true
