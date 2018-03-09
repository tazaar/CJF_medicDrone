# Requirements

Requires both ACE3 and CBA.

# Installation

- Merge Description.ext
- Merge initPlayerLocal.sqf
- Merge initServer.sqf

# Limitations

Drone heal actions and newly joined players
If a player joins after a drone was called, that player will not be able to use the heal from that drone.
Both intended and unintended behaviour as to save a tiny amount of datatrafic as newly joined players should not be able to get to the drone anyways.
Could be fixed by changing a few lines of code if needed.

Script does not check for presence of CBA or ACE3, easily fixed if i could find the script snippets for testing if CBA and ACE3 is installed again..