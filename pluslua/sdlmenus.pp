unit sdlmenus;
{$MODE FPC}

	{ BUGS - If SelectMenu is handed an empty menu, all heck will }
	{  break loose. This can be a particular problem for SelectFile. }
{
	Quiz Game
	Copyright (C) 2010 Joseph Hewitt

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

uses sdl,sdl_ttf,dos,texutil,sdlgfx,uiconfig;


const
	{These two constants are used to tell the SELECT procedure whether or not}
	{the user is allowed to cancel.}
	RPMNormal = 0;
	RPMNoCancel = 1;
	RPMEscCancel = 2;	{ Menu can be cancelled, but not by mouse click. }

	RPMNoCleanup = 2; {If you want the menu left on the screen after we've finished, use this.}

type
	RPGMenuKeyPtr = ^RPGMenuKey;
	RPGMenuKey = Record
		k: Char;
		value: longint;		{The value returned when this key is pressed.}
		next: RPGMenuKeyPtr;
	end;

	RPGMenuItemPtr = ^RPGMenuItem;
	RPGMenuItem = Record
		msg: string;		{The text which appears in the menu}
		value: longint;		{A value, returned by SelectMenu. -1 is reserved for Cancel}
		desc: string;		{Pointer to the item description. If Nil, no desc.}
		next: RPGMenuItemPtr;
	end;
	RPGMenu = Record
		active: boolean;
		itemcolor,selcolor,dtexcolor: TSDL_Color;
		Menu_Zone: PSDL_Rect;
		Desc_Zone: TSDL_Rect;
		mode: Byte;
		topitem,selectitem,numitem: longint; {fields holding info about the status of the menu.}
		FirstItem: RPGMenuItemPtr;
		FirstKey: RPGMenuKeyPtr;
	end;
	RPGMenuPtr = ^RPGMenu;



Function AddRPGMenuItem(var RPM: RPGMenuPtr; const msg: string; value: longint; const desc: string): RPGMenuItemPtr;
Function AddRPGMenuItem(var RPM: RPGMenuPtr; const msg: string; value: longint): RPGMenuItemPtr;
Procedure DisposeRPGMenuItem( var LList: RPGMenuItemPtr );
Procedure ClearMenu( RPM: RPGMenuPtr );
Procedure RemoveRPGMenuItem(RPM: RPGMenuPtr; var LMember: RPGMenuItemPtr);

Procedure AddRPGMenuKey(RPM: RPGMenuPtr; k: Char; value: longint);
Function CreateRPGMenu(icolor,scolor: TSDL_Color; Z: PSDL_Rect): RPGMenuPtr;
Procedure AttachMenuDesc( RPM: RPGMenuPtr; Z: TSDL_Rect );

Procedure DisposeRPGMenu(var RPM: RPGMenuPtr);
Procedure DisplayMenu( RPM: RPGMenuPtr; ReDrawer: RedrawProcedureType );
Function RPMLocateByPosition(RPM: RPGMenuPtr; i: longint): RPGMenuItemPtr;
Function RPMLocateByValue(RPM: RPGMenuPtr; i: longint): RPGMenuItemPtr;
Function SelectMenu( RPM: RPGMenuPtr; ReDrawer: RedrawProcedureType ): longint;
Procedure RPMSortAlpha(RPM: RPGMenuPtr);

Function CurrentMenuItemValue( RPM: RPGMenuPtr ): longint;
Function SetItemByValue( RPM: RPGMenuPtr ; V: longint ): RPGMenuItemPtr;
Procedure SetItemByPosition( RPM: RPGMenuPtr ; N: longint );

Procedure BuildFileMenu( RPM: RPGMenuPtr; const SearchPattern: String );
Function SelectFile( RPM: RPGMenuPtr; ReDrawer: RedrawProcedureType ): String;

Procedure AlphaKeyMenu( RPM: RPGMenuPtr );


implementation

Function LastMenuItem(MIList: RPGMenuItemPtr): RPGMenuItemPtr;
	{This procedure will find the last item in the linked list.}
begin
	{While the menu item is pointing to a next menu item, it's not the last. duh.}
	{So, move through the list until we hit a Nil pointer.}
	while MIList^.next <> Nil do begin
		{Check the next one.}
		MIList := MIList^.next;
	end;
	{We've found a MI.next = Nil. Yay! Return its address.}
	LastMenuItem := MIList;
end;

Function AddRPGMenuItem(var RPM: RPGMenuPtr; const msg: string; value: longint; const desc: string): RPGMenuItemPtr;
	{This procedure will add an item to the RPGToolMenu.}
	{The new item will be added as the last item in the list.}
var
	it: ^RPGMenuItem;		{Here's a pointer for the item we're creating.}
	temp: RPGMenuItemPtr;
begin
	{Allocate memory for it.}
	New(it);

	{Check to make sure that the allocation succeeded.}
	if it = Nil then begin
		exit( Nil );
	end;

	{Initialize it to the correct values.}
	it^.msg := msg;
	it^.value := value;
	it^.next := Nil;
	it^.desc := desc; 	{The desc field is assigned the value of PChar since it}
				{is assumed that we arent responsible for the allocation,}
				{disposal, or contents of this string.}

	{Locate the last item in the list, then assign "it" to it.}
	{If the list is currently empty, stick "it" in as the first item.}
	if RPM^.firstitem = Nil then begin
		RPM^.firstitem := it;
	end else begin
		temp := LastMenuItem(RPM^.FirstItem);
		temp^.next := it;		
	end;

	{Increment the NumItem field.}
	Inc(RPM^.numitem);

	AddRPGMenuItem := it;
end;

Function AddRPGMenuItem(var RPM: RPGMenuPtr; const msg: string; value: longint): RPGMenuItemPtr;
	{ Just like the above, but no desc. }
begin
	AddRPGMenuItem := AddRPGMenuItem( RPM , msg , value , '' );
end;

Procedure DisposeRPGMenuItem( var LList: RPGMenuItemPtr );
	{ Get rid of this list of items. }
	{ WARNING - If you call this procedure for a menu, it will not }
	{ change the value of the NumItems field!!! This will cause }
	{ problems when trying to use the menu. Unless you know exactly }
	{ what you're doing, use the ClearMenu procedure instead. }
var
	NextItem: RPGMenuItemPtr;
begin
	while LList <> Nil do begin
		NextItem := LList^.Next;
		Dispose( LList );
		LList := NextItem;
	end;
end;

Procedure ClearMenu( RPM: RPGMenuPtr );
	{ Deallocate all the items in this menu, and set the number of }
	{ items to 0. }
var
	NextItem: RPGMenuKeyPtr;
begin
	DisposeRPGMenuItem( RPM^.FirstItem );
	RPM^.NumItem := 0;
	RPM^.SelectItem := 1;
	RPM^.topitem := 1;

	while RPM^.FirstKey <> Nil do begin
		NextItem := RPM^.FirstKey^.Next;
		Dispose( RPM^.FirstKey );
		RPM^.FirstKey := NextItem;
	end;
end;

Procedure RemoveRPGMenuItem(RPM: RPGMenuPtr; var LMember: RPGMenuItemPtr);
	{Locate and extract member LMember from list LList.}
	{Then, dispose of LMember.}
var
	a,b: RPGMenuItemPtr;
begin
	{ Make sure LMember isn't Nil }
	if LMember = Nil then Exit;

	{Initialize A and B}
	B := RPM^.FirstItem;
	A := Nil;

	{Locate LMember in the list. A will thereafter be either Nil,}
	{if LMember if first in the list, or it will be equal to the}
	{element directly preceding LMember.}
	while (B <> LMember) and (B <> Nil) do begin
		A := B;
		B := B^.next;
	end;

	if B = Nil then begin
		{Major FUBAR. The member we were trying to remove can't}
		{be found in the list.}
		writeln('ERROR- RemoveLink asked to remove a link that doesnt exist.');
		end
	else if A = Nil then begin
		{There's no element before the one we want to remove,}
		{i.e. it's the first one in the list.}
		RPM^.FirstItem := B^.Next;
		Dispose(B);
		end
	else begin
		{We found the attribute we want to delete and have another}
		{one standing before it in line. Go to work.}
		A^.next := B^.next;
		Dispose(B);
	end;

	{ Reduce the number of items in the menu. }
	Dec(RPM^.NumItem);
end;

Procedure AddRPGMenuKey(RPM: RPGMenuPtr; k: Char; value: longint);
	{Add a dynamically defined RPGMenuKey to the menu.}
var
	it: RPGMenuKeyPtr;
begin
	New(it);
	if it = Nil then begin
		exit;
	end;

	{Initialize the values.}
	it^.k := k;
	it^.value := value;
	it^.next := RPM^.FirstKey;
	RPM^.FirstKey := it;
end;

Function CreateRPGMenu(icolor,scolor: TSDL_Color; Z: PSDL_Rect): RPGMenuPtr;
	{This function creates a new RPGMenu record, and returns the address.}
var
	it: ^RPGMenu;			{Here's a pointer for the menu we're making.}
begin
	{Allocate memory for it.}
	New(it);

	{Check to make sure that we've actually initialized something.}
	if it = Nil then exit( Nil );

	{Initialize the elements of the record.}
	it^.itemcolor := icolor;
	it^.selcolor := scolor;
	it^.Menu_Zone := Z;
	it^.Desc_Zone.W := 0; {A width value of 0 means there is no desc window.}
	it^.Mode := RPMNormal;
	it^.FirstItem := Nil;
	it^.FirstKey := Nil;
	it^.dtexcolor := TextColor;
	it^.active := False;

	{TopItem refers to the highest item on the screen display.}
	it^.topitem := 1;

	{SelectItem refers to the item currently being pointed at by the selector.}
	it^.selectitem := 1;

	{NumItem refers to the total number of items currently in the linked list.}
	it^.numitem := 0;

	{Return the address.}
	CreateRPGMenu := it;
end;

Procedure AttachMenuDesc( RPM: RPGMenuPtr; Z: TSDL_Rect );
	{ Set the area for description items to zone Z. }
begin
	RPM^.Desc_Zone := Z;
end;

Procedure DisposeRPGMenu(var RPM: RPGMenuPtr);
	{This procedure is called when you want to get rid of the menu. It will deallocate}
	{the memory for the RPGMenu record and also for all of the linked RPGMenuItems.}
var
	c,d: RPGMenuKeyPtr;
begin
	{Check to make sure that we've got a valid pointer here.}
	if RPM = Nil then begin
		exit;
	end;

	{Save the location of the first menu item...}
	DisposeRPGMenuItem( RPM^.FirstItem );
	c := RPM^.FirstKey;
	{... then get rid of the menu record.}
	Dispose(RPM);
	RPM := Nil;

	{Keep processing the menu items until we hit a Nil nextitem.}
	while c <> Nil do begin
		d := c^.next;
		Dispose(c);
		c := d;
	end;
end;

Function RPMLocateByPosition(RPM: RPGMenuPtr; i: longint): RPGMenuItemPtr;
	{Locate the i'th element of the item list, then return its address.}
var
	a: RPGMenuItemPtr;	{Our pointer}
	t: longint;		{Our counter}
begin
	{Error check, first off.}
	if i > RPM^.numitem then begin
		exit( Nil );
	end;

	a := RPM^.FirstItem;
	t := 1;

	if i > 1 then begin
		for t := 2 to i do
			a := a^.next;
	end;

	RPMLocateByPosition := a;
end;

Function RPMLocateByValue(RPM: RPGMenuPtr; i: longint): RPGMenuItemPtr;
	{Locate the i'th element of the item list, then return its address.}
var
	t,a: RPGMenuItemPtr;	{Our counter and a pointer}
begin
	a := Nil;
	t := RPM^.FirstItem;

	while ( a = Nil ) and ( t <> Nil ) do begin
		if t^.value = i then a := t;
		t := t^.Next;
	end;

	RPMLocateByValue := a;
end;

Function MenuHeight( RPM: RPGMenuPtr ): longint;
	{ Return the height of the menu, in text rows. }
var
	MH: longint;
begin
	MH := ( RPM^.Menu_Zone^.h div TTF_FontLineSkip( game_font ) );
	if MH < 1 then MH := 1;
	MenuHeight := MH;
end;

Procedure RPMRefreshDesc(RPM: RPGMenuPtr);
	{Refresh the menu description box, if appropriate.}
begin
	{Check to make sure that this menu has a description box, first off.}
	if RPM^.Desc_Zone.W > 0 then begin
		CMessage( RPMLocateByPosition(RPM,RPM^.selectitem)^.desc , RPM^.Desc_Zone , RPM^.dtexcolor );
	end;
end;

Procedure DisplayMenu( RPM: RPGMenuPtr; ReDrawer: RedrawProcedureType );
	{Display the menu on the screen.}
var
	topitem: RPGMenuItemPtr;
	a: RPGMenuItemPtr;		{A pointer to be used while printing.}
	t: longint;
	height: longint;		{The width of the menu display.}
	NextColor: TSDL_Color;
	MyDest: TSDL_Rect;
	Y,DY: longint;
begin
	{Error check- make sure the menu has items in it.}
	if RPM^.FirstItem = Nil then Exit;

	{ If a redraw procedure has been specified, call it. }
	if ReDrawer <> Nil then ReDrawer;

	SDL_SetClipRect( Game_Screen , @RPM^.Menu_Zone^ );

	{Calculate the height of the menu.}
	height := MenuHeight( rpm );

	{Locate the top of the menu.}
	topitem := RPMLocateByPosition(RPM,RPM^.topitem);

	MyDest.X := RPM^.Menu_Zone^.X;
	Y := RPM^.Menu_Zone^.Y;
	DY := TTF_FontLineSkip( game_font );
	MyDest.W := RPM^.Menu_Zone^.W;

	a := topitem;
	for t := 1 to Height do begin
		MyDest.Y := Y;
		Y := Y + DY;

		{If we're at the currently selected item, highlight it.}
		if ((t + RPM^.topitem - 1) = RPM^.selectitem) and RPM^.Active then
			NextColor := RPM^.selcolor
		else
			NextColor := RPM^.itemcolor;

		QuickText( a^.msg , MyDest , NextColor , game_font );

		a := a^.next;

		{Check to see if we've prematurely encountered the end of the list.}
		if a = Nil then break;
	end;

	{Restore the window to its regular size.}
	SDL_SetClipRect( Game_Screen , Nil );

	{If there's an associated Desc field, display it now.}
	RPMRefreshDesc(RPM);
end;

Procedure RPMReposition( RPM: RPGMenuPtr; FullScroll: Boolean );
	{The selected item has just changed, and is no longer visible on screen.}
	{Adjust the RPGMenu's topitem field to an appropriate value.}
begin
	{When this function is called, there are two possibilities: either the}
	{selector has moved off the bottom of the page or the top.}

	if RPM^.selectitem < RPM^.topitem then begin
		{The selector has moved off the bottom of the list. The new page}
		{display should start with SelectItem on the bottom.}
		if FullScroll then begin
			RPM^.topitem := RPM^.selectitem - MenuHeight( RPM ) + 1;
		end else begin
			RPM^.topitem := RPM^.selectitem;
		end;

		{Error check- if this moves topitem below 1, that's bad.}
		if RPM^.topitem < 1 then
			RPM^.topitem := 1;
		end
	else begin
		{The selector has moved off the top of the list. The new page should}
		{start with SelectItem at the top, unless this would make things look}
		{funny.}
		if FullScroll then begin
			if ((RPM^.selectitem + MenuHeight( RPM ) - 1) > RPM^.numitem) then begin
				{There will be whitespace at the bottom of the menu if we assign}
				{SelectItem to TopItem. Make TopItem equal to the effective last}
				{page.}
				RPM^.topitem := RPM^.numitem - MenuHeight( RPM ) + 1;
				if RPM^.topitem < 1 then RPM^.topitem := 1;
				end
			else
				RPM^.topitem := RPM^.selectitem;
		end else if ((RPM^.topitem + MenuHeight( RPM ) - 1) < RPM^.numitem) then begin
			Inc( RPM^.TopItem );
		end;
	end;

end;

Procedure RPMUpKey( RPM: RPGMenuPtr; FullScroll: Boolean );
	{Someone just pressed the UP key, and we're gonna process that input.}
	{PRECONDITIONS: RPM has been initialized properly, and is currently being}
	{  displayed on the screen.}
begin
	{Decrement the selected item by one.}
	Dec(RPM^.selectitem);

	{If this causes it to go beneath one, wrap around to the last item.}
	if RPM^.selectitem = 0 then
		RPM^.selectitem := RPM^.numitem;

	{If the movement takes the selected item off the screen, do a redisplay.}
	{Otherwise, indicate the newly selected item.}
	if (RPM^.selectitem < RPM^.topitem) or ((RPM^.selectitem - RPM^.topitem) >= MenuHeight( RPM )) then begin
		{Determine an appropriate new value for topitem.}
		RPMReposition(RPM,FullScroll);
	end;
end;

Procedure RPMDownKey( RPM: RPGMenuPtr; FullScroll: Boolean );
	{Someone just pressed the DOWN key, and we're gonna process that input.}
	{PRECONDITIONS: RPM has been initialized properly, and is currently being}
	{  displayed on the screen.}
begin
	{Increment the selected item.}
	Inc(RPM^.selectitem);
	{If this takes the selection out of bounds, restart at the first item.}
	if RPM^.selectitem = RPM^.numitem + 1 then
		RPM^.selectitem := 1;

	{If the movement takes the selected item off the screen, do a redisplay.}
	{Otherwise, indicate the newly selected item.}
	if (RPM^.selectitem < RPM^.topitem) or ((RPM^.selectitem - RPM^.topitem) >= MenuHeight( RPM ) ) then begin
		{Determine an appropriate new value for topitem.}
		RPMReposition(RPM,FullScroll);
	end;
end;


Function SelectMenu( RPM: RPGMenuPtr; ReDrawer: RedrawProcedureType ): longint;
	{This function will allow the user to browse through the menu and will}
	{return a value based upon the user's selection.}
var
	getit: char;		{Character used to store user input}
	r,I: longint;		{The value we'll be sending back.}
	m: RPGMenuKeyPtr;
	UK: Boolean;		{Has a special MenuKey been pressed?}
	OldMouseX, OldMouseY: longint; { TUNGINOBI: I got sick of the mouse cursor getting }
                          { in the way of the keyboard, so this will only }
                          { change the menu item if the mouse has moved. }
begin
	{The menu is now active!}
	RPM^.Active := True;
	{Show the menu to the user.}
	DisplayMenu( RPM , ReDrawer );
	DoFlip;

	{TUNGINOBI: Initialise the mouse movement variables}
	OldMouseX := Mouse_X;
	OldMouseY := Mouse_Y;

	{Initialize UK}
	UK := False;

	{Start the loop. Remain in this loop until either the player makes a selection}
	{or cancels the menu using the ESC key.}
	repeat
		DisplayMenu(RPM,ReDrawer);
		DoFlip;

		{Read the input from the keyboard.}
		getit := RPGKey;

		{Certain keys need processing- if so, process them.}
		case getit of
			{Selection Movement Keys}
			RPK_Up: begin
					RPMUpKey( RPM , True );
					{ Override mouse pointer selection. }
					OldMouseX := Mouse_X;
					OldMouseY := Mouse_Y;
				end;
			RPK_Down: begin
					RPMDownKey( RPM , True );
					{ Ditto the above. }
					OldMouseX := Mouse_X;
					OldMouseY := Mouse_Y;
				end;
			RPK_TimeEvent:
				{ If the mouse pointer is around }
				{ the menu, we may have to do something. }
				if ( Mouse_X >= RPM^.Menu_Zone^.X ) and ( Mouse_X <= ( RPM^.Menu_Zone^.X + RPM^.Menu_Zone^.W ) ) and (( Mouse_X <> OldMouseX ) or ( Mouse_Y <> OldMouseY )) then begin
					if ( Mouse_Y < ( RPM^.Menu_Zone^.Y ) ) then begin
						if ( RPM^.SelectItem > 1 ) then RPMUpKey( RPM , False );
					end else if ( Mouse_Y > ( RPM^.Menu_Zone^.Y + RPM^.Menu_Zone^.H ) ) then begin
						if ( (RPM^.selectitem - RPM^.topitem) < MenuHeight( RPM ) ) and ( RPM^.selectitem < RPM^.numitem ) then RPMDownKey( RPM , False );
					end else begin
						I := ( Mouse_Y - RPM^.Menu_Zone^.Y ) div TTF_FontLineSkip( game_font );
						SetItemByPosition( RPM , RPM^.TopItem + I );
						{ Upon setting an item directly, freeze the mouse. }
						OldMouseX := Mouse_X;
						OldMouseY := Mouse_Y;
					end;
				end;
			RPK_MouseButton:
				{ If the mouse hit happened inside }
				{ the menu area, it was a selection. }
				{ Otherwise it was a cancel. }
				if ( Mouse_X >= RPM^.Menu_Zone^.X ) and ( Mouse_X <= ( RPM^.Menu_Zone^.X + RPM^.Menu_Zone^.W )) and ( Mouse_Y >= RPM^.Menu_Zone^.Y ) and ( Mouse_Y <= ( RPM^.Menu_Zone^.Y + RPM^.Menu_Zone^.H )) then begin
					getit := ' ';
				end else begin
					if ( RPM^.Mode <> RPMNoCancel ) and ( RPM^.Mode <> RPMEscCancel ) then getit := #27
					else getit := ' ';
				end;
			RPK_RightButton:
				if ( RPM^.Mode <> RPMNoCancel ) and ( RPM^.Mode <> RPMEscCancel ) then getit := #27;

			{If we receive an ESC, better check to make sure we're in a}
			{cancelable menu. If not, convert the ESC to an unused key.}
			#27: If RPM^.Mode = RPMNoCancel then getit := 'Q';
			{ If we get a backspace, conver that to ESC. }
			#8: If RPM^.Mode <> RPMNoCancel then getit := #27;
			{ Convert enter to space. }
			#13,#10: getit := ' ';
		end;


		{Check to see if a special MENU KEY has been pressed.}
		if RPM^.FirstKey <> Nil then begin
			m := RPM^.FirstKey;
			while m <> Nil do begin
				if getit = m^.k then begin
					UK := True;
					r := m^.value;
				end;
				m := m^.next;
			end;
		end;

	{Check for a SPACE or ESC.}
	until (getit = ' ') or (getit = #27) or UK;

	{The menu is no longer active.}
	RPM^.Active := False;

	{We have to send back a different value depending upon whether a selection}
	{was made or the menu was cancelled. If an item was selected, return its}
	{value field. The value always returned by a cancel will be -1.}
	{If a MenuKey was pressed, r already contains the right value.}
	if getit = ' ' then begin
			r := RPMLocateByPosition(RPM,RPM^.selectitem)^.value;
		end
	else if not UK then
		r := -1;

	SelectMenu := r;
end;

Procedure RPMSortAlpha(RPM: RPGMenuPtr);
	{Given a menu, RPM, sort its items based on the alphabetical}
	{order of their msg fields.}
	{I should mention here that I haven't written a sorting}
	{algorithm in years, and only once on a linked list (CS assignment).}
	{I think this is an insertion sort... I checked on internet for}
	{examples of sorting techniques, found a bunch of contradictory}
	{information, and decided to just write the easiest thing that}
	{would work. Since we're dealing with a relatively small number}
	{of items here, speed shouldn't be that big a concern.}
var
	sorted: RPGMenuItemPtr;	{The sorted list}
	a,b,c,d: RPGMenuItemPtr;{Counters. We always need them, you know.}
	youshouldstop: Boolean;	{Can you think of a better name?}
begin
	{Initialize A and Sorted.}
	a := RPM^.firstitem;
	Sorted := Nil;

	while a <> Nil do begin
		b := a;		{b is to be added to sorted}
		a := a^.next;	{increase A to the next item in the menu}

		{Give b's Next field a value of Nil.}
		b^.next := nil;

		{Locate the correct position in Sorted to store b}
		if Sorted = Nil then
			{This is the trivial case- Sorted is empty.}
			Sorted := b
		else if UpCase( b^.msg ) < Upcase( Sorted^.msg ) then begin
			{b should be the first element in the list.}
			c := sorted;
			sorted := b;
			sorted^.next := c;
			end
		else begin
			{c and d will be used to move through Sorted.}
			c := Sorted;

			{Locate the last item lower than b}
			youshouldstop := false;
			repeat
				d := c;
				c := c^.next;

				if c = Nil then
					youshouldstop := true
				else if UpCase( c^.msg ) > UpCase( b^.msg ) then begin
					youshouldstop := true;
				end;
			until youshouldstop;
			b^.next := c;
			d^.next := b;
		end;
	end;
	RPM^.firstitem := Sorted;
end;

Function CurrentMenuItemValue( RPM: RPGMenuPtr ): longint;
	{ Determine the value of the current menu item, and return it. }
	{ Return 0 if the item is not found. }
var
	Item: RPGMenuItemPtr;
begin
	item := RPMLocateByPosition( RPM , RPM^.SelectItem );
	if item = Nil then begin
		CurrentMenuItemValue := 0;
	end else begin
		CurrentMenuItemValue := item^.value;
	end;
end;

Function SetItemByValue( RPM: RPGMenuPtr ; V: longint ): RPGMenuItemPtr;
	{ Search through the list, and set the SelectItem }
	{ field to the first menu item which matches V. }
var
	T: longint;
	MI: RPGMenuItemPtr;
begin
	if RPM = Nil then exit;

	MI := RPM^.FirstItem;
	T := 1;

	while (MI <> Nil) and (MI^.Value <> V) do begin
		MI := MI^.Next;
		Inc( T );
	end;

	if MI <> Nil then begin
		RPM^.SelectItem := T;

		if (RPM^.selectitem < RPM^.topitem) or ((RPM^.selectitem - RPM^.topitem) > MenuHeight( RPM ) ) then begin
			{Determine an appropriate new value for topitem.}
			RPMReposition(RPM,True);
		end;
	end;

	SetItemByValue := MI;
end;

Procedure SetItemByPosition( RPM: RPGMenuPtr ; N: longint );
	{ Search through the list, and set the SelectItem }
	{ field to the Nth menu item. }
begin
	if RPM = Nil then exit;

	if N <= RPM^.NumItem then begin
		RPM^.SelectItem := N;

		if (RPM^.selectitem < RPM^.topitem) or ((RPM^.selectitem - RPM^.topitem + 1) > MenuHeight( RPM ) ) then begin
			{Determine an appropriate new value for topitem.}
			RPMReposition(RPM,True);
		end;
	end;
end;


Procedure BuildFileMenu( RPM: RPGMenuPtr; const SearchPattern: String );
	{ Do a DosSearch for files matching SearchPattern, then add }	
	{ each of the files found to the menu. }
var
	F: SearchRec;
	N: longint;
begin
	N := 1;
	FindFirst( SearchPattern , AnyFile , F );

	While DosError = 0 do begin
		AddRPGMenuItem( RPM , F.Name , N );
		Inc(N);
		FindNext( F );
	end;
end;

Function SelectFile( RPM: RPGMenuPtr; ReDrawer: RedrawProcedureType ): String;
	{ RPM is a menu created by the BuildFileMenu procedure. }
	{ So, select one of the items and return the item name, which }
	{ should be a filename. }
var
	N: longint;	{ The number of the file selected. }
	Name: String;	{ The name of the filename selected. }
begin
	{ Do the menu selection first. }
	N := SelectMenu( RPM , ReDrawer );

	if N = -1 then begin
		{ Selection was canceled. So, return an empty string. }
		Name := '';
	end else begin
		{ Locate the selected element of the menu. }
		Name := RPMLocateByPosition(RPM,RPM^.SelectItem)^.msg;
	end;

	SelectFile := Name;
end;

Procedure AlphaKeyMenu( RPM: RPGMenuPtr );
	{ Alter this menu so that each item in it has a letter key }
	{ hotlinked. }
	{ This procedure has nothing to do with gears, but it's easier }
	{ to stick it here than keep two copies in the conmenus and }
	{ sdlmenus units. What I really need is a separate menu-utility }
	{ unit, I guess. }
var
	Key: Char;
	MI: RPGMenuItemPtr;
begin
	{ The hotkeys start with 'a'. }
	Key := 'a';

	MI := RPM^.firstitem;
	while MI <> Nil do begin
		{ Alter the message. }
		MI^.msg := Key + ') ' + MI^.msg;

		{ Add the key. }
		AddRPGMenuKey( RPM , Key , MI^.value );

		{ Move to the next letter in the series. }
		{ note that only 52 letters can be assigned. }
		if key = 'z' then key := 'A'
		else inc( key );

		MI := MI^.Next;
	end;
end;


end.


