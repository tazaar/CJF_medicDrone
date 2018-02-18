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
	Popinjay John 2018-02-18

---------------------------------------------------------------------------- */

// TODO; Add user changable actions ace or vanilla or both.

// Set initial time to zero and save an function call :)
CJF_medicDrone_lastCalled = 0;
// Is the action currently callable?
CJF_medicDrone_isCallable = false;
// Keep track if we are under players online limit
CJF_medicDrone_underPlayersLimit = nil;

// Function that actually heals the player
CJF_fnc_medicDroneHealLocalPlayer = {
		params ["_id"];
		[player, player] call ace_medical_fnc_treatmentAdvanced_fullHealLocal;
		// Tell server we used a heal
		["CJF_eh_medicDroneUsedHeal", [_id]] call CBA_fnc_serverEvent;
};

CJF_fnc_medicDroneRegisterActions = {
	// Does player want vanilla action button?
	if (CJF_medicDrone_actionStyle == "both" || CJF_medicDrone_actionStyle == "vanilla") then { CJF_medicDroneAction = player addAction ["Call medic drone", {call CJF_fnc_medicDroneRequester; } ]; };
	// Does player want ACE 3 self-interaction button?
	if (CJF_medicDrone_actionStyle == "both" || CJF_medicDrone_actionStyle == "ace") then {
		_action = ["CJF_medicDroneAction","Call in a medic drone","",{call CJF_fnc_medicDroneRequester;},{true}] call ace_interact_menu_fnc_createAction;
		[player, 1, ["ACE_SelfActions"], _action] call ace_interact_menu_fnc_addActionToObject;
	};
	CJF_medicDrone_isCallable = true;
};

CJF_fnc_medicDroneRemoveActions = {
	if (CJF_medicDrone_actionStyle == "both" || CJF_medicDrone_actionStyle == "vanilla") then {
		// Remove vanilla
		player removeAction CJF_medicDroneAction;
	};
	if (CJF_medicDrone_actionStyle == "both" || CJF_medicDrone_actionStyle == "ace") then {
		// Remove ACE3
		[player, 1, ["ACE_SelfActions", "CJF_medicDroneAction"]] call ace_interact_menu_fnc_removeActionFromObject;
	};
	CJF_medicDrone_isCallable = false;
};

// Send request to server for medic drone
CJF_fnc_medicDroneRequester = {
	// Check if time has exceeded minimum time between calls
	if (time >= (CJF_medicDrone_lastCalled + CJF_medicDrone_maxLoiter + CJF_medicDrone_cooldown)) then {
		_pos = player getPos [6, (getDir player)];
		["CJF_eh_medicDroneRequest", [_pos]] call CBA_fnc_serverEvent;
		CJF_medicDrone_lastCalled = time;
		// Get rid of actions until they can be called again.
		call CJF_fnc_medicDroneRemoveActions:
		[{call CJF_fnc_medicDroneCheckAndAddActions;}, [], (CJF_medicDrone_maxLoiter + CJF_medicDrone_cooldown)] call CBA_fnc_waitAndExecute;
	};	
};

// Restrict useage if player number is greater than setting
CJF_fnc_medicDroneCheckAndAddActions = {
	if (CJF_medicDrone_underPlayersLimit == true) then {
		call CJF_fnc_medicDroneRegisterActions;
	}
};

CJF_eh_medicDronePlayersChanged = {
	if ((count allPlayers) <= CJF_medicDrone_maxOnline) then { // If we are under limit
		CJF_medicDrone_underPlayersLimit = true;
	} else {
		// Remove actions if it was active
		if (CJF_medicDrone_isCallable == true) then {
			call CJF_fnc_medicDroneRemoveActions;
		};
		CJF_medicDrone_underPlayersLimit = false;
	};
};

// Call event and check once to kick things off
call CJF_eh_medicDronePlayersChanged;
[{call CJF_fnc_medicDroneCheckAndAddActions;}, [], (CJF_medicDrone_maxLoiter + CJF_medicDrone_cooldown)] call CBA_fnc_waitAndExecute;

addMissionEventHandler ["PlayerConnected", "CJF_eh_medicDronePlayersChanged"];
addMissionEventHandler ["PlayerDisconnected", "CJF_eh_medicDronePlayersChanged"];

// End of file, return true for success
true
