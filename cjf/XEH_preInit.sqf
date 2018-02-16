/* ----------------------------------------------------------------------------
Function: CJF_fnc_medicDroneLocal

Description:
	Shared variables and functions for medical drone.
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
	Popinjay John 2018-02-14

---------------------------------------------------------------------------- */

[
	"CJF_medicDrone_cooldown",
	"SLIDER",
	["Medic drone cooldown", "Cooldown in addition to loiter time"],
	"Medic drone",
	[0, 3600, 600, 0],
	1
] call CBA_Settings_fnc_init;

[
	"CJF_medicDrone_maxLoiter",
	"SLIDER",
	["Medic drone loiter", "Time from spawn until despawn"],
	"Medic drone",
	[20, 900, 120, 0],
	1
] call CBA_Settings_fnc_init;

[
	"CJF_medicDrone_maxUses",
	"SLIDER",
	["Medic drone useages", "How many times can heal be used"],
	"Medic drone",
	[1, 100, 2, 0],
	1
] call CBA_Settings_fnc_init;

[
	"CJF_medicDrone_ACEonly",
	"CHECKBOX",
	["ACE request only", "Tick to only request drone from ACE self-interact"],
	"Medic drone",
	false
] call CBA_Settings_fnc_init;

// End of file, return true for success
true
