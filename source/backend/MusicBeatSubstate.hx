package backend;

import flixel.FlxSubState;

#if TOUCH_CONTROLS_ALLOWED
import mobile.MobileControlManager;
import mobile.MobileControlManager;
import mobile.objects.FunkinMobilePad;
import mobile.objects.FunkinHitbox;
import mobile.objects.FunkinJoyStick;
#end

class MusicBeatSubstate extends FlxSubState
{
	public static var instance:MusicBeatSubstate;

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return Controls.instance;

	#if TOUCH_CONTROLS_ALLOWED
	public var mobileManager:MobileControlManager;
	#end

	// Mobil buton fonksiyonları
	public inline function mobileButtonJustPressed(buttons:Dynamic):Bool {
		#if TOUCH_CONTROLS_ALLOWED
		return mobileManager != null && mobileManager.mobilePad != null && mobileManager.mobilePad.justPressed(buttons);
		#else
		return false;
		#end
	}

	public inline function mobileButtonPressed(buttons:Dynamic):Bool {
		#if TOUCH_CONTROLS_ALLOWED
		return mobileManager != null && mobileManager.mobilePad != null && mobileManager.mobilePad.pressed(buttons);
		#else
		return false;
		#end
	}

	public inline function mobileButtonJustReleased(buttons:Dynamic):Bool {
		#if TOUCH_CONTROLS_ALLOWED
		return mobileManager != null && mobileManager.mobilePad != null && mobileManager.mobilePad.justReleased(buttons);
		#else
		return false;
		#end
	}

	public inline function mobileButtonReleased(buttons:Dynamic):Bool {
		#if TOUCH_CONTROLS_ALLOWED
		return mobileManager != null && mobileManager.mobilePad != null && mobileManager.mobilePad.released(buttons);
		#else
		return false;
		#end
	}

	public function new()
	{
		super();
		instance = this;
		#if TOUCH_CONTROLS_ALLOWED
		mobileManager = new MobileControlManager(this);
		#end
	}

	override function destroy()
	{
		#if TOUCH_CONTROLS_ALLOWED
		if (mobileManager != null) {
			mobileManager.destroy();
			mobileManager = null;
		}
		#end
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		if(!persistentUpdate) MusicBeatState.timePassedOnState += elapsed;
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// Override in subclasses
	}
	
	public function sectionHit():Void
	{
		// Override in subclasses
	}
	
	function getBeatsOnSection():Float
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) 
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}