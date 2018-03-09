/* ----------------------------------------------------------------------------
Function: XEH_preInit

Description:
	Shared variables and CBA settings for medical drone.
	Must be called in an CBA XEH for CBA Settings compatbility.

Parameters:

Returns:
	TRUE when complete

Examples:
    (begin example)
	// CBA Extended event handlers
	class Extended_PreInit_EventHandlers {
		medicDroneMission = call compile preprocessFileLineNumbers "cjf\medicDrone\XEH_preInit.sqf";
	};
    (end)

Author: 
	Popinjay John 2018-03-09

---------------------------------------------------------------------------- */

[
	"CJF_medicDrone_cooldown",
	"SLIDER",
	["Medic drone cooldown", "Cooldown in addition to loiter time"],
	"CJF Medic Drone",
	[0, 3600, 600, 0],
	1
] call CBA_Settings_fnc_init;

[
	"CJF_medicDrone_maxLoiter",
	"SLIDER",
	["Medic drone loiter", "Time from spawn until despawn"],
	"CJF Medic Drone",
	[70, 3600, 300, 0],
	1
] call CBA_Settings_fnc_init;

[
	"CJF_medicDrone_maxUses",
	"SLIDER",
	["Medic drone useages", "How many times can heal be used"],
	"CJF Medic Drone",
	[1, 100, 2, 0],
	1
] call CBA_Settings_fnc_init;

[
	"CJF_medicDrone_actionStyle",
	"LIST",
	["Action style", "Chose where to be able to call drone from, actual healing will always be available from both"],
	"CJF Medic Drone",
	[["both", "vanilla", "ace"], ["Both", "Vanilla", "ACE 3"], 0],
	0,
	{
		if (hasInterface) then {
			call CJF_fnc_medicDrone_removeCalldownActions;
			call CJF_fnc_medicDrone_registerCalldownActions;
		};
	}
] call CBA_Settings_fnc_init;

[
	"CJF_medicDrone_holdTime",
	"SLIDER",
	["Interaction time", "How long must players hold to heal"],
	"CJF Medic Drone",
	[1, 30, 10, 0],
	1
] call CBA_Settings_fnc_init;

[
	"CJF_medicDrone_maxOnline",
	"SLIDER",
	["Players online restriction", "If more players than this setting is online, disable medic drone"],
	"CJF Medic Drone",
	[1, 100, 4, 0],
	1,
	{
		if (isServer) then {
			["init", false] call CJF_eh_medicDrone_onPlayerConnectedDisconnected;
		};
	}
] call CBA_Settings_fnc_init;

[
	"CJF_medicDrone_maxNotifyDistance",
	"SLIDER",
	["Max distance to notify nearby players", "Show a notification to player when drone gets called inside distance"],
	"CJF Medic Drone",
	[15, 500, 100, 0],
	1
] call CBA_Settings_fnc_init;

// End of file, return true for success
true
