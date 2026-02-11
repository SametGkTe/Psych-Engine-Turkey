package backend;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

import states.TitleState;

// Add a variable here and it will get automatically saved
@:structInit class SaveVariables {
	public var downScroll:Bool = false;
	public var middleScroll:Bool = false;
	public var opponentStrums:Bool = true;
	public var showFPS:Bool = true;
	public var flashing:Bool = true;
	public var autoPause:Bool = true;
	public var antialiasing:Bool = true;
	public var noteSkin:String = 'Default';
	public var splashSkin:String = 'Psych';
	public var splashAlpha:Float = 0.6;
	public var lowQuality:Bool = false;
	public var shaders:Bool = true;
	public var cacheOnGPU:Bool = #if !switch false #else true #end; // GPU Caching made by Raltyro
	public var framerate:Int = 60;
	public var camZooms:Bool = true;
	public var hideHud:Bool = false;
	public var noteOffset:Int = 0;
	public var debugMode:Bool = false;
	
	/* Mobile */
	public var wideScreen:Bool = false;
	#if android public var storageType:String = "EXTERNAL_DATA"; #end
	
	public var mobileBinds:Map<String, Array<String>> = [
		// 1K
		'1k_note_1'		=> ['1K_NOTE_1'],

		// 2K
		'2k_note_1'		=> ['2K_NOTE_1'],
		'2k_note_2'		=> ['2K_NOTE_2'],

		// 3K
		'3k_note_1'		=> ['3K_NOTE_1'],
		'3k_note_2'		=> ['3K_NOTE_2'],
		'3k_note_3'		=> ['3K_NOTE_3'],

		// 4K
		'note_left'		=> ['NOTE_LEFT'],
		'note_down'	=> ['NOTE_DOWN'],
		'note_up'		=> ['NOTE_UP'],
		'note_right'		=> ['NOTE_RIGHT'],
		
		// 5K
		'5k_note_1'		=> ['5K_NOTE_1'],
		'5k_note_2'		=> ['5K_NOTE_2'],
		'5k_note_3'		=> ['5K_NOTE_3'],
		'5k_note_4'		=> ['5K_NOTE_4'],
		'5k_note_5'		=> ['5K_NOTE_5'],
		
		// 6K
		'6k_note_1'		=> ['6K_NOTE_1'],
		'6k_note_2'		=> ['6K_NOTE_2'],
		'6k_note_3'		=> ['6K_NOTE_3'],
		'6k_note_4'		=> ['6K_NOTE_4'],
		'6k_note_5'		=> ['6K_NOTE_5'],
		'6k_note_6'		=> ['6K_NOTE_6'],
		
		// 7K
		'7k_note_1'		=> ['7K_NOTE_1'],
		'7k_note_2'		=> ['7K_NOTE_2'],
		'7k_note_3'		=> ['7K_NOTE_3'],
		'7k_note_4'		=> ['7K_NOTE_4'],
		'7k_note_5'		=> ['7K_NOTE_5'],
		'7k_note_6'		=> ['7K_NOTE_6'],
		'7k_note_7'		=> ['7K_NOTE_7'],
		
		// 8K
		'8k_note_1'		=> ['8K_NOTE_1'],
		'8k_note_2'		=> ['8K_NOTE_2'],
		'8k_note_3'		=> ['8K_NOTE_3'],
		'8k_note_4'		=> ['8K_NOTE_4'],
		'8k_note_5'		=> ['8K_NOTE_5'],
		'8k_note_6'		=> ['8K_NOTE_6'],
		'8k_note_7'		=> ['8K_NOTE_7'],
		'8k_note_8'		=> ['8K_NOTE_8'],
		
		// 9K
		'9k_note_1'		=> ['9K_NOTE_1'],
		'9k_note_2'		=> ['9K_NOTE_2'],
		'9k_note_3'		=> ['9K_NOTE_3'],
		'9k_note_4'		=> ['9K_NOTE_4'],
		'9k_note_5'		=> ['9K_NOTE_5'],
		'9k_note_6'		=> ['9K_NOTE_6'],
		'9k_note_7'		=> ['9K_NOTE_7'],
		'9k_note_8'		=> ['9K_NOTE_8'],
		'9k_note_9'		=> ['9K_NOTE_9'],
		
		// 20K
		'20k_note_1'	=> ['20K_NOTE_1'],
		'20k_note_2'	=> ['20K_NOTE_2'],
		'20k_note_3'	=> ['20K_NOTE_3'],
		'20k_note_4'	=> ['20K_NOTE_4'],
		'20k_note_5'	=> ['20K_NOTE_5'],
		'20k_note_6'	=> ['20K_NOTE_6'],
		'20k_note_7'	=> ['20K_NOTE_7'],
		'20k_note_8'	=> ['20K_NOTE_8'],
		'20k_note_9'	=> ['20K_NOTE_9'],
		'20k_note_10'	=> ['20K_EXTRA_10'],
		'20k_note_11'	=> ['20K_EXTRA_11'],
		'20k_note_12'	=> ['20K_EXTRA_12'],
		'20k_note_13'	=> ['20K_EXTRA_13'],
		'20k_note_14'	=> ['20K_EXTRA_14'],
		'20k_note_15'	=> ['20K_EXTRA_15'],
		'20k_note_16'	=> ['20K_EXTRA_16'],
		'20k_note_17'	=> ['20K_EXTRA_17'],
		'20k_note_18'	=> ['20K_EXTRA_18'],
		'20k_note_19'	=> ['20K_EXTRA_19'],
		'20k_note_20'	=> ['20K_EXTRA_20'],
		
		// 55K
		'55k_note_1'	=> ['55K_NOTE_1'],
		'55k_note_2'	=> ['55K_NOTE_2'],
		'55k_note_3'	=> ['55K_NOTE_3'],
		'55k_note_4'	=> ['55K_NOTE_4'],
		'55k_note_5'	=> ['55K_NOTE_5'],
		'55k_note_6'	=> ['55K_NOTE_6'],
		'55k_note_7'	=> ['55K_NOTE_7'],
		'55k_note_8'	=> ['55K_NOTE_8'],
		'55k_note_9'	=> ['55K_NOTE_9'],
		'55k_note_10'	=> ['55K_EXTRA_10'],
		'55k_note_11'	=> ['55K_EXTRA_11'],
		'55k_note_12'	=> ['55K_EXTRA_12'],
		'55k_note_13'	=> ['55K_EXTRA_13'],
		'55k_note_14'	=> ['55K_EXTRA_14'],
		'55k_note_15'	=> ['55K_EXTRA_15'],
		'55k_note_16'	=> ['55K_EXTRA_16'],
		'55k_note_17'	=> ['55K_EXTRA_17'],
		'55k_note_18'	=> ['55K_EXTRA_18'],
		'55k_note_19'	=> ['55K_EXTRA_19'],
		'55k_note_20'	=> ['55K_EXTRA_20'],
		'55k_note_21'	=> ['55K_EXTRA_21'],
		'55k_note_22'	=> ['55K_EXTRA_22'],
		'55k_note_23'	=> ['55K_EXTRA_23'],
		'55k_note_24'	=> ['55K_EXTRA_24'],
		'55k_note_25'	=> ['55K_EXTRA_25'],
		'55k_note_26'	=> ['55K_EXTRA_26'],
		'55k_note_27'	=> ['55K_EXTRA_27'],
		'55k_note_28'	=> ['55K_EXTRA_28'],
		'55k_note_29'	=> ['55K_EXTRA_29'],
		'55k_note_30'	=> ['55K_EXTRA_30'],
		'55k_note_31'	=> ['55K_EXTRA_31'],
		'55k_note_32'	=> ['55K_EXTRA_32'],
		'55k_note_33'	=> ['55K_EXTRA_33'],
		'55k_note_34'	=> ['55K_EXTRA_34'],
		'55k_note_35'	=> ['55K_EXTRA_35'],
		'55k_note_36'	=> ['55K_EXTRA_36'],
		'55k_note_37'	=> ['55K_EXTRA_37'],
		'55k_note_38'	=> ['55K_EXTRA_38'],
		'55k_note_39'	=> ['55K_EXTRA_39'],
		'55k_note_40'	=> ['55K_EXTRA_40'],
		'55k_note_41'	=> ['55K_EXTRA_41'],
		'55k_note_42'	=> ['55K_EXTRA_42'],
		'55k_note_43'	=> ['55K_EXTRA_43'],
		'55k_note_44'	=> ['55K_EXTRA_44'],
		'55k_note_45'	=> ['55K_EXTRA_45'],
		'55k_note_46'	=> ['55K_EXTRA_46'],
		'55k_note_47'	=> ['55K_EXTRA_47'],
		'55k_note_48'	=> ['55K_EXTRA_48'],
		'55k_note_49'	=> ['55K_EXTRA_49'],
		'55k_note_50'	=> ['55K_EXTRA_50'],
		'55k_note_51'	=> ['55K_EXTRA_51'],
		'55k_note_52'	=> ['55K_EXTRA_52'],
		'55k_note_53'	=> ['55K_EXTRA_53'],
		'55k_note_54'	=> ['55K_EXTRA_54'],
		'55k_note_55'	=> ['55K_EXTRA_55'],

		'ui_up'			=> ['UP'],
		'ui_left'			=> ['LEFT'],
		'ui_down'		=> ['DOWN'],
		'ui_right'		=> ['RIGHT'],

		'accept'		=> ['A'],
		'back'			=> ['B'],
		'pause'			=> ['P'],
		'reset'			=> ['NONE'],
		'taunt'			=> ['T']
	];
	public static var defaultMobileBinds:Map<String, Array<String>> = null;
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

	/* Mobile Controls */
	/* Bool Options */
	public var disableOnlineShaders:Bool = false;
	public var hitboxHint:Bool = false;
	public var ogGameControls:Bool = false; //There we go

	/* Int/Float Options */
	public var extraKeys:Int = 0;
	public var hitboxAlpha:Float = #if mobile 0.7 #else 0 #end;
	public var mobilePadAlpha:Float = #if mobile 0.6 #else 0 #end;

	/* String Options */
	public var hitboxType:String = 'Gradient';
	public var hitboxLocation:String = 'Bottom';
	public var hitboxMode:String = 'Normal (New)';
	public var mobileExtraKeyReturns:Array<String> = ['SHIFT', 'SPACE', 'Q', 'E'];

	//P.E.T variables
	public var menuTheme:String = 'V2.5';
	public var petwatermark:Bool = true;
	public var petloadingscreen:Bool = true;
	public var petwatermarklogo:String = 'ONLINE';
	public var petloadingscreenimage:String = 'ONLINE';
	public var disableIntroVideo:Bool = false;

	public var arrowRGB:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]];
	public var arrowRGBPixel:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]];

	public var ghostTapping:Bool = true;
	public var timeBarType:String = 'Time Left';
	public var scoreZoom:Bool = true;
	public var noReset:Bool = false;
	public var healthBarAlpha:Float = 1;
	public var hitsoundVolume:Float = 0;
	public var pauseMusic:String = 'Tea Time';
	public var checkForUpdates:Bool = true;
	public var comboStacking:Bool = true;
	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative', 
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		// -kade
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];

	public var comboOffset:Array<Int> = [0, 0, 0, 0];
	public var favoriteSongs:Array<String> = [];
	public var favSongs:Array<String> = []; // songName-folder format
	public var ratingOffset:Int = 0;
	public var sickWindow:Float = 45.0;
	public var goodWindow:Float = 90.0;
	public var badWindow:Float = 135.0;
	public var safeFrames:Float = 10.0;
	public var guitarHeroSustains:Bool = true;
	public var discordRPC:Bool = true;
	public var loadingScreen:Bool = true;
	public var language:String = 'en-US';
	
	public var importSaveFile:String = '';
}

