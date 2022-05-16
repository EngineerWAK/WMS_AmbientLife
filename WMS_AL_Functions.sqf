/**
* WMS_AL_functions.sqf
*
* TNA-Community
* https://discord.gg/Zs23URtjwF
* © 2022 {|||TNA|||}WAKeupneo
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License. 
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/.
* Do Not Re-Upload
*/
/*
	WMS Ambient Life (civilian by default) should provide some roaming NPC driving around the map and later on probably flying.
	Mostly build to fill empty map running with DFO standalone, would be useless with WMS_InfantryProgram since it use it's own roaming system.
	You can obviously use armed vehicles and change the faction to get hostile roaming units.
	
	// Start Ambient Life from initServer.sqf
	if (true)then {execVM "WMS_AL_Functions.sqf"};
*/

WMS_AL_Version		= "v0.15_2022MAY16";
WMS_AmbientLife		= true;
WMS_AL_Standalone	= false;
WMS_AL_LOGs			= false;
WMS_AL_IncludeLoc	= true;
WMS_AL_StripOffUnit = false;
WMS_AL_LockVehicles = false;
WMS_AL_Faction		= CIVILIAN;
WMS_AL_VHLmax		= 35;
WMS_AL_UnitMax		= 10;
WMS_AL_Skills		= [0.8, 0.7, 0.2, 0.3, 0.3, 0.6, 0, 0.5, 0.5]; //"spotDistance","spotTime","aimingAccuracy","aimingShake","aimingSpeed","reloadSpeed","courage","commanding","general"
WMS_AL_Units		= [//array of classnames
						"C_man_p_beggar_F","C_man_1","C_Man_casual_1_F","C_Man_casual_2_F","C_Man_casual_3_F","C_Man_casual_4_F","C_Man_casual_5_F","C_Man_casual_6_F","C_man_polo_1_F","C_man_polo_2_F","C_man_polo_3_F","C_man_polo_4_F","C_man_polo_5_F","C_man_polo_6_F",
						"C_Man_ConstructionWorker_01_Black_F","C_Man_ConstructionWorker_01_Blue_F","C_Man_ConstructionWorker_01_Red_F","C_Man_ConstructionWorker_01_Vrana_F","C_man_p_fugitive_F","C_man_p_shorts_1_F","C_man_hunter_1_F","C_Man_Paramedic_01_F","C_Man_UtilityWorker_01_F"
					]; 
WMS_AL_Vehicles		= [[ //array of arrays or classnames //[[AIR],[GROUND],[SEA]]
						"C_Heli_Light_01_civil_F","C_IDAP_Heli_Transport_02_F","C_Heli_light_01_digital_F","C_Heli_light_01_shadow_F" //17% chance to spawn
					],[
						"C_Van_01_fuel_F","C_Hatchback_01_F","C_Hatchback_01_sport_F","C_Offroad_02_unarmed_F","C_Truck_02_transport_F","C_Truck_02_covered_F","C_Offroad_01_F","C_Offroad_01_comms_F","C_Offroad_01_repair_F","C_Quadbike_01_F","C_SUV_01_F","C_Tractor_01_F","C_Van_01_transport_F","C_Van_01_box_F","C_Van_02_medevac_F","C_Van_02_transport_F"
					],[
						"C_Boat_Civil_01_F","C_Boat_Civil_01_police_F","C_Boat_Civil_01_rescue_F","C_Rubberboat","C_Boat_Transport_02_F","C_Scooter_Transport_01_F" //not used yet
					]];

WMS_AL_AceIsRunning = true; //Automatic
WMS_AL_LastUsedPos	= [0,0,0]; //Dynamic
WMS_AL_Roads		= []; //array of roads //Dynamic //pushBack //You can put yours if you want but the system will pushback roads here
WMS_AL_Running		= [[],[]]; //array of arrays of data [[VEHICLES],[INFANTRY]] //[HexaID,time,group,vehicle]

