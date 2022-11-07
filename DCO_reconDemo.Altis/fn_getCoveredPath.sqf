/*
 * Author: ThomasAngel
 * Divides a path into X amount of steps, with each step being an extra -
 * check for terrain cover
 *
 * Arguments:
 * 0: The group to move <GROUP>
 * 1: The starting position <TODO>
 * 2: The ending position <TODO>
 * 3: Number of steps <SCALAR>
 * 4: Force stealth <BOOLEAN>
 *
 * Return Value:
 * The return value <BOOL>
 *
 * Example:
 * [position, position, 3] call DCO_fnc_getCoveredPath;
 *
 * Public: [Yes/No]
 */

params [
	["_group", grpNull, [grpNull]],
	["_startingPos", [0, 0, 0], [[], objNull]],
	["_endingPos", [0, 0, 0], [[], objNull]],
	["_steps", 1, [0]],
	["_forceStealth", false, [false]]
];

private _totalDistance = _startingPos distance _endingPos;
private _totalDirection = _startingPos getDir _endingPos;
private _stepDistance = _totalDistance / _steps;
if (_stepDistance < 25) then {_stepDistance = 25; _steps = round (_totalDistance / 25)};

private _bestPlaceUnwrap = {
	private _arrayToUnwrap = _this;
	private _return = [[(_arrayToUnwrap # 0) # 0, (_arrayToUnwrap # 0) # 1, 0], _arrayToUnwrap # 1];
	_return
};

private _currentPosition = _startingPos;
for "_i" from 0 to _steps - 1 do {
	private _nextPosSearch = _currentPosition getPos [_stepDistance, _currentPosition getDir _endingPos]; // The position to search the next position from
	private _bestPlace = (selectBestPlaces [_nextPosSearch, _stepDistance, "2*forest + 4*trees - 2*hills - 2*houses - 4*deadBody - coast - 10*waterDepth", _stepDistance - 5, 3] # 0) call _bestPlaceUnwrap;
	private _nextWaypoint = _group addWaypoint [_bestPlace # 0, 10];
	_nextWaypoint setWaypointFormation "COLUMN";
	_nextWaypoint setWaypointCombatMode "GREEN"; // Return fire-disengage
	private _waypointBehaviour = ["STEALTH", "AWARE"] select ((_bestPlace # 1) > 1);
	private _waypointSpeed = ["FULL", "NORMAL"] select ((_bestPlace # 1) > 1);
	_nextWaypoint setWaypointBehaviour _waypointBehaviour;
	_nextWaypoint setWaypointSpeed _waypointSpeed;
	_currentPosition = _bestPlace # 0;
};

// Check if group reached target
if ((_currentPosition distance _endingPos) > 100) then {
 	//[_group, _currentPosition, _endingPos, 2] call compile preprocessFileLineNumbers "fn_getCoveredPath.sqf";
	 private _nextWaypoint = _group addWaypoint [_endingPos, 10];
	_nextWaypoint setWaypointFormation "COLUMN";
	_nextWaypoint setWaypointCombatMode "GREEN"; // Return fire-disengage
};

true
