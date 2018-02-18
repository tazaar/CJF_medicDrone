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
		class CJF_medicDroneInit {
			medicDrone = "call compile preprocessFileLineNumbers 'cjf/XEH_preInit.sqf'";
		};
	};
    (end)

Author: 
	Popinjay John 2018-02-18

---------------------------------------------------------------------------- */

[
	"CJF_medicDrone_cooldown",
	"SLIDER",
	["Medic drone cooldown", "Cooldown in addition to loiter time"],
	"CJF Medic drone",
	[0, 3600, 600, 0],
	1
] call CBA_Settings_fnc_init;

[
	"CJF_medicDrone_maxLoiter",
	"SLIDER",
	["Medic drone loiter", "Time from spawn until despawn"],
	"CJF Medic drone",
	[20, 900, 120, 0],
	1
] call CBA_Settings_fnc_init;

[
	"CJF_medicDrone_maxUses",
	"SLIDER",
	["Medic drone useages", "How many times can heal be used"],
	"CJF Medic drone",
	[1, 100, 2, 0],
	1
] call CBA_Settings_fnc_init;

[
	"CJF_medicDrone_actionStyle",
	"LIST",
	["Action style", "Chose where to be able to call drone from, actual healing will always be available from both"],
	"CJF Medic drone",
	[["both", "vanilla", "ace"], ["Both", "Vanilla", "ACE 3"], 0],
	2,
	{
		if (hasInterface) then {
			if (CJF_medicDrone_isCallable) then {
				CJF_fnc_medicDroneRemoveActions;
				CJF_fnc_medicDroneRegisterActions;
			};
		};
	}
] call CBA_Settings_fnc_init;

[
	"CJF_medicDrone_maxOnline",
	"SLIDER",
	["Players online restriction", "If more players than this setting is online, disable medic drone"],
	"CJF Medic drone",
	[1, 100, 5, 0],
	1
] call CBA_Settings_fnc_init;

// End of file, return true for success
true
