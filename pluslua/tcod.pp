unit tcod;

{$LINKLIB tcod}

interface

type
	TCOD_renderer_t = (
		TCOD_RENDERER_GLSL := 0,
		TCOD_RENDERER_OPENGL,
		TCOD_RENDERER_SDL,
		TCOD_NB_RENDERERS
	);

	TCOD_console_t = ^char;	{ really a void * }

	TCOD_keycode_t = (
		TCODK_NONE := 0,
		TCODK_ESCAPE,
		TCODK_BACKSPACE,
		TCODK_TAB,
		TCODK_ENTER,
		TCODK_SHIFT,
		TCODK_CONTROL,
		TCODK_ALT,
		TCODK_PAUSE,
		TCODK_CAPSLOCK,
		TCODK_PAGEUP,
		TCODK_PAGEDOWN,
		TCODK_END,
		TCODK_HOME,
		TCODK_UP,
		TCODK_LEFT,
		TCODK_RIGHT,
		TCODK_DOWN,
		TCODK_PRINTSCREEN,
		TCODK_INSERT,
		TCODK_DELETE,
		TCODK_LWIN,
		TCODK_RWIN,
		TCODK_APPS,
		TCODK_0,
		TCODK_1,
		TCODK_2,
		TCODK_3,
		TCODK_4,
		TCODK_5,
		TCODK_6,
		TCODK_7,
		TCODK_8,
		TCODK_9,
		TCODK_KP0,
		TCODK_KP1,
		TCODK_KP2,
		TCODK_KP3,
		TCODK_KP4,
		TCODK_KP5,
		TCODK_KP6,
		TCODK_KP7,
		TCODK_KP8,
		TCODK_KP9,
		TCODK_KPADD,
		TCODK_KPSUB,
		TCODK_KPDIV,
		TCODK_KPMUL,
		TCODK_KPDEC,
		TCODK_KPENTER,
		TCODK_F1,
		TCODK_F2,
		TCODK_F3,
		TCODK_F4,
		TCODK_F5,
		TCODK_F6,
		TCODK_F7,
		TCODK_F8,
		TCODK_F9,
		TCODK_F10,
		TCODK_F11,
		TCODK_F12,
		TCODK_NUMLOCK,
		TCODK_SCROLLLOCK,
		TCODK_SPACE,
		TCODK_CHAR
	);

	TCOD_key_t = record
		vk: TCOD_keycode_t;
		c: char;
		pressed: boolean;
		lalt: boolean;
		lctrl: boolean;
		ralt: boolean;
		rctrl: boolean;
		shift: boolean;
	end;

	TCOD_bkgnd_flag_t = (
		TCOD_BKGND_NONE := 0,
		TCOD_BKGND_SET,
		TCOD_BKGND_MULTIPLY,
		TCOD_BKGND_LIGHTEN,
		TCOD_BKGND_DARKEN,
		TCOD_BKGND_SCREEN,
		TCOD_BKGND_COLOR_DODGE,
		TCOD_BKGND_COLOR_BURN,
		TCOD_BKGND_ADD,
		TCOD_BKGND_ADDA,
		TCOD_BKGND_BURN,
		TCOD_BKGND_OVERLAY,
		TCOD_BKGND_ALPH,
		TCOD_BKGND_DEFAULT
	);

	TCOD_colctrl_t = (
		TCOD_COLCTRL_1 := 1,
		TCOD_COLCTRL_2,
		TCOD_COLCTRL_3,
		TCOD_COLCTRL_4,
		TCOD_COLCTRL_5,
		{TCOD_COLCTRL_NUMBER := 5,}
		TCOD_COLCTRL_FORE_RGB,
		TCOD_COLCTRL_BACK_RGB,
		TCOD_COLCTRL_STOP
	);

	TCOD_color_t = record
		r, g, b: byte;
	end;

const
	{ TCOD_chars_t: custom characters that libtcod can draw }
	{ single walls }
	TCOD_CHAR_VLINE = #179;
	TCOD_CHAR_HLINE = #196;
	TCOD_CHAR_NE = #191;
	TCOD_CHAR_NW = #218;
	TCOD_CHAR_SE = #217;
	TCOD_CHAR_SW = #192;
	{ arrows }
	TCOD_CHAR_ARROW_E = #26;

	{ Defined in TCOD_colctrl_t enum. }
	TCOD_COLCTRL_NUMBER: TCOD_colctrl_t = TCOD_COLCTRL_5;

	{ TCOD_key_status_t flags can be combined when passed to TCOD_console_check_for_keypress. }
	TCOD_KEY_PRESSED = 1;
	TCOD_KEY_RELEASED = 2;

var
	{ standard colors }
	TCOD_red: TCOD_color_t; cvar; external;
	TCOD_yellow: TCOD_color_t; cvar; external;
	TCOD_green: TCOD_color_t; cvar; external;
	TCOD_cyan: TCOD_color_t; cvar; external;
	TCOD_blue: TCOD_color_t; cvar; external;
	TCOD_magenta: TCOD_color_t; cvar; external;

	{ darker colors }
	TCOD_darker_red: TCOD_color_t; cvar; external;
	TCOD_darker_yellow: TCOD_color_t; cvar; external;
	TCOD_darker_green: TCOD_color_t; cvar; external;
	TCOD_darker_cyan: TCOD_color_t; cvar; external;
	TCOD_darker_blue: TCOD_color_t; cvar; external;
	TCOD_darker_magenta: TCOD_color_t; cvar; external;

	{ grey (with an 'e') levels }
	TCOD_black: TCOD_color_t; cvar; external;
	TCOD_darker_grey: TCOD_color_t; cvar; external;
	TCOD_grey: TCOD_color_t; cvar; external;
	TCOD_white: TCOD_color_t; cvar; external;

{ Console }
procedure TCOD_console_init_root(w, h: integer; title: pchar; fullscreen: boolean; renderer: TCOD_renderer_t); cdecl; external;
function TCOD_console_is_window_closed: boolean; cdecl; external;
function TCOD_console_wait_for_keypress(flushbuf: boolean): TCOD_key_t; cdecl; external;
procedure TCOD_console_set_keyboard_repeat(initial_delay, interval: integer); cdecl; external;
procedure TCOD_console_flush; cdecl; external;
procedure TCOD_console_clear(con: TCOD_console_t); cdecl; external;
procedure TCOD_console_put_char(con: TCOD_console_t; x, y, c: integer; flag: TCOD_bkgnd_flag_t); cdecl; external;
procedure TCOD_console_put_char_ex(con: TCOD_console_t; x, y, c: integer; fore, back: TCOD_color_t); cdecl; external;
procedure TCOD_console_print(con: TCOD_console_t; x, y: integer; fmt: pchar); cdecl; varargs; external;
function TCOD_console_check_for_keypress(flags: integer): TCOD_key_t; cdecl; external;

implementation

end.
