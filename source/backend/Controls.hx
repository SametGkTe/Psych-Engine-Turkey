package backend;

import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.mappings.FlxGamepadMapping;
import flixel.input.keyboard.FlxKey;

#if TOUCH_CONTROLS
import mobile.objects.FunkinHitbox;
import mobile.MobileControlManager;
#end

class Controls
{
	// Pressed buttons (directions)
	public var UI_UP_P(get, never):Bool;
	public var UI_DOWN_P(get, never):Bool;
	public var UI_LEFT_P(get, never):Bool;
	public var UI_RIGHT_P(get, never):Bool;
	public var NOTE_UP_P(get, never):Bool;
	public var NOTE_DOWN_P(get, never):Bool;
	public var NOTE_LEFT_P(get, never):Bool;
	public var NOTE_RIGHT_P(get, never):Bool;
	
	private function get_UI_UP_P() return justPressed('ui_up');
	private function get_UI_DOWN_P() return justPressed('ui_down');
	private function get_UI_LEFT_P() return justPressed('ui_left');
	private function get_UI_RIGHT_P() return justPressed('ui_right');
	private function get_NOTE_UP_P() return justPressed('note_up');
	private function get_NOTE_DOWN_P() return justPressed('note_down');
	private function get_NOTE_LEFT_P() return justPressed('note_left');
	private function get_NOTE_RIGHT_P() return justPressed('note_right');

	// Held buttons (directions)
	public var UI_UP(get, never):Bool;
	public var UI_DOWN(get, never):Bool;
	public var UI_LEFT(get, never):Bool;
	public var UI_RIGHT(get, never):Bool;
	public var NOTE_UP(get, never):Bool;
	public var NOTE_DOWN(get, never):Bool;
	public var NOTE_LEFT(get, never):Bool;
	public var NOTE_RIGHT(get, never):Bool;
	
	private function get_UI_UP() return pressed('ui_up');
	private function get_UI_DOWN() return pressed('ui_down');
	private function get_UI_LEFT() return pressed('ui_left');
	private function get_UI_RIGHT() return pressed('ui_right');
	private function get_NOTE_UP() return pressed('note_up');
	private function get_NOTE_DOWN() return pressed('note_down');
	private function get_NOTE_LEFT() return pressed('note_left');
	private function get_NOTE_RIGHT() return pressed('note_right');

	// Released buttons (directions)
	public var UI_UP_R(get, never):Bool;
	public var UI_DOWN_R(get, never):Bool;
	public var UI_LEFT_R(get, never):Bool;
	public var UI_RIGHT_R(get, never):Bool;
	public var NOTE_UP_R(get, never):Bool;
	public var NOTE_DOWN_R(get, never):Bool;
	public var NOTE_LEFT_R(get, never):Bool;
	public var NOTE_RIGHT_R(get, never):Bool;
	
	private function get_UI_UP_R() return justReleased('ui_up');
	private function get_UI_DOWN_R() return justReleased('ui_down');
	private function get_UI_LEFT_R() return justReleased('ui_left');
	private function get_UI_RIGHT_R() return justReleased('ui_right');
	private function get_NOTE_UP_R() return justReleased('note_up');
	private function get_NOTE_DOWN_R() return justReleased('note_down');
	private function get_NOTE_LEFT_R() return justReleased('note_left');
	private function get_NOTE_RIGHT_R() return justReleased('note_right');

	// Pressed buttons (others)
	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var PAUSE(get, never):Bool;
	public var RESET(get, never):Bool;
	
	private function get_ACCEPT() return justPressed('accept');
	private function get_BACK() return justPressed('back');
	private function get_PAUSE() return justPressed('pause');
	private function get_RESET() return justPressed('reset');

	// Gamepad & Keyboard & Mobile stuff
	public var keyboardBinds:Map<String, Array<FlxKey>>;
	public var gamepadBinds:Map<String, Array<FlxGamepadInputID>>;
	public var mobileBinds:Map<String, Array<String>>;
	public var controllerMode:Bool = false;

