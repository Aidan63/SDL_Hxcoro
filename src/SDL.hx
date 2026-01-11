package;

import haxe.Exception;
import haxe.io.Bytes;
import cpp.encoding.Utf8;
import haxe.Int64;
import cpp.Char;
import cpp.Pointer;

using cpp.marshal.ViewExtensions;

@:semantics(value)
@:cpp.PointerType({ type : "SDL_Window" })
extern class Window {}

@:semantics(value)
@:cpp.ValueType({ type : "SDL_UserEvent" })
extern class UserEvent {
	var data1 : Pointer<cpp.Object>;

	public function new() : Void;
}

@:semantics(value)
@:cpp.ValueType({ type : "SDL_Event" })
extern class Event {
	var type : Int;

	var user : UserEvent;

	public function new() : Void;
}

@:include("SDL3/SDL.h")
@:buildXml("

<copyFile name='SDL3.dll' from='${SDL_DIST_DIR}\\lib\\x64'/>

<files id='haxe'>
	<compilerflag value='-I${SDL_DIST_DIR}\\include'/>
</files>

<linker id='exe'>
	<lib name='${SDL_DIST_DIR}\\lib\\x64\\SDL3.lib'/>
</linker>

")
extern class SDL {
	static inline final EVENT_QUIT : Int = 0x100;

	static inline final INIT_VIDEO : Int = 0x20;

	static inline final WINDOW_RESIZABLE : Int = 0x20;

	@:native("SDL_Init")
	static function init(flags:Int):Void;

	@:native("SDL_Quit")
	static function quit():Void;

	static inline function createWindow(title:String, width:Int, height:Int, flags:Int64):Window {
		final size   = Utf8.getByteCount(title);
		final buffer = Bytes.alloc(Int64.toInt(size) + 1).asView();

		if (Utf8.encode(title, buffer) != size) {
			throw new Exception("Failed to encode the entire string");
		}

		return createWindowImpl(buffer.reinterpret().ptr, width, height, flags);
	}

	@:native('SDL_DestroyWindow')
	static function destroyWindow(window:Window):Void;

	@:native('SDL_RegisterEvents')
	static function registerEvents(number:Int):Int;

	@:native('SDL_PushEvent')
	static function pushEvent(event:Event):Bool;

	@:native('SDL_PollEvent')
	static function pollEvent(event:Event):Bool;

	//

	@:native("SDL_CreateWindow")
	private static function createWindowImpl(title:Pointer<Char>, width:Int, height:Int, flags:Int64):Window;
}