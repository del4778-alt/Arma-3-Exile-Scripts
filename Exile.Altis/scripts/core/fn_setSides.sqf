if (!isServer) exitWith {};

// Reset same-side friendliness
east setFriend [east,1];
west setFriend [west,1];
independent setFriend [independent,1];
resistance setFriend [resistance,1];
civilian setFriend [civilian,1];

// EAST is enemy to everyone else
east setFriend [west,0];
west setFriend [east,0];

east setFriend [independent,0];
independent setFriend [east,0];

east setFriend [resistance,0];
resistance setFriend [east,0];

// Keep non-east sides neutral/friendly with each other (default Exile behaviour)
west setFriend [independent,1];
independent setFriend [west,1];

west setFriend [resistance,1];
resistance setFriend [west,1];

independent setFriend [resistance,1];
resistance setFriend [independent,1];

// Civilians friendly to all non-east
civilian setFriend [west,1];
civilian setFriend [independent,1];
civilian setFriend [resistance,1];
west setFriend [civilian,1];
independent setFriend [civilian,1];
resistance setFriend [civilian,1];

diag_log "[UMC][SIDES] relations applied (EAST enemy to all, others friendly).";