	// ========================================================
	// JUST PRESSED
	// ========================================================
	public function justPressed(key:String):Bool
	{
		var result:Bool = (FlxG.keys.anyJustPressed(keyboardBinds[key]) == true);
		if (result) controllerMode = false;

		#if TOUCH_CONTROLS
		if (mobileControls) {
			try {
				return result 
					|| _myGamepadJustPressed(gamepadBinds[key]) == true 
					|| hitboxJustPressed(mobileBinds[key]) == true 
					|| mobilePadJustPressed(mobileBinds[key]) == true 
					|| scriptedButtonJustPressed(mobileBinds[key]) == true;
			} catch (e:haxe.Exception) {
				return result || _myGamepadJustPressed(gamepadBinds[key]) == true;
			}
		}
		#end

		return result || _myGamepadJustPressed(gamepadBinds[key]) == true;
	}

	// ========================================================
	// PRESSED (HELD)
	// ========================================================
	public function pressed(key:String):Bool
	{
		var result:Bool = (FlxG.keys.anyPressed(keyboardBinds[key]) == true);
		if (result) controllerMode = false;

		#if TOUCH_CONTROLS
		if (mobileControls) {
			try {
				return result 
					|| _myGamepadPressed(gamepadBinds[key]) == true 
					|| hitboxPressed(mobileBinds[key]) == true 
					|| mobilePadPressed(mobileBinds[key]) == true 
					|| scriptedButtonPressed(mobileBinds[key]) == true;
			} catch (e:haxe.Exception) {
				return result || _myGamepadPressed(gamepadBinds[key]) == true;
			}
		}
		#end

		return result || _myGamepadPressed(gamepadBinds[key]) == true;
	}

	// ========================================================
	// JUST RELEASED
	// ========================================================
	public function justReleased(key:String):Bool
	{
		var result:Bool = (FlxG.keys.anyJustReleased(keyboardBinds[key]) == true);
		if (result) controllerMode = false;

		#if TOUCH_CONTROLS
		if (mobileControls) {
			try {
				return result 
					|| _myGamepadJustReleased(gamepadBinds[key]) == true 
					|| hitboxJustReleased(mobileBinds[key]) == true 
					|| mobilePadJustReleased(mobileBinds[key]) == true 
					|| scriptedButtonJustReleased(mobileBinds[key]) == true;
			} catch (e:haxe.Exception) {
				return result || _myGamepadJustReleased(gamepadBinds[key]) == true;
			}
		}
		#end

		return result || _myGamepadJustReleased(gamepadBinds[key]) == true;
	}

