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
	Popinjay John 2018-03-09

---------------------------------------------------------------------------- */

// CBA hashmap to keep track of all drones
// Key = droneID, value = [0 actionID]
CJF_medicDrone_currentDronesLocal = [] call CBA_fnc_hashCreate;
// PublicVariable to keep track of if we are allowed to call a drone.
// CJF_medicDrone_canPlayersRequestDrone
// Keep track of if we have called an drone
CJF_medicDrone_hasRequestedDrone = false;
// Keep track of calldown action ID
CJF_medicDrone_calldownActionID = nil;

CJF_eh_medicDrone_onRegisterDroneAction = {
	params ["_veh"];
	
	// If we are within X meters, show a notification on screen
	// Get player 2d position
	_player2dpos = [];
		titleText ["<t font='TahomaB'> <t size='2' color='#ff0000'>Medic Drone Incoming </t><br /> ETA: T-10 Seconds <br />Stand clear of landing area!</t>", "PLAIN", 1, true, true];
	if ((player distance _veh) <= CJF_medicDrone_maxNotifyDistance) then {
	};
	
	// Hold action
	_actionID = [
		_veh,																// Object the action is attached to
		"Drone heal",														// Title of the action
		"\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_revive_ca.paa",		// Idle icon shown on screen
		"\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_revive_ca.paa",		// Progress icon shown on screen
		"_this distance _target < 3",										// Condition for the action to be shown
		"_caller distance _target < 5",										// Condition for the action to progress
		{[player, "AinvPknlMstpSlayWrflDnon_medic", 1] call ace_common_fnc_doAnimation},																	// Code executed when action starts
		{},																	// Code executed on every progress tick
		{ [player, "", 1] call ace_common_fnc_doAnimation; _this select 0 call CJF_fnc_medicDrone_useHeal;},					// Code executed on completion
		{},																	// Code executed on interrupted
		[],																	// Arguments passed to the scripts as _this select 3
		CJF_medicDrone_holdTime,											// Action duration [s]
		6,																	// Priority
		false,																// Remove on completion
		false																// Show in unconscious state 
	] call BIS_fnc_holdActionAdd;

	// ACE3 Interaction menu
	_action = ["CJF_medicDrone_heal","Heal","",{
		[player, "AinvPknlMstpSlayWrflDnon_medic", 1] call ace_common_fnc_doAnimation;
		[CJF_medicDrone_holdTime, [_target], {
			param [0] params ["_veh"];
			[player, "", 1] call ace_common_fnc_doAnimation;
			_veh call CJF_fnc_medicDrone_useHeal;
		}, "", "Healing..", {
			param [0] params ["_veh"];
			player distance _veh < 3;
		}] call ace_common_fnc_progressBar;
	},{_player distance _target < 5;}, {}, nil, "", 3] call ace_interact_menu_fnc_createAction;
	[_veh, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
	
	// Save hold action ID so we can delete it later
	[CJF_medicDrone_currentDronesLocal, _veh, [_actionID]] call CBA_fnc_hashSet;
};

CJF_eh_medicDrone_onRemoveDroneAction = {
	params ["_veh"];
	
	if (!isNil {[CJF_medicDrone_currentDronesLocal, _veh] call CBA_fnc_hashGet}) then {
		// Fetch hold action ID and remove it
		_droneInfo = [CJF_medicDrone_currentDronesLocal, _veh] call CBA_fnc_hashGet;
		[_veh, _droneInfo select 0] call BIS_fnc_holdActionRemove;
		// Remove ACE3 action
		[_veh, 0, ["ACE_MainActions", "CJF_medicDrone_heal"]] call ace_interact_menu_fnc_removeActionFromObject;
		// Remove it from list of active drones
		[CJF_medicDrone_currentDronesLocal, _veh] call CBA_fnc_hashRem;
	};
};

CJF_eh_medicDrone_onCanPlayersRequestDrone = {
	if (CJF_medicDrone_canPlayersRequestDrone) then { // Is now OK to call drones
		[{call CJF_fnc_medicDrone_registerCalldownActions;}, [], (CJF_medicDrone_maxLoiter + CJF_medicDrone_cooldown)] call CBA_fnc_waitAndExecute;
	} else {
		if (!(isNil "CJF_medicDrone_calldownActionID")) then { 
			call CJF_fnc_medicDrone_removeCalldownActions;
		};
	};
};

CJF_fnc_medicDrone_registerCalldownActions = {
	if (CJF_medicDrone_canPlayersRequestDrone) then {
		// Does player want vanilla action button?
		if (CJF_medicDrone_actionStyle == "both" || CJF_medicDrone_actionStyle == "vanilla") then {
			CJF_medicDrone_calldownActionID = [["Call medic drone", {call CJF_fnc_medicDrone_requestDrone; }]] call CBA_fnc_addPlayerAction;
		};
		// Does player want ACE 3 self-interaction button?
		if (CJF_medicDrone_actionStyle == "both" || CJF_medicDrone_actionStyle == "ace") then {
			_action = ["CJF_medicDrone_Calldown","Call in a medic drone","",{call CJF_fnc_medicDrone_requestDrone;},{true}] call ace_interact_menu_fnc_createAction;
			[player, 1, ["ACE_SelfActions"], _action] call ace_interact_menu_fnc_addActionToObject;
		};
	};
	// If we can call another drone we don't have one currently requested
	CJF_medicDrone_hasRequestedDrone = false;
};

CJF_fnc_medicDrone_removeCalldownActions = {
	if (!(isNil "CJF_medicDrone_calldownActionID")) then {
		// Remove vanilla
		[CJF_medicDrone_calldownActionID] call CBA_fnc_removePlayerAction;
		CJF_medicDrone_calldownActionID = nil;
	};
	// Remove ACE3
	[player, 1, ["ACE_SelfActions", "CJF_medicDrone_Calldown"]] call ace_interact_menu_fnc_removeActionFromObject;
};

CJF_fnc_medicDrone_requestDrone = {
	// Send request for drone
	_pos = player getPos [6, (getDir player)];
	["CJF_medicDrone_requestDrone", [_pos]] call CBA_fnc_serverEvent;
	// We need to know later if we have requested an drone
	CJF_medicDrone_hasRequestedDrone = true;
	// Remove calldown action and re-register it when time has passed.
	call CJF_fnc_medicDrone_removeCalldownActions;
	[{call CJF_fnc_medicDrone_registerCalldownActions;}, [], (CJF_medicDrone_maxLoiter + CJF_medicDrone_cooldown)] call CBA_fnc_waitAndExecute;
};

CJF_fnc_medicDrone_useHeal = {
	params ["_veh"];
	// Tell the server we used a heal
	["CJF_medicDrone_useHeal", [_veh]] call CBA_fnc_serverEvent;
	// Do the healing
	[_veh, player] call ace_medical_fnc_treatmentAdvanced_fullHealLocal;
};

// Event handlers
["CJF_medicDrone_registerDroneAction", {_this call CJF_eh_medicDrone_onRegisterDroneAction}] call CBA_fnc_addEventHandler;
["CJF_medicDrone_removeDroneAction", {_this call CJF_eh_medicDrone_onRemoveDroneAction}] call CBA_fnc_addEventHandler;
["CJF_medicDrone_canPlayersRequestDroneUpdate", {call CJF_eh_medicDrone_onCanPlayersRequestDrone}] call CBA_fnc_addEventHandler;

// End of file, return true for success
true
