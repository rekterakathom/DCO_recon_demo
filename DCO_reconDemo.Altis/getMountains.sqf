private _placeToRecon = _this;

// Get near mountaintops
private _locations = nearestLocations [_placeToRecon, ["mount"], 1000];
 
// First sort by height (importance)
private _firstSort = [_locations, [], {importance _x}, "DESCEND", {true}] call BIS_fnc_sortBy;
 
// Second sort by visibility
private _secondSort = [_firstSort select [0, 3], [getPosASL player], {[objNull, "FIRE"] checkVisibility [[getPos _x # 0, getPos _x # 1, (getPos _x # 2) + 0.5], [_input0 # 0, _input0 # 1, (_input0 # 2) + 0.5]]}, "DESCEND", {true}] call BIS_fnc_sortBy;
 
// Get best possible position within 25 meters
private _possiblePlaces = selectBestPlaces [getPos (_secondSort # 0), 50, "2*hills + trees + forest", 5, 30];
 
// Remove extra junk from array
private _finalSortArray = [];
{_finalSortArray pushBack _x # 0} forEach _possiblePlaces;
 
// Final sort for actual visibility
_finalSort = [_finalSortArray, [getPosASL player], {[objNull, "VIEW"] checkVisibility [[_x # 0, _x # 1, (getTerrainHeightASL _x) + 0.5], [_input0 # 0, _input0 # 1, (_input0 # 2) + 0.5]]}, "DESCEND", {true}] call BIS_fnc_sortBy;
 
private _finalPos = _finalSort # 0;
 
// _finalPos is position2D so we need to add the height
_finalPos pushBack getTerrainHeightASL _finalPos;
 
_return = [objNull, "FIRE"] checkVisibility [_finalPos, getPosASL player];
//player setPosASL _finalPos;
ASLtoAGL _finalPos;
 