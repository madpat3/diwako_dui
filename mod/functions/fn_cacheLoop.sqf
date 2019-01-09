#include "../script_component.hpp"

[diwako_dui_fnc_cacheLoop,[],0.5] call CBA_fnc_waitAndExecute;

if !(diwako_dui_enable_compass || diwako_dui_namelist) exitWith {
    {
        ctrlDelete ctrlParentControlsGroup (diwako_dui_namebox_lists deleteAt 0);
    } forEach diwako_dui_namebox_lists;
    ("diwako_dui_namebox" call BIS_fnc_rscLayer) cutRsc ["diwako_dui_RscNameBox","PLAIN", 0, true];
};

private _player = [] call CBA_fnc_currentUnit;
diwako_dui_group = units group _player;
private _nums = toArray "0123456789ABCDEF"; //for converting hex nibbles to base 10 equivalents

private _getColorFromHex = {
    params ["_hex"];
    _hex = toArray _hex;
    _hex deleteAt 0; //remove the '#' at the beginning

    private _r = (_nums find (_hex select 0)) * 16 + (_nums find (_hex select 1));
    private _g = (_nums find (_hex select 2)) * 16 + (_nums find (_hex select 3));
    private _b = (_nums find (_hex select 4)) * 16 + (_nums find (_hex select 5));

    [(_r/255),(_g/255),(_b/255)];
};

{
    _x setVariable ["diwako_dui_compass_icon", [_x, true] call diwako_dui_fnc_getIcon];
    _x setVariable ["diwako_dui_icon", [_x] call diwako_dui_fnc_getIcon];
    private _color = assignedTeam _x call {
        if (_this == "RED") exitwith {diwako_dui_colors # 1};
        if (_this == "GREEN") exitwith {diwako_dui_colors # 2};
        if (_this == "BLUE") exitwith {diwako_dui_colors # 3};
        if (_this == "YELLOW") exitwith {diwako_dui_colors # 4};
        diwako_dui_colors # 0
    }; 
    _x setVariable ["diwako_dui_color", _color];
    _x setVariable ["diwako_dui_compass_color", ([_color, diwako_dui_colors # 5] select (_player == (_x getVariable ["diwako_dui_buddy", objNull]))) call _getColorFromHex];
} forEach diwako_dui_group;

if (diwako_dui_enable_compass && {diwako_dui_compass_pfHandle <= -1}) then {
    ("diwako_dui_compass" call BIS_fnc_rscLayer) cutRsc ["diwako_dui_RscCompass","PLAIN", 0, true];
    [] call diwako_dui_fnc_compass;
};

// built name list from here
private _display = uiNamespace getVariable ["diwako_dui_RscNameBox", displayNull];
if (isNull _display) exitWith {
    if (diwako_dui_namelist) then {
        ("diwako_dui_namebox" call BIS_fnc_rscLayer) cutRsc ["diwako_dui_RscNameBox","PLAIN", 0, true];
    };
};

private _grpCtrl = _display displayCtrl IDC_NAMEBOX_CTRLGRP;
private _lists = diwako_dui_namebox_lists;
if !(diwako_dui_namelist) exitWith {
    for "_i" from (count _lists) -1 to 0 step -1 do {
        ctrlDelete ctrlParentControlsGroup (_lists deleteAt _i);
    };
    ("diwako_dui_namebox" call BIS_fnc_rscLayer) cutText ["","PLAIN"];
};

if !([_player] call diwako_dui_fnc_canHudBeShown) exitWith {
    _grpCtrl ctrlShow false;
};

if (count diwako_dui_group == 1) exitWith {
    for "_i" from (count _lists) -1 to 0 step -1 do {
        ctrlDelete ctrlParentControlsGroup (_lists deleteAt _i);
    };
};
if !(ctrlShown _grpCtrl) then {
    _grpCtrl ctrlShow true;
};
private _text = "";
private _curList = controlNull;
private _listIndex = 0;
private _selectedUnits = groupSelectedUnits _player;
private _textSize = diwako_dui_namelist_size;
private _listWidth = 215 * pixelW;
private _listHeight = 128 * pixelH;
private _ctrlPosList = [0, 0, _listWidth*10, _listHeight];
{
    if (_forEachIndex mod round(5/_textSize) == 0) then {
        if !(isNull _curList) then {
            _curList ctrlSetStructuredText parseText _text;
            _curList ctrlSetFont diwako_dui_font;
            _curList ctrlSetPosition _ctrlPosList;
            _curList ctrlCommit 0;
            _text = "";
        };
        if (count _lists >= (_listIndex + 1)) then {
            _curList = _lists # _listIndex;
        } else {
            ctrlPosition _grpCtrl params ["_left", "_top", "_width", "_height"];
            // create group
            private _curGrp = _display ctrlCreate['RscControlsGroupNoScrollbars', -1, _grpCtrl];
            private _ctrlPos = [
                (5 * pixelW) * _listIndex + _listWidth * _listIndex,
                0,
                _listWidth,
                _listHeight
            ];
            _curGrp ctrlSetPosition _ctrlPos;
            _curGrp ctrlCommit 0;

            _curList = _display ctrlCreate ["RscStructuredText", -1, _curGrp];
            _lists pushBack _curList;
            _curList ctrlCommit 0;
        };
        _listIndex = _listIndex + 1;
    };
    private _unit = _x;
    private _selected = ["", ">>"] select (_selectedUnits findIf {_x == _unit} > -1);
    _text = format ["%1<t color='%4' size='%6' shadow='1' shadowColor='#000000' align='left'>%5<img image='%2'valign='bottom'/> %3</t><br/>", _text, _unit getVariable ["diwako_dui_icon", DUI_DEFAULT_ICON], _unit getVariable ["ACE_Name", name _unit], _unit getVariable ["diwako_dui_color","#FFFFFF"],_selected,_textSize];
} forEach diwako_dui_group;

if !(isNull _curList) then {
    _curList ctrlSetStructuredText parseText _text;
    _curList ctrlSetFont diwako_dui_font;
    _curList ctrlSetPosition _ctrlPosList;
    _curList ctrlCommit 0;
};
for "_i" from (count _lists) -1 to _listIndex step -1 do {
    ctrlDelete ctrlParentControlsGroup (_lists deleteAt _i);
};