///////////////////////////////////////
if (WMS_AL_Standalone) then {
		WMS_exileFireAndForget = false;
	WMS_AMS_MaxGrad 	= 0.15;
		WMS_exileToastMsg 	= false; //Exile Mod Notifications
	WMS_Pos_Locals 		= []; //AutoScan
	WMS_Pos_Villages	= []; //AutoScan
	WMS_Pos_Cities 		= []; //AutoScan
	WMS_Pos_Capitals 	= []; //AutoScan
		WMS_Pos_Forests 	= []; //DIY, if no position, back to random _pos
		WMS_Pos_Military 	= []; //DIY, if no position, back to random _pos
		WMS_Pos_Factory 	= []; //DIY, if no position, back to random _pos
		WMS_Pos_Custom	 	= []; //DIY, if no position, back to random _pos
};
///////////////////////////////////////
WMS_fnc_AL_ManagementLoop = {
	if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_ManagementLoop time %1', time]};
	if (WMS_AL_Standalone) then {
		[]call WMS_fnc_AL_CollectPos;
	};
	uisleep 15;
	[]call WMS_fnc_AL_FindRoad;
	uisleep 5;
	for "_i" from 1 to WMS_AL_VHLmax do {
		[] call WMS_fnc_AL_createVHL;
		uisleep 0.5;
	};
	for "_i" from 1 to WMS_AL_UnitMax do {
		[] call WMS_fnc_AL_createUnits;
		uisleep 0.5;
	};
	uisleep 120;
	while {WMS_AmbientLife} do {
		if (true) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_ManagementLoop time %1 server FPS %2, players %3', time, diag_fps, count allPlayers]};
		//respawn missing vehicles, ONE per loop
		if (count (WMS_AL_Running select 0) < WMS_AL_VHLmax) then {
			if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_ManagementLoop spawning a new vehicle %1', time]};
			[] call WMS_fnc_AL_createVHL;
		};
		//respawn missing dudes, ONE per loop
		if (count (WMS_AL_Running select 1) < WMS_AL_UnitMax) then {
			if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_ManagementLoop spawning a new little dude %1', time]};
			[] call WMS_fnc_AL_createUnits;
		};
		{
			//destroying stuck vehicles
			if (speed (_x select 3) < 5) then {
				_lastPos = _x select 3 getVariable ["WMS_AL_LastPos", [0,0,0]];
				if ((position (_x select 3)) distance2D _lastPos < 50) then {
					if (({isPlayer _x} count crew (_x select 3)) == 0) then {
						if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_ManagementLoop %1 Is stuck ! bye bye', _x]};
						{moveOut _x; _x setDamage 1} forEach crew (_x select 3);
						(_x select 3) setDamage 1;
					};
				}else {(_x select 3) setVariable ["WMS_AL_LastPos", position (_x select 3)]};
			};
			uisleep 0.2;
		}forEach (WMS_AL_Running select 0);
		uisleep 120;
	};
};
WMS_fnc_AL_CollectPos = { //at server launch
	if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_CollectPos time %1', time]};
	private _worldCenter 	= [worldsize/2,worldsize/2,0]; 
	private _worldDiameter 	= ((worldsize/2)*1.413);
	if (WMS_AL_LOGs) then {Diag_log '|WAK|TNA|WMS|[AL] collecting LOCALS positions'};
	{WMS_Pos_Locals pushback getPos _x}forEach (nearestLocations [_worldCenter, ["nameLocal"],_worldDiameter]);
	if (WMS_AL_LOGs) then {Diag_log '|WAK|TNA|WMS|[AL] collecting VILLAGES positions'};
	{WMS_Pos_Villages pushback getPos _x}forEach (nearestLocations [_worldCenter, ["nameVillage"],_worldDiameter]);
	if (WMS_AL_LOGs) then {Diag_log '|WAK|TNA|WMS|[AL] collecting CITIES positions'};
	{WMS_Pos_Cities pushback getPos _x}forEach (nearestLocations [_worldCenter, ["nameCity"],_worldDiameter]);
	if (WMS_AL_LOGs) then {Diag_log '|WAK|TNA|WMS|[AL] collecting CAPITALS positions'};
	{WMS_Pos_Capitals pushback getPos _x}forEach (nearestLocations [_worldCenter, ["nameCityCapital"],_worldDiameter]);
};

