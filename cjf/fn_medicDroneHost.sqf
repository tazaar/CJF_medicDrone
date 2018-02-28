/* ----------------------------------------------------------------------------
Function: CJF_fnc_medicDroneLocal

Description:
	Adds server side functions for medical drone.

Parameters:

Returns:
	TRUE when complete

Examples:
    (begin example)
	call CJF_fnc_medicDroneHost (In initServer)
    (end)

Author: 
	Popinjay John 2018-02-18

---------------------------------------------------------------------------- */

// CBA hashmap to keep track of all drones
CJF_medicDrone_drones = [] call CBA_fnc_hashCreate;

// Called from client for each drone spawn
CJF_fnc_medicDroneSpawn = {
	params ["_pos"];

	// Spawn helipad because arma..
	_pad = "HeliH" createVehicle _pos;
	// Spawn drone above player
	_veh = createVehicle["B_UAV_06_medical_F", _pos, [], 0, "FLY"]; createVehicleCrew _veh;
	
	// Clear cargo of existing items and add our custom ones
	clearItemCargoGlobal _veh;
	_veh addItemCargoGlobal ["ACE_fieldDressing", 10];
	_veh addItemCargoGlobal ["ACE_elasticBandage", 10];
	_veh addItemCargoGlobal ["ACE_quikclot", 5];
	_veh addItemCargoGlobal ["ACE_packingBandage", 5];
	_veh addItemCargoGlobal ["ACE_morphine", 5];
	_veh addItemCargoGlobal ["ACE_tourniquet", 5];
	
	// Add drone and pad to server list of drones key = droneID, value = Current uses, vehicle and pad object
	[CJF_medicDrone_drones, _veh, [CJF_medicDrone_maxUses, _veh, _pad]] call CBA_fnc_hashSet;

	// Add our healing action/interaction to drone, Heal is a local function
	// Vanilla Arma 3 action menu
	[_veh, ["Heal", {_this select 0 call CJF_fnc_medicDroneHealLocalPlayer;}]] remoteExec ["addAction", 0, _veh];
	// ACE3 Interaction menu
	_action = ["droneHeal","Heal","",{_this select 0 call CJF_fnc_medicDroneHealLocalPlayer;},{true}] call ace_interact_menu_fnc_createAction;
	// [_veh, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
	[_veh, 0, ["ACE_MainActions"], _action] remoteExec ["ace_interact_menu_fnc_addActionToObject", 0, _veh];

	// Tell drone to land
	_veh land "LAND";
	// Wait loiter time then remove after loiter has expired
	[CJF_fnc_medicDroneRemove, [_veh], CJF_medicDrone_maxLoiter] call CBA_fnc_waitAndExecute;
	// If drone died, remove actions
	_veh addEventHandler ["Killed",{(_this select 0) call CJF_fnc_medicDroneRemoveActions;}];
};

// Remove actions from drone
CJF_fnc_medicDroneRemoveActions = {
	params ["_id"];
	// get our vehicle array, If it's not here actions has already been removed
	if (!isNil {[CJF_medicDrone_drones, _id] call CBA_fnc_hashGet}) then {
		_drone = [CJF_medicDrone_drones, _id] call CBA_fnc_hashGet;
		// Get our drone vehicle
		_veh = _drone select 1;
		[_veh] remoteExec ["removeAllActions", 0];
		[_veh, 0,["ACE_MainActions", "droneHeal"]] remoteExec ["ace_interact_menu_fnc_removeActionFromObject", 0];
	};
};

// Fly away and despawn objects
CJF_fnc_medicDroneRemove = {
	params ["_id"];
	// get our vehicle and pad object
	_drone = [CJF_medicDrone_drones, _id] call CBA_fnc_hashGet;
	// Get our objects we want to remove
	_veh = _drone select 1;
	_pad = _drone select 2;
	
	// If drone is dead just delete it else BE FREE MY DRONE!
	if (!alive _veh) then {
		deleteVehicle _veh; deleteVehicle _pad;
	} else {
		_randomPos = [[[position _veh, 100]],[]] call BIS_fnc_randomPos;
		_veh move _randomPos;
		[{deleteVehicle (_this select 0); deleteVehicle (_this select 1);}, [_veh, _pad], 15] call CBA_fnc_waitAndExecute;
	};
	
	// Remove drone from list of active drones
	[CJF_medicDrone_drones, _id] call CBA_fnc_hashRem;
};

// On each use of drone healing
CJF_fnc_medicDroneUsedLogic = {
	params ["_id"];
	// Get our drone from the hash
	_drone = [CJF_medicDrone_drones, _id] call CBA_fnc_hashGet;
	// Remove one use from drone
	_drone set [0, (_drone select 0) - 1];
	// Has it run out of uses?
	if ((_drone select 0) <= 0) then {
		// fly away and remove action plus objects
		(_drone select 1) call CJF_fnc_medicDroneRemoveActions;
		(_drone select 1) call CJF_fnc_medicDroneRemove;
	};
};

// Event handlers
["CJF_eh_medicDroneRequest", {(_this) spawn CJF_fnc_medicDroneSpawn}] call CBA_fnc_addEventHandler;
["CJF_eh_medicDroneUsedHeal", {(_this) spawn CJF_fnc_medicDroneUsedLogic}] call CBA_fnc_addEventHandler;

// End of file, return true for success
true
