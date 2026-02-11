package;

#if android
import android.content.Context as AndroidContext;
import android.os.Environment as AndroidEnvironment;
import android.Permissions as AndroidPermissions;
import android.os.Build.VERSION as AndroidVersion;
import android.os.Build.VERSION_CODES as AndroidVersionCode;
import android.Settings as AndroidSettings;
#end

import debug.FPSCounter;

import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;
import haxe.io.Path;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import states.TitleState;

#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import psychlua.HScript.HScriptInfos;
#end

#if (linux || mac)
import lime.graphics.Image;
#end

#if desktop
import backend.ALSoftConfig;
#end

#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import backend.Highscore;

#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end

class Main extends Sprite
{
	public static final game = {
		width: 1280,
		height: 720,
		initialState: TitleState,
		framerate: 60,
		skipSplash: true,
		startFullscreen: false
	};

	public static var fpsVar:FPSCounter;

	public static function main():Void
	{
		#if !mobile
		if (Path.normalize(Sys.getCwd()) != Path.normalize(lime.system.System.applicationDirectory)) {
			Sys.setCwd(lime.system.System.applicationDirectory);

			if (Path.normalize(Sys.getCwd()) != Path.normalize(lime.system.System.applicationDirectory)) {
				Lib.application.window.alert(
					"Your path is either not run from the game directory,\nor contains illegal UTF-8 characters!\n\nRun from: "
					+ Sys.getCwd()
					+ "\nExpected path: "
					+ lime.system.System.applicationDirectory,
					"Invalid Runtime Path!"
				);
				Sys.exit(1);
			}
		}
		#end
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();
		
		// ============ MOBILE INITIALIZATION ============
		#if mobile
			#if android
			// Android storage ve izin ayarları
			initAndroidStorage();
			#elseif ios
			Sys.setCwd(lime.system.System.applicationStorageDirectory);
			#end
		#end

		// ============ NATIVE FIXES ============
		#if (cpp && windows)
		backend.Native.fixScaling();
		#end

		// ============ VIDEO SUPPORT ============
		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0") ['--no-lua'] #end);
		#end

		// ============ MODS ============
		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		// ============ SAVE DATA ============
		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		Highscore.load();

		// ============ HSCRIPT SETUP ============
		#if HSCRIPT_ALLOWED
		setupHScript();
		#end

		// ============ CONTROLS & PREFS ============
		#if LUA_ALLOWED 
		Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); 
		#end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		
		#if ACHIEVEMENTS_ALLOWED 
		Achievements.load(); 
		#end

		// ============ GAME INITIALIZATION ============
		addChild(new FlxGame(game.width, game.height, game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		// ============ FPS COUNTER (Desktop only) ============
		#if !mobile
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if (fpsVar != null) {
			fpsVar.visible = ClientPrefs.data.showFPS;
		}
		#end
		
		// ============ MOBILE SCREEN SETTINGS ============
		#if mobile
		ScreenUtil.wideScreen.enabled = ClientPrefs.data.wideScreen;
		#end

		// ============ LINUX/MAC ICON FIX ============
		#if (linux || mac)
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		// ============ HTML5 SETTINGS ============
		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		// ============ GENERAL SETTINGS ============
		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];
		
		// ============ CRASH HANDLER ============
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		// ============ DISCORD ============
		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		// ============ SHADER FIX ============
		FlxG.signals.gameResized.add(function(w, h) {
			if (FlxG.cameras != null) {
				for (cam in FlxG.cameras.list) {
					if (cam != null && cam.filters != null)
						resetSpriteCache(cam.flashSprite);
				}
			}
			if (FlxG.game != null)
				resetSpriteCache(FlxG.game);
		});
	}

	// ============ ANDROID STORAGE INITIALIZATION ============
	#if android
	private function initAndroidStorage():Void
	{
		try {
			// Android'de güvenli depolama yolunu al (izin gerektirmez)
			var storagePath:String = lime.system.System.applicationStorageDirectory;
			
			// Çalışma dizinini ayarla
			Sys.setCwd(storagePath);
			
			// Mods klasörünü oluştur
			var modsPath:String = storagePath + "mods/";
			if (!FileSystem.exists(modsPath))
				FileSystem.createDirectory(modsPath);
			
			// Saves klasörünü oluştur
			var savesPath:String = storagePath + "saves/";
			if (!FileSystem.exists(savesPath))
				FileSystem.createDirectory(savesPath);
			
			trace("Android storage initialized: " + storagePath);
		} catch (e:Dynamic) {
			trace("Android storage initialization error: " + e);
		}
	}
	#end
	// ============ HSCRIPT SETUP ============
	#if HSCRIPT_ALLOWED
	private function setupHScript():Void
	{
		Iris.warn = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(WARN, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '') + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('WARNING: $msgInfo', FlxColor.YELLOW);
		};
		
		Iris.error = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(ERROR, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '') + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('ERROR: $msgInfo', FlxColor.RED);
		};
		
		Iris.fatal = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(FATAL, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '') + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('FATAL: $msgInfo', 0xFFBB0000);
		};
	}
	#end

	// ============ SPRITE CACHE RESET ============
	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	// ============ CRASH HANDLER ============
	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "PsychEngine_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error;
		#if officialBuild
		errMsg += "\nPlease report this error to the GitHub page: https://github.com/ShadowMario/FNF-PsychEngine";
		#end
		errMsg += "\n\n> Crash Handler written by: sqirra-rng";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end
		Sys.exit(1);
	}
	#end
}