class ClientPrefs {
	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};

	//Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		//Key Bind, Name for ControlsSubState
		'note_up'		=> [W, UP],
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_right'	=> [D, RIGHT],
		
		'ui_up'			=> [W, UP],
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_right'		=> [D, RIGHT],
		
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R],
		
		'volume_mute'	=> [ZERO],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN],
		'debug_2'		=> [EIGHT]
	];
	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'note_up'		=> [DPAD_UP, Y],
		'note_left'		=> [DPAD_LEFT, X],
		'note_down'		=> [DPAD_DOWN, A],
		'note_right'	=> [DPAD_RIGHT, B],
		
		'ui_up'			=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left'		=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'		=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right'		=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		
		'accept'		=> [A, START],
		'back'			=> [B],
		'pause'			=> [START],
		'reset'			=> [BACK]
	];
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

	public static function resetKeys(controller:Null<Bool> = null) //Null = both, False = Keyboard, True = Controller
	{
		if(controller != true)
			for (key in keyBinds.keys())
				if(defaultKeys.exists(key))
					keyBinds.set(key, defaultKeys.get(key).copy());

		if(controller != false)
			for (button in gamepadBinds.keys())
				if(defaultButtons.exists(button))
					gamepadBinds.set(button, defaultButtons.get(button).copy());
	}
	public static function isDebug() {
		#if debug
		return true;
		#end

		if (PlayState.chartingMode)
			return true;
		
		return data?.debugMode ?? false;
	}

	public static function clearInvalidKeys(key:String)
	{
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		var gamepadBind:Array<FlxGamepadInputID> = gamepadBinds.get(key);
		while(keyBind != null && keyBind.contains(NONE)) keyBind.remove(NONE);
		while(gamepadBind != null && gamepadBind.contains(NONE)) gamepadBind.remove(NONE);
	}

	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
		defaultButtons = gamepadBinds.copy();
	}

	public static function saveSettings() {
		for (key in Reflect.fields(data))
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));

		#if ACHIEVEMENTS_ALLOWED Achievements.save(); #end
		FlxG.save.flush();

		//Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());
		save.data.keyboard = keyBinds;
		save.data.gamepad = gamepadBinds;
		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() {
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

		for (key in Reflect.fields(data))
			if (key != 'gameplaySettings' && Reflect.hasField(FlxG.save.data, key))
				Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));
		
		if(Main.fpsVar != null)
			Main.fpsVar.visible = data.showFPS;

		#if (!html5 && !switch)
		FlxG.autoPause = ClientPrefs.data.autoPause;

		if(FlxG.save.data.framerate == null) {
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.framerate = Std.int(FlxMath.bound(refreshRate, 60, 240));
		}
		#end

		if(data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = data.framerate;
			FlxG.drawFramerate = data.framerate;
		}
		else
		{
			FlxG.drawFramerate = data.framerate;
			FlxG.updateFramerate = data.framerate;
		}

		if(FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
				data.gameplaySettings.set(name, value);
		}
		
		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;

		#if DISCORD_ALLOWED DiscordClient.check(); #end

		// controls on a separate save file
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());
		if(save != null)
		{
			if(save.data.keyboard != null)
			{
				var loadedControls:Map<String, Array<FlxKey>> = save.data.keyboard;
				for (control => keys in loadedControls)
					if(keyBinds.exists(control)) keyBinds.set(control, keys);
			}
			if(save.data.gamepad != null)
			{
				var loadedControls:Map<String, Array<FlxGamepadInputID>> = save.data.gamepad;
				for (control => keys in loadedControls)
					if(gamepadBinds.exists(control)) gamepadBinds.set(control, keys);
			}
			reloadVolumeKeys();
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
	{
		if(!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
		return /*PlayState.isStoryMode ? defaultValue : */ (data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadVolumeKeys()
	{
		TitleState.muteKeys = keyBinds.get('volume_mute').copy();
		TitleState.volumeDownKeys = keyBinds.get('volume_down').copy();
		TitleState.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}
	public static function toggleVolumeKeys(?turnOn:Bool = true)
	{
		final emptyArray = [];
		FlxG.sound.muteKeys = turnOn ? TitleState.muteKeys : emptyArray;
		FlxG.sound.volumeDownKeys = turnOn ? TitleState.volumeDownKeys : emptyArray;
		FlxG.sound.volumeUpKeys = turnOn ? TitleState.volumeUpKeys : emptyArray;
	}
}
