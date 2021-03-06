unit ghmovers;
	{This unit holds constants and functions relating to}
	{movement systems - wheels, hover jets, etc.}
{
	GearHead2, a roguelike mecha CRPG
	Copyright (C) 2005 Joseph Hewitt

	This library is free software; you can redistribute it and/or modify it
	under the terms of the GNU Lesser General Public License as published by
	the Free Software Foundation; either version 2.1 of the License, or (at
	your option) any later version.

	The full text of the LGPL can be found in license.txt.

	This library is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser
	General Public License for more details. 

	You should have received a copy of the GNU Lesser General Public License
	along with this library; if not, write to the Free Software Foundation,
	Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 
}
{$LONGSTRINGS ON}

interface

uses gears,ui4gh,texutil;

	{ *** MOVEMENT SYSTEM FORMAT *** }
	{ G = GG_MoveSys }
	{ S = Movement System Type }
	{ V = Movement System Size }

Type
	MoveSysDesc = Record
		Dmg: SmallInt;	{ How much damage can it take? }
		Cost: SmallInt;	{ How much does it cost? }
	end;

Const
	NumMoveSys = 8;
	MovesysMan: Array [1..NumMoveSys] of MoveSysDesc = (
		(	{Wheels}
			dmg: 1;
			cost: 10;
		),
		(	{Tracks}
			dmg: 2;
			cost: 10;
		),
		(	{Hover Jets}
			dmg: 0;
			cost: 56;
		),
		(	{Flight Jets}
			dmg: 0;
			cost: 78;
		),
		(	{Arc Thrusters}
			dmg: 0;
			cost: 125;
		),
		(	{Overchargers}
			dmg: 0;
			cost: 38;
		),
		(	{Space Flight}
			dmg: 0;
			cost: 44;
		),
		(	{Heavy Actuators}
			dmg: 1;
			cost: 100;
		)
	);

	GS_Wheels = 1;
	GS_Tracks = 2;
	GS_HoverJets = 3;
	GS_FlightJets = 4;
	GS_Overchargers = 6;
	GS_SpaceFlight = 7;
	GS_HeavyActuator = 8;


Function MovesysBaseDamage( Part: GearPtr ): Integer;
Function MovesysBaseMass( Part: GearPtr ): Integer;
Function MovesysName( Part: GearPtr ): String;
Function MoveSysValue( Part: GearPtr ): LongInt;

Procedure CheckMoverRange( Part: GearPtr );



implementation

Function MovesysBaseDamage( Part: GearPtr ): Integer;
	{Calculate the number of damage points that may be}
	{sustained by the movement system provided.}
	{PRECONDITION: Part points to a valid movement system record.}
var
	it: Integer;
begin
	if MovesysMan[ Part^.S ].DMG = 0 then begin
		{This part has one DP, regardless of value.}
		it := 1;
	end else begin
		it := Part^.V * MovesysMan[ Part^.S ].DMG;
	end;
	MoveSysBaseDamage := it;
end;

Function MovesysBaseMass( Part: GearPtr ): Integer;
	{Calculate the basic mass of this movement system.}
	{In general, this is equal to its damage points.}
	{PRECONDITION: Part points to a valid movement system record.}
begin
	MovesysBaseMass := MovesysBaseDamage(Part);
end;

Function MovesysName( Part: GearPtr ): String;
	{Return a default name for the movement system in question.}
begin
	MovesysName := MsgString( 'MOVESYSNAME_' + BStr(  Part^.S ) );
end;

Function MoveSysValue( Part: GearPtr ): LongInt;
	{ Return the unscaled cost of this movement system. }
begin
	MoveSysValue := Part^.V * MoveSysMan[ Part^.S ].Cost;
end;

Procedure CheckMoverRange( Part: GearPtr );
	{ Examine everything about this part and make sure the values }
	{ fall within the acceptable range. }
var
	T: Integer;
begin
	{ Check S - Movement System Type }
	if Part^.S < 1 then Part^.S := 1
	else if Part^.S > NumMoveSys then Part^.S := NumMoveSys;

	{ Check V - Movement System Size }
	if Part^.V < 1 then Part^.V := 1
	else if Part^.V > 15 then Part^.V := 15;

	{ Check Stats - No Stats are defined. }
	for t := 1 to NumGearStats do Part^.Stat[ T ] := 0;
end;


end.
