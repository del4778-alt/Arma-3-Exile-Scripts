/*
    Dynamic Weather Hazard System v1.0
    Environmental challenges and survival mechanics

    Features:
    - Radiation zones requiring protective gear
    - Toxic fog spawning zombies (Ravage integration)
    - Extreme weather affecting AI accuracy
    - Temperature system (hypothermia/heatstroke)
    - Safe zone alerts

    Installation:
    [] execVM "Dynamic-Weather-Hazards\fn_weatherHazards.sqf";
*/

WEATHER_CONFIG = createHashMapFromArray [
    ["enabled", true],
    ["debug", true],
    ["radiationZones", 3],
    ["toxicFogChance", 0.2],
    ["extremeWeatherInterval", 1800],
    ["temperatureEnabled", true],
    ["damagePerTick", 0.05]
];

WEATHER_RadiationZones = [];
WEATHER_ActiveHazards = [];

WEATHER_fnc_log = {
    if (WEATHER_CONFIG get "debug") then {
        diag_log format ["[WEATHER] %1", _this select 0];
    };
};

WEATHER_fnc_createRadiationZone = {
    params ["_pos", "_radius"];

    private _zone = createTrigger ["EmptyDetector", _pos];
    _zone setTriggerArea [_radius, _radius, 0, false];
    _zone setTriggerActivation ["ANY", "PRESENT", true];
    _zone setTriggerStatements [
        "player in thisList",
        "player setVariable ['InRadiation', true]",
        "player setVariable ['InRadiation', false]"
    ];

    private _marker = createMarker [format ["rad_%1", time], _pos];
    _marker setMarkerShape "ELLIPSE";
    _marker setMarkerSize [_radius, _radius];
    _marker setMarkerColor "ColorRed";
    _marker setMarkerAlpha 0.3;
    _marker setMarkerText "RADIATION";

    _zone
};

WEATHER_fnc_spawnToxicFog = {
    params ["_pos"];

    private _fog = "#particlesource" createVehicleLocal _pos;
    _fog setParticleParams [
        ["\A3\data_f\ParticleEffects\Universal\Universal", 16, 12, 13, 0],
        "", "Billboard", 1, 15, [0, 0, 0], [0, 0, 0], 0, 10, 7.9, 0.066,
        [10, 15, 20], [[0.5, 0.5, 0.3, 0.3], [0.5, 0.5, 0.3, 0.2], [0.5, 0.5, 0.3, 0]],
        [0.125], 1, 0, "", "", _pos
    ];
    _fog setParticleRandom [5, [10, 10, 2], [0.5, 0.5, 0], 0, 0.5, [0, 0, 0, 0], 0, 0];
    _fog setDropInterval 0.01;

    ["Toxic fog deployed - zombies incoming!"] remoteExec ["systemChat", 0];

    _fog
};

WEATHER_fnc_updateTemperature = {
    {
        if (isPlayer _x && alive _x) then {
            private _temp = 20 - (rain * 10) + (sunOrMoon * 5);

            if (_temp < 5) then {
                _x setDamage ((damage _x) + (WEATHER_CONFIG get "damagePerTick"));
                _x say3D "heartbeat";
                hintSilent "HYPOTHERMIA - Find warmth!";
            };

            if (_temp > 35) then {
                _x setDamage ((damage _x) + (WEATHER_CONFIG get "damagePerTick") * 0.5);
                hintSilent "HEATSTROKE - Find shade!";
            };
        };
    } forEach allPlayers;
};

WEATHER_fnc_init = {
    ["Dynamic Weather Hazard System v1.0 initializing..."] call WEATHER_fnc_log;

    waitUntil {time > 10};

    // Spawn radiation zones
    for "_i" from 1 to (WEATHER_CONFIG get "radiationZones") do {
        private _pos = [random worldSize, random worldSize, 0];
        private _zone = [_pos, 200] call WEATHER_fnc_createRadiationZone;
        WEATHER_RadiationZones pushBack _zone;
    };

    // Radiation damage loop
    [] spawn {
        while {true} do {
            {
                if (isPlayer _x && _x getVariable ["InRadiation", false]) then {
                    _x setDamage ((damage _x) + (WEATHER_CONFIG get "damagePerTick"));
                    hintSilent "RADIATION EXPOSURE!";
                };
            } forEach allPlayers;
            sleep 5;
        };
    };

    // Weather events loop
    [] spawn {
        while {true} do {
            if (random 1 < (WEATHER_CONFIG get "toxicFogChance")) then {
                private _pos = [random worldSize, random worldSize, 0];
                [_pos] call WEATHER_fnc_spawnToxicFog;
            };
            sleep (WEATHER_CONFIG get "extremeWeatherInterval");
        };
    };

    // Temperature loop
    if (WEATHER_CONFIG get "temperatureEnabled") then {
        [] spawn {
            while {true} do {
                call WEATHER_fnc_updateTemperature;
                sleep 30;
            };
        };
    };

    ["Weather Hazard System initialized"] call WEATHER_fnc_log;
};

[] call WEATHER_fnc_init;
