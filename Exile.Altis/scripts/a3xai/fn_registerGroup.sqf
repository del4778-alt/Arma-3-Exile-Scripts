params ["_grp"];

private _all = A3XAI get "activeGroups";
_all pushBackUnique _grp;
A3XAI set ["activeGroups", _all];

_grp
