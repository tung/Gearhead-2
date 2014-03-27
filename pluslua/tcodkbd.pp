unit tcodkbd;

interface

implementation

uses keyboard, tcod;

procedure TCODKbdInitDriver;
begin
	TCOD_console_set_keyboard_repeat(300, 60);
end;

function TCODKbdGetKeyEvent: TKeyEvent;
var
	tkt: TCOD_key_t;
	tkr: TKeyRecord;
	found: boolean;
begin
	found := false;
	while not found do begin
		tkt := TCOD_console_wait_for_keypress(false);
		{ For now, ignore key release events. }
		if tkt.pressed then begin
			if tkt.c <> #0 then begin
				tkr.Flags := kbASCII;
				tkr.KeyCode := word(tkt.c);
				found := true;
			end else begin
				{ translate the keys that matter }
				tkr.Flags := kbFnKey;
				found := true;
				case tkt.vk of
				TCODK_UP: tkr.KeyCode := kbdUp;
				TCODK_DOWN: tkr.KeyCode := kbdDown;
				TCODK_LEFT: tkr.KeyCode := kbdLeft;
				TCODK_RIGHT: tkr.KeyCode := kbdRight;
				TCODK_HOME: tkr.KeyCode := kbdHome;
				TCODK_END: tkr.KeyCode := kbdEnd;
				TCODK_PAGEUP: tkr.KeyCode := kbdPgUp;
				TCODK_PAGEDOWN: tkr.KeyCode := kbdPgDn;
				else found := false
				end;
			end;

			tkr.ShiftState := 0;
			if tkt.shift then tkr.ShiftState := tkr.ShiftState and kbShift;
			if tkt.lctrl or tkt.rctrl then tkr.ShiftState := tkr.ShiftState and kbCtrl;
			if tkt.lalt or tkt.ralt then tkr.ShiftState := tkr.ShiftState and kbAlt;
		end;
	end;

	TCODKbdGetKeyEvent := TKeyEvent(tkr);
end;

function TCODKbdTranslateKeyEvent(tke: TKeyEvent): TKeyEvent;
begin
	TCODKbdTranslateKeyEvent := tke;
end;

const
	CustomDriver: TKeyboardDriver = (
		InitDriver: @TCODKbdInitDriver;
		DoneDriver: nil;

		GetKeyEvent: @TCODKbdGetKeyEvent;
		PollKeyEvent: nil;
		GetShiftState: nil;

		TranslateKeyEvent: @TCODKbdTranslateKeyEvent;
		TranslateKeyEventUniCode: @TCODKbdTranslateKeyEvent;
	);

initialization
	SetKeyboardDriver(CustomDriver);

end.
