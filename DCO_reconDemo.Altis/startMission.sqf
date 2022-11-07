// Get a suitable position to recon from
private _placeToScout = getMarkerPos ["marker_0", true];
private _destination = _placeToScout call compile preprocessFileLineNumbers "getMountains.sqf";
private _reconResults = [];
getCoveredPath = compile preprocessFileLineNumbers "fn_getCoveredPath.sqf";

(leader reconGroup) addEventHandler ["Suppressed", {
	params ["_unit", "_distance", "_shooter"];
	[_unit, _distance, _shooter] spawn {
		for "_i" from count waypoints reconGroup - 1 to 0 step -1 do
		{
			deleteWaypoint [reconGroup, _i];
		};
		reconGroup setCombatMode "COMBAT";
		(selectRandom (units reconGroup)) commandSuppressiveFire _shooter;
		systemChat "Suppressing target";
		sleep 10;
		systemChat "Fire returned, moving to exfil";
		[reconGroup, (getPosATL (leader reconGroup)), getMarkerPos "marker_2", 6] call getCoveredPath;
	};
}];

if (_destination # 2 < 0) then {_destination = [_destination # 0, _destination # 1, 0]};
systemChat format ["Selected destination %1", _destination];

// Start forming a path to destination
private _directionFromTarget = _placeToScout getDir _destination; // Direction from target to recon spot
private _destinationApproachStart = _destination getPos [300, _directionFromTarget]; // The place from where the group will start to move to the recon spot

// TODO: improve the approach
private _startApproach = _destinationApproachStart getPos [300, _directionFromTarget - 45]; // The place the group will move to the approach


[reconGroup, (getPosATL (leader reconGroup)), _startApproach, 4] call getCoveredPath;
[reconGroup, _startApproach, _destinationApproachStart, 4] call getCoveredPath;
[reconGroup, _destinationApproachStart, _destination, 4, true] call getCoveredPath;

private _nextWaypoint = reconGroup addWaypoint [_destination, 10];
_nextWaypoint setWaypointFormation "COLUMN";
_nextWaypoint setWaypointCombatMode "GREEN"; // Return fire-disengage
_nextWaypoint setWaypointBehaviour "STEALTH";
_nextWaypoint setWaypointSpeed "LIMITED";

systemChat format ["Moving to %1 through %2", mapGridPosition _destination, mapGridPosition _startApproach];

waitUntil {sleep 1; ((leader reconGroup) distance _destination) < 10};

// The maximum distance that the group can move towards the target if they can't see it
private _maxDistanceToMove = ((leader reconGroup) distance _placeToScout) / 6;

private _checkVisibilityFunction =  {
	params ["_placeToScout"];
	([(leader reconGroup), "VIEW", (nearestBuilding _placeToScout)] checkVisibility [eyePos (leader reconGroup), [_placeToScout # 0, _placeToScout # 1, (AGLtoASL _placeToScout # 2) + 15]]) > 0.5;
	};

private _reconFunction = {
	params ["_placeToScout"];
	systemChat "Target found, conducting recon";
	(units reconGroup) commandWatch _placeToScout;
	sleep 15;
	(units reconGroup) commandWatch objNull;
	_reconResults = (leader reconGroup) targetsQuery [objNull, east, "", _placeToScout, 60];
	systemChat "Recon complete. Moving to exfil";
	[reconGroup, (getPosATL (leader reconGroup)), getMarkerPos "marker_2", 6, true] call getCoveredPath;
	_reconResults
};

private _moveTowards = {
	params ["_maxDistanceToMove", "_directionFromTarget", "_placeToScout"];
	private _newPosition = selectBestPlaces [(leader reconGroup) getPos [_maxDistanceToMove, _directionFromTarget - 180], 50, "forest + 4*trees - 10*deadBody", 5, 5];
	private _waypoint = [((_newPosition # 0) # 0) # 0, ((_newPosition # 0) # 0) # 1, 0];
	systemChat format ["Unable to see target. Moving %1 meters to %2 to get a better view", (leader reconGroup) distance _waypoint, mapGridPosition _waypoint];
	
	(units reconGroup) glanceAt _placeToScout;
	fourthWaypoint = reconGroup addWaypoint [_waypoint, 0];
	fourthWaypoint setWaypointFormation "LINE";
	fourthWaypoint setWaypointCombatMode "GREEN"; // Return fire-disengage
	fourthWaypoint setWaypointBehaviour "STEALTH";
	fourthWaypoint setWaypointSpeed "LIMITED";
	DCO_movingComplete = false;
	reconGroup addEventHandler ["WaypointComplete", {
		params ["_group", "_waypointIndex"];
		if (_waypointIndex == fourthWaypoint # 1) then {
			DCO_movingComplete = true;
		};
	}];
	waitUntil {DCO_movingComplete};
	DCO_movingComplete = nil;
	(units reconGroup) glanceAt objNull;
	true
};

if !([_placeToScout] call _checkVisibilityFunction) then {
	private _moving = [_maxDistanceToMove, _directionFromTarget, _placeToScout] spawn _moveTowards;
	
	//[reconGroup, (getPosATL (leader reconGroup)), _waypoint, 6, true] call _getCoveredPath;
	waitUntil {scriptDone _moving};
	systemChat "Moving complete";

	if !([_placeToScout] call _checkVisibilityFunction) then {
		_moving = [_maxDistanceToMove, _directionFromTarget, _placeToScout] spawn _moveTowards;
		waitUntil {scriptDone _moving};
		systemChat "Moving complete";
		if !([_placeToScout] call _checkVisibilityFunction) then {
			systemChat "Couldn't find a position to recon from. Aborting mission, moving to exfil";
			[reconGroup, (getPosATL (leader reconGroup)), getMarkerPos "marker_2", 6, true] call getCoveredPath;
			_reconResults = (leader reconGroup) targetsQuery [objNull, east, "", _placeToScout, 60];
		} else {
			systemChat "Target seen";
			_reconResults = [_placeToScout] call _reconFunction;
		};
	} else {
		systemChat "Target seen";
		_reconResults = [_placeToScout] call _reconFunction;
	};
} else {
	systemChat "Target seen";
	_reconResults = [_placeToScout] call _reconFunction;
};

waitUntil {((leader reconGroup) distance getMarkerPos "marker_2") < 20};
systemChat "Mission complete";
hint str _reconResults;
