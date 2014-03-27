unit tcodvideo;

interface

implementation

uses
	video,
	tcod,
	uiconfig; { GH-specific, used for the terminal width and height. }

const
	tcolor_ptrs: array[0..15] of ^TCOD_color_t = (
		@TCOD_black,
		@TCOD_darker_blue,
		@TCOD_darker_green,
		@TCOD_darker_cyan,
		@TCOD_darker_red,
		@TCOD_darker_magenta,
		@TCOD_darker_yellow,
		@TCOD_grey,

		@TCOD_darker_grey,
		@TCOD_blue,
		@TCOD_green,
		@TCOD_cyan,
		@TCOD_red,
		@TCOD_magenta,
		@TCOD_yellow,
		@TCOD_white
	);

var
	tcolor_from_vidcell: array[0..15] of TCOD_color_t;

procedure InitColors;
var
	i: integer;
begin
	for i := 0 to 15 do begin
		tcolor_from_vidcell[i].r := tcolor_ptrs[i]^.r;
		tcolor_from_vidcell[i].g := tcolor_ptrs[i]^.g;
		tcolor_from_vidcell[i].b := tcolor_ptrs[i]^.b;
	end;
end;

procedure TCODVidInitDriver;
var
	cols, rows: integer;
begin
	{ Terminal dimensions from GH config file. }
	cols := ScreenColumns;
	rows := ScreenRows;

	{ ScreenColumns and ScreenRows used directly send garbage to and crash TCOD_console_init_root. ;_; }
	TCOD_console_init_root(cols, rows, 'GearHead: Arena-R', false, TCOD_RENDERER_SDL);

	{ Ensure InitVideo prepares VideoBuf and OldVideoBuf correctly. }
	ScreenWidth := cols;
	ScreenHeight := rows;
end;

procedure TCODVidUpdateScreen(force: boolean);
var
	i: integer;
	x, y, ch: integer;
	fgc, bgc: TCOD_color_t;
begin
	for i := 0 to (VideoBufSize div SizeOf(TVideoCell)) - 1 do begin
		x := i mod ScreenColumns;
		y := i div ScreenColumns;
		{ Assume little-endian. }
		ch := VideoBuf^[i] and $00FF;
		fgc := tcolor_from_vidcell[(VideoBuf^[i] and $0F00) shr 8];
		bgc := tcolor_from_vidcell[(VideoBuf^[i] and $7000) shr 12];
		{ Ignore blink bit. }
		TCOD_console_put_char_ex(nil, x, y, ch, fgc, bgc);
	end;
	TCOD_console_flush;
end;

procedure TCODVidClearScreen;
begin
	TCOD_console_clear(nil);
end;

const
	CustomDriver: TVideoDriver = (
		InitDriver: @TCODVidInitDriver;
		DoneDriver: nil;
		UpdateScreen: @TCODVidUpdateScreen;
		ClearScreen: @TCODVidClearScreen;
		SetVideoMode: nil;
		GetVideoModeCount: nil;
		GetVideoModeData: nil;
		SetCursorPos: nil;
		GetCursorType: nil;
		SetCursorType: nil;
		GetCapabilities: nil;
	);

initialization
	InitColors;
	SetVideoDriver(CustomDriver);

end.
