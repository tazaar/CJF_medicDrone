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
	Popinjay John 2018-03-09

---------------------------------------------------------------------------- */

// CBA hashmap to keep track of all drones
// Key = droneID, value = [0 padID, 1 smokeID, 2 usesLeft, 3 EHkilledID]
CJF_medicDrone_currentDrones = [] call CBA_fnc_hashCreate;
CJF_medicDrone_canPlayersRequestDrone = false;
publicVariable "CJF_medicDrone_canPlayersRequestDrone";

// Land a drone at the players feet with ACE full heal and medical supplies
CJF_eh_medicDrone_onRequestDrone = {
	params ["_pos"];
	
	if (call CJF_fnc_medicDrone_isValidRequestDrone) then {
		// Spawn helipad because arma..
		_pad = "Land_HelipadEmpty_F" createVehicle _pos;
		// Spawn smoke grenade
		_smoke = "SmokeShellOrange" createVehicle _pos;
		// Spawn drone above player
		_veh = createVehicle["B_UAV_06_medical_F", _pos, [], 0, "FLY"]; createVehicleCrew _veh;
		// Disable drone collision with smoke
		_veh disableCollisionWith _smoke;
		
		// Clear cargo of existing items and add our custom ones
		clearItemCargoGlobal _veh;
		_veh addItemCargoGlobal ["ACE_fieldDressing", 6];
		_veh addItemCargoGlobal ["ACE_elasticBandage", 6];
		_veh addItemCargoGlobal ["ACE_quikclot", 6];
		_veh addItemCargoGlobal ["ACE_packingBandage", 6];
		_veh addItemCargoGlobal ["ACE_morphine", 1];
		_veh addItemCargoGlobal ["ACE_tourniquet", 1];
		
		// Events & timers
		// Tell players to add action to drone
		if (isDedicated) then { // Do we need global (player host) or just remote EH
			["CJF_medicDrone_registerDroneAction", [_veh]] call CBA_fnc_remoteEvent;
		} else {
			["CJF_medicDrone_registerDroneAction", [_veh]] call CBA_fnc_globalEvent;
		};
		// Wait loiter time then remove after loiter has expired
		[CJF_fnc_medicDrone_droneDeparting, [_veh], CJF_medicDrone_maxLoiter] call CBA_fnc_waitAndExecute;
		// If drone died, Tell players to remove action
		_ehKilledID = _veh addEventHandler ["killed",{
			if (isDedicated) then { // Do we need global (player host) or just remote EH
				["CJF_medicDrone_removeDroneAction", [_this select 0]] call CBA_fnc_remoteEvent;
			} else {
				["CJF_medicDrone_removeDroneAction", [_this select 0]] call CBA_fnc_globalEvent;
			};
		}];

		// Add drone, pad and actionID to server list of drones
		[CJF_medicDrone_currentDrones, _veh, [_pad, _smoke, CJF_medicDrone_maxUses, _ehKilledID]] call CBA_fnc_hashSet;

		// Tell drone to land
		_veh land "LAND";
	};
};

// Logic to handle heal action serverside
CJF_eh_medicDrone_onUseHeal = {
	params ["_veh"];
	_droneInfo = [CJF_medicDrone_currentDrones, _veh] call CBA_fnc_hashGet;
	// Remove one use from drone
	_droneInfo set [2, (_droneInfo select 2) - 1];
	// Has it run out of uses?
	if ((_droneInfo select 2) <= 0) then {
		// Disable killed EH because we are removing action now
		_veh removeEventHandler ["killed", (_droneInfo select 3)];
		// Tell players to remove action
		if (isDedicated) then { // Do we need global (player host) or just remote clients
			["CJF_medicDrone_removeDroneAction", [_veh]] call CBA_fnc_remoteEvent;
		} else {
			["CJF_medicDrone_removeDroneAction", [_veh]] call CBA_fnc_globalEvent;
		};
	};
};