WMS_fnc_AL_FindRoad = { //at server launch
	if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_FindRoad time %1', time]};
	private _arrayOfPos = WMS_Pos_Villages+WMS_Pos_Cities+WMS_Pos_Capitals;
	if (count _arrayOfPos == 0) exitWith {if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_FindRoad _arrayOfPos IS EMPTY %1', time]};};
	if (WMS_AL_IncludeLoc) then {_arrayOfPos+WMS_Pos_Locals}; 
	{
		_roads = _x nearRoads 150;
		if (count _roads != 0) then {
			_road = selectRandom _roads;
			WMS_AL_Roads pushBack _road;
		}else{
			if (WMS_AL_LOGs) then {Diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_FindRoad no road around %1', _x]};
		};
	}forEach _arrayOfPos;
	if (WMS_AL_LOGs) then {Diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_FindRoad %1 roads found', (count WMS_AL_Roads)]};
};
WMS_fnc_AL_generateHexaID = {	//will be used to find the mission data in arrays
	private _hexaBase = [0,1,2,3,4,5,6,7,8,9,"a","b","c","e","e","f"];
	private _hexaArray = [];
	for "_i" from 1 to 8 do {
		_hexaArray pushBack	(selectRandom _hexaBase);
	};
	private _MissionHexaID = format ["%1%2%3%4%5%6%7%8",(_hexaArray select 0),(_hexaArray select 1),(_hexaArray select 2),(_hexaArray select 3),(_hexaArray select 4),(_hexaArray select 5),(_hexaArray select 6),(_hexaArray select 7)];
	if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_generateHexaID _MissionHexaID %1', _MissionHexaID]};
	_MissionHexaID
};
WMS_fnc_AL_createVHL = {
	if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_createVHL _this %1', _this]};
	params [
		["_pos", []],
		["_vhl", selectRandom (WMS_AL_Vehicles select (selectRandom [1,1,0,1,1,1]))]
	];
	private _dir = Random 359;
	private _waypoints = [];
	private _hexaID = []call WMS_fnc_AL_generateHexaID;
	if(count _pos == 0) then {
		_road = selectRandom WMS_AL_Roads;
		_pos = position _road;
		if (_pos distance2D WMS_AL_LastUsedPos < 20) then {
			_pos = [_pos, 25, 250, 20, 0, 0, 0, [], [([] call BIS_fnc_randomPos),[]]] call BIS_fnc_FindSafePos;
		};
		_dir = direction _road;
		WMS_AL_LastUsedPos = _pos;
	};
	private _grp = createGroup WMS_AL_Faction;
	_waypoints = [_hexaID,_pos,_grp,false,false] call WMS_fnc_AL_Patrol; //[_hexaID, pos, group, boulean infantry, boulean combat]
	//2 possibilities, create the vehicle ready to go with crew or create a vehicel and then the crew
	//lets do the easy one first:
	private _vehicleData = [_pos, _dir, _vhl, _grp] call BIS_fnc_spawnVehicle; //[createdVehicle, crew, group]
	private _vhlObject = (_vehicleData select 0);
	if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_createVHL _vehicleData %1', _vehicleData]};
	if (WMS_AL_LockVehicles) then {_vhlObject lock 3};
	clearMagazineCargoGlobal _vhlObject; 
	clearWeaponCargoGlobal _vhlObject; 
	clearItemCargoGlobal _vhlObject; 
	clearBackpackCargoGlobal _vhlObject;
	_vhlObject setVariable ["WMS_AL_lastPos", position _vhlObject];
	_vhlObject setVariable ["WMS_AL_hexaID", _hexaID];
	[(_vehicleData select 1)] call WMS_fnc_AL_setUnits;
	_vhlObject setVariable ["WMS_AL_RealFuckingSide",WMS_AL_Faction];
	_vhlObject addEventHandler ["Killed", " 
		[(_this select 0),(_this select 1),(_this select 2)] call WMS_fnc_AL_VhlEH;
		"];//params ["_unit", "_killer", "_instigator", "_useEffects"];
	(WMS_AL_Running select 0) pushBack [_hexaID,time,_grp,_vhlObject,_waypoints]; //[HexaID,time,group,vehicle,[waypoints]]
};

WMS_fnc_AL_createUnits = {
	if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_createUnits _this %1', _this]};
	params [
		["_pos", []],
		["_unit", selectRandom WMS_AL_Units]
	];
	private _dir = Random 359;
	private _waypoints = [];
	private _hexaID = []call WMS_fnc_AL_generateHexaID;
	if(count _pos == 0) then {
		_road = selectRandom WMS_AL_Roads;
		_pos = position _road;
		if (_pos distance2D WMS_AL_LastUsedPos < 20) then {
			_pos = [_pos, 10, 250, 5, 0, 0, 0, [], [([] call BIS_fnc_randomPos),[]]] call BIS_fnc_FindSafePos;
		};
		_dir = direction _road;
		WMS_AL_LastUsedPos = _pos;
	};
	private _grp = createGroup WMS_AL_Faction;
	_waypoints = [_hexaID,_pos,_grp,true,false] call WMS_fnc_AL_Patrol; //[_hexaID, pos, group, boulean infantry, boulean combat]
	_unitObject = _grp createUnit [_unit, _pos, [], 15, "FORM"];
	_unitObject setVariable ["WMS_AL_hexaID", _hexaID];
	[[_unitObject]] call WMS_fnc_AL_setUnits;
	(WMS_AL_Running select 1) pushBack [_hexaID,time,_grp,_unitObject,_waypoints]; //[HexaID,time,group,vehicle,[waypoints]]
};

WMS_fnc_AL_setUnits = {
	if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_setUnits _this %1', _this]};
	private [];
	params [
		"_units",
		["_options", []],
		["_skills",WMS_AL_Skills]
	];
	{
		//setSkill
		_x setSkill ["spotDistance", 	(_skills select 0)];
		_x setSkill ["spotTime", 		(_skills select 1)];
		_x setSkill ["aimingAccuracy", 	(_skills select 2)];
		_x setSkill ["aimingShake", 	(_skills select 3)];
		_x setSkill ["aimingSpeed", 	(_skills select 4)];
		_x setSkill ["reloadSpeed", 	(_skills select 5)];
		_x setSkill ["courage", 		(_skills select 6)];
		_x setSkill ["commanding", 		(_skills select 7)];
		_x setSkill ["general", 		(_skills select 8)];
		_x setVariable ["WMS_DFO_options",_options];
		_x allowFleeing 0;
		_x setVariable ["WMS_AL_RealFuckingSide",WMS_AL_Faction];
		_x addEventHandler ["Killed", " 
		[(_this select 0),(_this select 1),(_this select 2)] call WMS_fnc_AL_UnitEH;
		"];//params ["_unit", "_killer", "_instigator", "_useEffects"];
	}forEach _units
};

WMS_fnc_AL_UnitEH = {
	if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_UnitEH _this %1', _this]};
	params [
		"_killed",
		"_killer", //the registered _playerObject for the mission is the pilot who launched the mission, if the pilot die and come back, he doesnt match the registered anymore
		"_instigator"
	];
	if (isPlayer _instigator) then {_killer = _instigator};
	if(isPlayer _killer && {((side _killer) getfriend (_killed getVariable ["WMS_AL_RealFuckingSide",WMS_AL_Faction])) > 0.5}) then {
		[_killer] call WMS_fnc_AL_PunishPunks;
	};
	private _hexaID = _killed getVariable ["WMS_AL_hexaID", "zzzzzzzz"];
	if (WMS_AL_StripOffUnit) then {
		_killed removeWeapon (primaryWeapon _killed);
		_killed removeWeapon (secondaryWeapon _killed); //launcher
		//removeAllItems _killed;
		removeAllWeapons _killed;
		removeBackpackGlobal _killed;
		removeVest _killed;
		//moveOut _killed;
	};
	deleteGroup (group _killed);
	//if the unit die, remove it from the manager
	private _result = []; 
	{ 
		_found = (_x select 0) find _hexaID;
		_result pushback _found;
	}forEach (WMS_AL_Running select 1);
	private _RefIndex = _result find 0;
	//{deleteWaypoint _x}forEach (((WMS_AL_Running select 1) select _RefIndex) select 4); //units use CBA patrol which manage the waypoints itself
	(WMS_AL_Running select 1) deleteAt _RefIndex;
};
WMS_fnc_AL_VhlEH = {
	if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_VhlEH _this %1', _this]};
	params [
		"_killed",
		"_killer", //the registered _playerObject for the mission is the pilot who launched the mission, if the pilot die and come back, he doesnt match the registered anymore
		"_instigator"
	];
	if (isPlayer _instigator) then {_killer = _instigator};
	private _hexaID = _killed getVariable ["WMS_AL_hexaID", "zzzzzzzz"];
	if(isPlayer _killer && {((side _killer) getfriend (_killed getVariable ["WMS_AL_RealFuckingSide",WMS_AL_Faction])) > 0.5}) then {
		[_killer] call WMS_fnc_AL_PunishPunks;
	};
	{
		moveOut _x; 
		_x setDamage 1;
		if (WMS_AL_StripOffUnit) then {
			_x removeWeapon (primaryWeapon _x);
			_x removeWeapon (secondaryWeapon _x); //launcher
			//removeAllItems _x;
			removeAllWeapons _x;
			removeBackpackGlobal _x;
			removeVest _x;
		};
	} forEach units (group _killed);
	deleteGroup (group _killed);
	//if the unit die, remove it from the manager
	private _result = []; 
	{ 
		_found = (_x select 0) find _hexaID;
		_result pushback _found;
	}forEach (WMS_AL_Running select 0);
	private _RefIndex = _result find 0;
	{deleteWaypoint _x}forEach (((WMS_AL_Running select 0) select _RefIndex) select 4);
	[_killed] spawn {uisleep 5; deleteVehicle (_this select 0)};
	(WMS_AL_Running select 0) deleteAt _RefIndex;
};

WMS_fnc_AL_Patrol = {
	if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_Patrol _this %1', _this]};
	params [
		"_hexaID",
		"_pos", 
		"_grp", 
		["_infantry", true],
		["_combat", false]
	];
	private _waypoints = [];
	//create Waypoints, lets say 4 of them, in random cities for Vehicles, around for dudes
	if (_infantry) then {
		if (_combat) then {
			[_grp, _pos, 150, 4, "MOVE", "AWARE", "RED", "NORMAL", "COLUMN", "", [1,2,3]] call CBA_fnc_taskPatrol;
		} else {
			[_grp, _pos, 150, 4, "MOVE", "CARELESS", "BLUE", "LIMITED", "COLUMN", "", [1,2,3]] call CBA_fnc_taskPatrol;
		};
	} else {
		private _wpt0 = _grp addWaypoint [_pos, 50, 0, format["WPT0_%1",round time]];
		_waypoints pushBack _wpt0;
		_wpt0 setWaypointType "MOVE";
		private _wpt1 = _grp addWaypoint [getPos (selectRandom WMS_AL_Roads), 150, 1, format["WPT1_%1",round time]];
		_wpt1 setWaypointType "MOVE";
		_waypoints pushBack _wpt1;
		private _wpt2 = _grp addWaypoint [getPos (selectRandom WMS_AL_Roads), 150, 2, format["WPT2_%1",round time]];
		_wpt2 setWaypointType "MOVE";
		_waypoints pushBack _wpt2;
		private _wpt3 = [];
		private _lastPos = getPos (selectRandom WMS_AL_Roads);
		if (_lastPos distance2D (getWPPos _wpt2) < 150 || _lastPos distance2D (getWPPos _wpt0) < 50) then {
			private _findPos = true;
			private _cycles = 100;
			while {_findPos} do {
				_lastPos = getPos (selectRandom WMS_AL_Roads);
				if (_lastPos distance2D (getWPPos _wpt2) > 50 && _lastPos distance2D (getWPPos _wpt0) > 50) then {
					_findPos = false;
					_wpt3 = _grp addWaypoint [_lastPos, 150, 3, format["WPT3_%1",round time]];
				};
				_cycles = _cycles-1;
				if (_cycles < 1) then {
					_findPos = false;
					_wpt3 = _grp addWaypoint [_lastPos, 150, 3, format["WPT3_%1",round time]];
				};
			};
		}else {_wpt3 = _grp addWaypoint [_lastPos, 150, 3, format["WPT3_%1",round time]];};
		_waypoints pushBack _wpt3;
		_wpt3 setWaypointType "CYCLE";
		{
			if (_combat) then {
				_x setWaypointCombatMode "YELLOW";
				_x setWaypointBehaviour "AWARE";
				_x setWaypointSpeed "NORMAL";
			} else {
				_x setWaypointCombatMode "BLUE";
				_x setWaypointBehaviour "CARELESS";
				_x setWaypointSpeed "LIMITED";
			};
		}forEach _waypoints;
	};
	_waypoints
};
WMS_fnc_AL_PunishPunks = { //will be use to remind to those getting in the mission zone that it's not their mission, ACE broken legs and things like that
	if (WMS_AL_LOGs) then {diag_log format ['|WAK|TNA|WMS|WMS_fnc_AL_PunishPunks _this %1', _this]};
	params [
		"_playerObject",
		["_maxDamage",0.4],
		["_part", selectRandom ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"]], //["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"] ACE
		["_projectiles", selectRandom ["stab","bullet","grenade","explosive","shell","vehiclecrash","backblast","falling"]] //["stab","bullet","grenade","explosive","shell","vehiclecrash","collision","backblast","punch","falling","ropeburn","fire"]
		];

	if (WMS_AL_AceIsRunning) then {
		if (isPlayer _playerObject) then {
			[_playerObject, _maxDamage, _part, _projectiles, _playerObject] remoteExecCall ["ace_medical_fnc_addDamageToUnit",owner _playerObject];
		} else {
			[_playerObject, 0.3, _part, _projectiles, _playerObject] call ace_medical_fnc_addDamageToUnit;
		};
	} else {
		//Bohemia:
		/*_parts = [
			"face_hub", //Unit dies at damage equal to or above 1
			"neck", //Unit dies at damage equal to or above 1
			"head", //Unit dies at damage equal to or above 1
			"pelvis", //Unit dies at damage equal to or above 1
			"spine1", //Unit dies at damage equal to or above 1
			"spine2", //Unit dies at damage equal to or above 1
			"spine3", //Unit dies at damage equal to or above 1
			"body", //Unit dies at damage equal to or above 1
			"arms", //Unit doesn't die with damage to this part
			"hands", //Unit doesn't die with damage to this part
			"legs" //Unit doesn't die with damage to this part 
		];*/
		//_playerObject setHit [selectRandom _parts,random 0.25,true,_playerObject];
		private _dmg = damage _playerObject;
		_playerObject setDamage _dmg+(random _maxDamage); //it's not sexy but it should do the job for now
	};
};

///////////////////////////
{if ("Advanced Combat Environment" in (_x select 0))then {WMS_AL_AceIsRunning = true;}}forEach getLoadedModsInfo;
if (WMS_AmbientLife) then {[]spawn WMS_fnc_AL_ManagementLoop};