	// ========================================================
	// GAMEPAD FUNCTIONS
	// ========================================================
	private function _myGamepadJustPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if (keys != null) {
			for (key in keys) {
				if (FlxG.gamepads.anyJustPressed(key) == true) {
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}

	private function _myGamepadPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if (keys != null) {
			for (key in keys) {
				if (FlxG.gamepads.anyPressed(key) == true) {
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}

	private function _myGamepadJustReleased(keys:Array<FlxGamepadInputID>):Bool
	{
		if (keys != null) {
			for (key in keys) {
				if (FlxG.gamepads.anyJustReleased(key) == true) {
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}

	// ========================================================
	// MOBILE CONTROLS
	// ========================================================
	public var isInSubstate:Bool = false;

	#if TOUCH_CONTROLS
	public var mobileControls(get, never):Bool;

	@:noCompletion
	private function get_mobileControls():Bool
	{
		return ClientPrefs.data.mobilePadAlpha >= 0.1;
	}

	private function getRequestedInstance():Dynamic
	{
		if (isInSubstate)
			return MusicBeatSubstate.instance;
		else
			return MusicBeatState.getState();
	}

	private function getRequestedHitbox():FunkinHitbox
	{
		var instance = getRequestedInstance();
		if (instance != null && instance.mobileManager != null)
			return instance.mobileManager.hitbox;
		return null;
	}
	#else
	public var mobileControls:Bool = false;
	#end

	// ========================================================
	// MOBILE PAD FUNCTIONS
	// ========================================================
	private function mobilePadPressed(keys:Array<String>):Bool
	{
		#if TOUCH_CONTROLS
		var instance = getRequestedInstance();
		if (keys != null && instance != null && instance.mobileManager != null && instance.mobileManager.mobilePad != null) {
			if (instance.mobileManager.mobilePad.pressed(keys) == true)
				return true;
		}
		#end
		return false;
	}

	private function mobilePadJustPressed(keys:Array<String>):Bool
	{
		#if TOUCH_CONTROLS
		var instance = getRequestedInstance();
		if (keys != null && instance != null && instance.mobileManager != null && instance.mobileManager.mobilePad != null) {
			if (instance.mobileManager.mobilePad.justPressed(keys) == true)
				return true;
		}
		#end
		return false;
	}

	private function mobilePadJustReleased(keys:Array<String>):Bool
	{
		#if TOUCH_CONTROLS
		var instance = getRequestedInstance();
		if (keys != null && instance != null && instance.mobileManager != null && instance.mobileManager.mobilePad != null) {
			if (instance.mobileManager.mobilePad.justReleased(keys) == true)
				return true;
		}
		#end
		return false;
	}

	// ========================================================
	// HITBOX FUNCTIONS
	// ========================================================
	private function hitboxPressed(keys:Array<String>):Bool
	{
		#if TOUCH_CONTROLS
		var hitbox = getRequestedHitbox();
		if (keys != null && hitbox != null) {
			if (hitbox.pressed(keys) == true)
				return true;
		}
		#end
		return false;
	}

	private function hitboxJustPressed(keys:Array<String>):Bool
	{
		#if TOUCH_CONTROLS
		var hitbox = getRequestedHitbox();
		if (keys != null && hitbox != null) {
			if (hitbox.justPressed(keys) == true)
				return true;
		}
		#end
		return false;
	}

	private function hitboxJustReleased(keys:Array<String>):Bool
	{
		#if TOUCH_CONTROLS
		var hitbox = getRequestedHitbox();
		if (keys != null && hitbox != null) {
			if (hitbox.justReleased(keys) == true)
				return true;
		}
		#end
		return false;
	}

	// ========================================================
	// SCRIPTED BUTTON FUNCTIONS
	// ========================================================
	private function scriptedButtonPressed(keys:Array<String>):Bool
	{
		#if TOUCH_CONTROLS
		if (PlayState.instance != null && PlayState.instance.customManagers != null) {
			for (key => manager in PlayState.instance.customManagers) {
				if (manager[0] != null) {
					if (keys != null && manager[0].hitbox != null && manager[0].hitbox.pressed(keys) == true)
						return true;
					if (keys != null && manager[0].mobilePad != null && manager[0].mobilePad.pressed(keys) == true)
						return true;
				}
			}
		}
		#end
		return false;
	}

	private function scriptedButtonJustPressed(keys:Array<String>):Bool
	{
		#if TOUCH_CONTROLS
		if (PlayState.instance != null && PlayState.instance.customManagers != null) {
			for (key => manager in PlayState.instance.customManagers) {
				if (manager[0] != null) {
					if (keys != null && manager[0].hitbox != null && manager[0].hitbox.justPressed(keys) == true)
						return true;
					if (keys != null && manager[0].mobilePad != null && manager[0].mobilePad.justPressed(keys) == true)
						return true;
				}
			}
		}
		#end
		return false;
	}

	private function scriptedButtonJustReleased(keys:Array<String>):Bool
	{
		#if TOUCH_CONTROLS
		if (PlayState.instance != null && PlayState.instance.customManagers != null) {
			for (key => manager in PlayState.instance.customManagers) {
				if (manager[0] != null) {
					if (keys != null && manager[0].hitbox != null && manager[0].hitbox.justReleased(keys) == true)
						return true;
					if (keys != null && manager[0].mobilePad != null && manager[0].mobilePad.justReleased(keys) == true)
						return true;
				}
			}
		}
		#end
		return false;
	}
	
	public static var instance:Controls;

	public function new()
	{
		keyboardBinds = ClientPrefs.keyBinds;
		gamepadBinds = ClientPrefs.gamepadBinds;
		#if TOUCH_CONTROLS
		mobileBinds = ClientPrefs.data.mobileBinds;
		#end
	}
}