// TODO; First player counts as two!
CJF_eh_medicDrone_onPlayerConnectedDisconnected = {
	params ["_cameOrLeft", "_jip"];
	// On playerConnected, the player is not actually counted as an player yet..
	// But only for the second person joining, first one to join gets counted correctly
	_fixedPlayers = count ([] call CBA_fnc_players);
	if (_cameOrLeft == "connected") then {
		if (_jip) then {
			_fixedPlayers = _fixedPlayers + 1;
		};
	};
	
	diag_log format ["MedicDrone: Players changed, now online: %1", _fixedPlayers];
	
	if (_fixedPlayers <= CJF_medicDrone_maxOnline) then { // Check if its OK to call drones now?
		if (!CJF_medicDrone_canPlayersRequestDrone) then { // Was it disabled, tell players its OK
			CJF_medicDrone_canPlayersRequestDrone = true;
			publicVariable "CJF_medicDrone_canPlayersRequestDrone";
			// Tell players to update
			if (isDedicated) then { // Do we need global (player host) or just remote clients
				["CJF_medicDrone_canPlayersRequestDroneUpdate"] call CBA_fnc_remoteEvent;
			} else {
				["CJF_medicDrone_canPlayersRequestDroneUpdate"] call CBA_fnc_globalEvent;
			};
		};
	} else { // It is not OK to call drones now
		if (CJF_medicDrone_canPlayersRequestDrone) then { // Was it enabled? tell players to disable
			CJF_medicDrone_canPlayersRequestDrone = false;
			publicVariable "CJF_medicDrone_canPlayersRequestDrone";
			// Tell players to update
			if (isDedicated) then { // Do we need global (player host) or just remote clients
				["CJF_medicDrone_canPlayersRequestDroneUpdate"] call CBA_fnc_remoteEvent;
			} else {
				["CJF_medicDrone_canPlayersRequestDroneUpdate"] call CBA_fnc_globalEvent;
			};
		};
	};
};

// Just to make future improvements easier
CJF_fnc_medicDrone_isValidRequestDrone = {
	true
};

// Remove from active drones and remove physical objects
CJF_fnc_medicDrone_droneRemove = {
	params ["_veh"];
	_droneInfo = [CJF_medicDrone_currentDrones, _veh] call CBA_fnc_hashGet;
	// Delete vehicle and pad
	deleteVehicle _veh;
	deleteVehicle (_droneInfo select 0);
	// Delete from active drones
	[CJF_medicDrone_currentDrones, _veh] call CBA_fnc_hashRem;
	// Tell clients to remove from their list as well
	if (isDedicated) then { // Do we need global (player host) or just remote EH
		["CJF_medicDrone_removeDroneAction", [_veh]] call CBA_fnc_remoteEvent;
	} else {
		["CJF_medicDrone_removeDroneAction", [_veh]] call CBA_fnc_globalEvent;
	};
	// Return true for finished
	true
};

// Depart drone from scene
CJF_fnc_medicDrone_droneDeparting = {
	params ["_veh"];
	_deletionTime = 20;
	
	_randomPos = [[[position _veh, 200]],[]] call BIS_fnc_randomPos;
	_veh move _randomPos;
	[{_this select 0 call CJF_fnc_medicDrone_droneRemove;}, [_veh], _deletionTime] call CBA_fnc_waitAndExecute;
};

// Add event handlers
["CJF_medicDrone_useHeal", {_this spawn CJF_eh_medicDrone_onUseHeal}] call CBA_fnc_addEventHandler;
["CJF_medicDrone_requestDrone", {_this spawn CJF_eh_medicDrone_onRequestDrone}] call CBA_fnc_addEventHandler;

addMissionEventHandler ["PlayerConnected", { ["connected", (_this select 3)] call CJF_eh_medicDrone_onPlayerConnectedDisconnected}];
addMissionEventHandler ["PlayerDisconnected", { ["disconnected", false] call CJF_eh_medicDrone_onPlayerConnectedDisconnected}];

// End of file, return true for success
true
