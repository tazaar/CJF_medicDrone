/* ----------------------------------------------------------------------------
Function: CJF_fnc_medicDroneLocal

Description:
	Adds action to call in a medical drone to fully heal ACE3 medical damage.

Parameters:

Returns:
	TRUE when complete

Examples:
    (begin example)
	call CJF_fnc_medicDroneLocal (In initPlayerLocal)
    (end)

Author: 
	Popinjay John 2018-02-14

---------------------------------------------------------------------------- */

// Set initial time so player can't immediately call it
CJF_medicDrone_lastCalled = 0;

// Function that actually heals the player
CJF_fnc_medicDrone_healLocalPlayer = {
		params ["_id"];
		[player, player] call ace_medical_fnc_treatmentAdvanced_fullHealLocal;
		// Tell server we used a heal
		["CJF_eh_medicDroneUsedHeal", [_id]] call CBA_fnc_serverEvent;
};

CJF_medicDroneRegisterActions = {
	// Request medic drone via vanilla Arma 3 action menu unless unwanted
	if (!CJF_medicDrone_ACEonly) then { CJF_medicDroneAction = player addAction ["Call medic drone", {call CJF_fnc_medicDroneRequester; } ]; };
	// And also via ACE3 Self-interaction menu
	_action = ["CJF_medicDroneAction","Call in a medic drone","",{call CJF_fnc_medicDroneRequester;},{true}] call ace_interact_menu_fnc_createAction;
	[player, 1, ["ACE_SelfActions"], _action] call ace_interact_menu_fnc_addActionToObject;
};

// [{call _registerActions;}, [], (CJF_medicDrone_maxLoiter + CJF_medicDrone_cooldown)] call CBA_fnc_waitAndExecute;
[{call CJF_medicDroneRegisterActions;}, [], 2] call CBA_fnc_waitAndExecute;

// Send request to server for medic drone
CJF_fnc_medicDroneRequester = {
	// Check if time has exceeded minimum time between calls
	// if (time >= (CJF_medicDrone_lastCalled + CJF_medicDrone_maxLoiter + CJF_medicDrone_cooldown)) then {
	if (true) then {
		_pos = player getPos [6, (getDir player)];
		["CJF_eh_medicDroneRequest", [_pos]] call CBA_fnc_serverEvent;
		CJF_medicDrone_lastCalled = time;
		// Get rid of vanilla and ACE3 actions until they actually can be called again.
		player removeAction CJF_medicDroneAction;
		[player, 1, ["ACE_SelfActions", "CJF_medicDroneAction"]] call ace_interact_menu_fnc_removeActionFromObject;
		[{call CJF_medicDroneRegisterActions;}, [], (CJF_medicDrone_maxLoiter + CJF_medicDrone_cooldown)] call CBA_fnc_waitAndExecute;
	};
	
};

// End of file, return true for success
true
