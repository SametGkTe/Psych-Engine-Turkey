package mobile.objects;

import mobile.Hitbox;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;
import flixel.util.FlxColor;
import objects.Note;

class FunkinHitbox extends Hitbox {
	public var currentMode:String;
	public var showHints:Bool;

	// Static hitbox positions (PlayState'te yoksa burada tanımla)
	public static var defaultHitboxPositions:Array<Float> = [0, 140, 280, 420, 560, 700, 840, 980, 1120];

	public function new(?mode:String, ?showHints:Bool, ?globalAlpha:Float = 0.7):Void
	{
		super(mode, globalAlpha, false);
		currentMode = mode;
		this.showHints = showHints != null ? showHints : true;

		if (mode == 'V Slice')
		{
			var mania:Int = getManiaKeys();
			var positions = getHitboxPositions(mania);
			
			if (mania == 4) {
				addHint('buttonNote1', ["NOTE_LEFT"], 0, positions[0], 0, 140, Std.int(FlxG.height), 0xFFC24B99);
				addHint('buttonNote2', ["NOTE_DOWN"], 1, positions[1], 0, 140, Std.int(FlxG.height), 0xFF00FFFF);
				addHint('buttonNote3', ["NOTE_UP"], 2, positions[2], 0, 140, Std.int(FlxG.height), 0xFF12FA05);
				addHint('buttonNote4', ["NOTE_RIGHT"], 3, positions[3], 0, 140, Std.int(FlxG.height), 0xFFF9393F);
			} else {
				for (i in 0...mania + 1) {
					addHint('buttonNote${i+1}', ['${mania}K_NOTE_${i+1}'], i, positions[i], 0, 110, Std.int(FlxG.height), 0xFFFFFFFF);
				}
			}
		}
		else
		{
			var Custom:String = mode != null ? mode : getHitboxType();
			var mania:Int = getManiaKeys();
			var maniaHitbox:String = 'Mania ${mania}';
			
			trace('maniaHitbox: $maniaHitbox');
			
			if (MobileConfig.hitboxModes.exists(maniaHitbox) && mania != 4) {
				trace('maniaHitbox found');
				Custom = maniaHitbox;
			}

			if (!MobileConfig.hitboxModes.exists(Custom)) {
				trace('Hitbox mode not found: $Custom, using default');
				// Fallback: basit 4 tuşlu hitbox
				createDefaultHitbox();
				scrollFactor.set();
				updateTrackedButtons();
				instance = this;
				return;
			}

			var hitboxConfig = MobileConfig.hitboxModes.get(Custom);
			var currentHint = hitboxConfig.hints;
			var extraKeys:Int = getExtraKeys();
			
			if (hitboxConfig.none != null)
				currentHint = hitboxConfig.none;
			if (extraKeys == 1 && hitboxConfig.single != null)
				currentHint = hitboxConfig.single;
			if (extraKeys == 2 && hitboxConfig.double != null)
				currentHint = hitboxConfig.double;
			if (extraKeys == 3 && hitboxConfig.triple != null)
				currentHint = hitboxConfig.triple;
			if (extraKeys == 4 && hitboxConfig.quad != null)
				currentHint = hitboxConfig.quad;
			if (extraKeys != 0 && hitboxConfig.hints != null)
				currentHint = hitboxConfig.hints;

			if (currentHint == null) {
				trace('No hints found for mode: $Custom');
				createDefaultHitbox();
				scrollFactor.set();
				updateTrackedButtons();
				instance = this;
				return;
			}

			for (buttonData in currentHint)
			{
				var buttonName:String = buttonData.button;
				var buttonIDs:Array<String> = buttonData.buttonIDs;
				var buttonUniqueID:Int = buttonData.buttonUniqueID != null ? buttonData.buttonUniqueID : -1;
				var buttonX:Float = buttonData.x;
				var buttonY:Float = buttonData.y;
				var buttonWidth:Int = buttonData.width;
				var buttonHeight:Int = buttonData.height;
				var buttonColor = buttonData.color;
				var buttonReturn = buttonData.returnKey;
				var location = getHitboxLocation();
				var addButton:Bool = false;

				switch (location) {
					case 'Top':
						if (buttonData.topX != null) buttonX = buttonData.topX;
						if (buttonData.topY != null) buttonY = buttonData.topY;
						if (buttonData.topWidth != null) buttonWidth = buttonData.topWidth;
						if (buttonData.topHeight != null) buttonHeight = buttonData.topHeight;
						if (buttonData.topColor != null) buttonColor = buttonData.topColor;
						if (buttonData.topReturnKey != null) buttonReturn = buttonData.topReturnKey;
					case 'Middle':
						if (buttonData.middleX != null) buttonX = buttonData.middleX;
						if (buttonData.middleY != null) buttonY = buttonData.middleY;
						if (buttonData.middleWidth != null) buttonWidth = buttonData.middleWidth;
						if (buttonData.middleHeight != null) buttonHeight = buttonData.middleHeight;
						if (buttonData.middleColor != null) buttonColor = buttonData.middleColor;
						if (buttonData.middleReturnKey != null) buttonReturn = buttonData.middleReturnKey;
					case 'Bottom':
						if (buttonData.bottomX != null) buttonX = buttonData.bottomX;
						if (buttonData.bottomY != null) buttonY = buttonData.bottomY;
						if (buttonData.bottomWidth != null) buttonWidth = buttonData.bottomWidth;
						if (buttonData.bottomHeight != null) buttonHeight = buttonData.bottomHeight;
						if (buttonData.bottomColor != null) buttonColor = buttonData.bottomColor;
						if (buttonData.bottomReturnKey != null) buttonReturn = buttonData.bottomReturnKey;
				}

				if (extraKeys == 0 && buttonData.extraKeyMode == 0 ||
				   extraKeys == 1 && buttonData.extraKeyMode == 1 ||
				   extraKeys == 2 && buttonData.extraKeyMode == 2 ||
				   extraKeys == 3 && buttonData.extraKeyMode == 3 ||
				   extraKeys == 4 && buttonData.extraKeyMode == 4 ||
				   buttonData.extraKeyMode == null)
				{
					addButton = true;
				}

				for (i in 1...5) {
					var buttonString = 'buttonExtra${i}';
					if (buttonData.button == buttonString && buttonReturn == null)
						buttonReturn = getExtraKeyReturn(i - 1);
				}
				
				if (addButton) {
					var color:Int = parseColor(buttonColor);
					addHint(buttonName, buttonIDs, buttonUniqueID, buttonX, buttonY, buttonWidth, buttonHeight, color, buttonReturn);
				}
			}
		}

		scrollFactor.set();
		updateTrackedButtons();
		instance = this;
	}

	// ========== HELPER FUNCTIONS ==========
	
	private function getManiaKeys():Int {
		try {
			return Note.maniaKeys;
		} catch (e:Dynamic) {
			return 4;
		}
	}

	private function getHitboxPositions(count:Int):Array<Float> {
		// PlayState'te hitboxPositions varsa kullan
		try {
			if (PlayState.hitboxPositions != null && PlayState.hitboxPositions.length >= count)
				return PlayState.hitboxPositions;
		} catch (e:Dynamic) {}
		
		// Yoksa hesapla
		var positions:Array<Float> = [];
		var buttonWidth:Float = FlxG.width / count;
		for (i in 0...count) {
			positions.push(i * buttonWidth);
		}
		return positions;
	}

	private function getHitboxType():String {
		try {
			if (ClientPrefs.data.hitboxType != null)
				return ClientPrefs.data.hitboxType;
		} catch (e:Dynamic) {}
		return "default";
	}

	private function getHitboxLocation():String {
		try {
			if (ClientPrefs.data.hitboxLocation != null)
				return ClientPrefs.data.hitboxLocation;
		} catch (e:Dynamic) {}
		return "Bottom";
	}

	private function getExtraKeys():Int {
		try {
			if (ClientPrefs.data.extraKeys > 0)
				return ClientPrefs.data.extraKeys;
		} catch (e:Dynamic) {}
		return 0;
	}

	private function getExtraKeyReturn(index:Int):String {
		try {
			if (ClientPrefs.data.mobileExtraKeyReturns != null && ClientPrefs.data.mobileExtraKeyReturns.length > index)
				return ClientPrefs.data.mobileExtraKeyReturns[index];
		} catch (e:Dynamic) {}
		return "NONE";
	}

	private function parseColor(colorValue:Dynamic):Int {
		if (colorValue == null) return 0xFFFFFFFF;
		
		if (Std.isOfType(colorValue, Int)) {
			return colorValue;
		}
		
		if (Std.isOfType(colorValue, String)) {
			var colorStr:String = cast colorValue;
			// Hex string kontrolü
			if (colorStr.startsWith("0x") || colorStr.startsWith("#")) {
				colorStr = colorStr.replace("#", "0x");
				var parsed = Std.parseInt(colorStr);
				return parsed != null ? parsed : 0xFFFFFFFF;
			}
			// Renk adı kontrolü
			switch (colorStr.toLowerCase()) {
				case "white": return 0xFFFFFFFF;
				case "black": return 0xFF000000;
				case "red": return 0xFFFF0000;
				case "green": return 0xFF00FF00;
				case "blue": return 0xFF0000FF;
				case "yellow": return 0xFFFFFF00;
				case "cyan": return 0xFF00FFFF;
				case "magenta": return 0xFFFF00FF;
				case "purple": return 0xFFC24B99;
				case "orange": return 0xFFFF8000;
				default: return 0xFFFFFFFF;
			}
		}
		
		return 0xFFFFFFFF;
	}

	private function createDefaultHitbox():Void {
		var buttonWidth:Int = Std.int(FlxG.width / 4);
		addHint('buttonNote1', ["NOTE_LEFT"], 0, 0, 0, buttonWidth, Std.int(FlxG.height), 0xFFC24B99);
		addHint('buttonNote2', ["NOTE_DOWN"], 1, buttonWidth, 0, buttonWidth, Std.int(FlxG.height), 0xFF00FFFF);
		addHint('buttonNote3', ["NOTE_UP"], 2, buttonWidth * 2, 0, buttonWidth, Std.int(FlxG.height), 0xFF12FA05);
		addHint('buttonNote4', ["NOTE_RIGHT"], 3, buttonWidth * 3, 0, buttonWidth, Std.int(FlxG.height), 0xFFF9393F);
	}

	// ========== GRAPHICS ==========

	override function createHintGraphic(Width:Int, Height:Int, Color:Int = 0xFFFFFF, ?isLane:Bool = false):BitmapData
	{
		var guh:Float = globalAlpha;
		var shape:Shape = new Shape();
		var hitboxType:String = getHitboxType();
		
		shape.graphics.beginFill(Color);
		
		switch (hitboxType) {
			case "No Gradient":
				var matrix:Matrix = new Matrix();
				matrix.createGradientBox(Width, Height, 0, 0, 0);
				if (isLane)
					shape.graphics.beginFill(Color);
				else
					shape.graphics.beginGradientFill(RADIAL, [Color, Color], [0, guh], [60, 255], matrix, PAD, RGB, 0);
				shape.graphics.drawRect(0, 0, Width, Height);
				shape.graphics.endFill();
			case "No Gradient (Old)":
				shape.graphics.lineStyle(10, Color, 1);
				shape.graphics.drawRect(0, 0, Width, Height);
				shape.graphics.endFill();
			default: // "Gradient" veya diğer
				shape.graphics.lineStyle(3, Color, 1);
				shape.graphics.drawRect(0, 0, Width, Height);
				shape.graphics.lineStyle(0, 0, 0);
				shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
				shape.graphics.endFill();
				if (isLane)
					shape.graphics.beginFill(Color);
				else
					shape.graphics.beginGradientFill(RADIAL, [Color, FlxColor.TRANSPARENT], [guh, 0], [0, 255], null, null, null, 0.5);
				shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
				shape.graphics.endFill();
		}

		var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape);
		return bitmap;
	}

	override public function createHint(name:Array<String>, uniqueID:Int, x:Float, y:Float, width:Int, height:Int, color:Int = 0xFFFFFF, ?returned:String):MobileButton
	{
		var hint:MobileButton = new MobileButton(x, y, returned);
		hint.loadGraphic(createHintGraphic(width, height, color));
		
		var mania:Int = getManiaKeys();
		var VSliceAllowed:Bool = (currentMode == 'V Slice' && mania < 10);

		if (showHints && !VSliceAllowed) {
			var doHeightFix:Bool = (height == 144);

			// Up Hint
			hint.hintUp = new FlxSprite();
			hint.hintUp.loadGraphic(createHintGraphic(width, Math.floor(height * (doHeightFix ? 0.060 : 0.020)), color, true));
			hint.hintUp.x = x;
			hint.hintUp.y = hint.y;

			// Down Hint
			hint.hintDown = new FlxSprite();
			hint.hintDown.loadGraphic(createHintGraphic(width, Math.floor(height * (doHeightFix ? 0.060 : 0.020)), color, true));
			hint.hintDown.x = x;
			hint.hintDown.y = hint.y + hint.height / (doHeightFix ? 1.060 : 1.020);
		}

		hint.solid = false;
		hint.immovable = true;
		hint.scrollFactor.set();
		hint.alpha = 0.00001;
		hint.IDs = name;
		hint.uniqueID = uniqueID;
		
		hint.onDown.callback = function() {
			onButtonDown?.dispatch(hint, name, uniqueID);
			if (hint.alpha != globalAlpha && !VSliceAllowed)
				hint.alpha = globalAlpha;
			if (hint.hintUp != null && hint.hintDown != null && !VSliceAllowed) {
				if (hint.hintUp.alpha != 0.00001 || hint.hintDown.alpha != 0.00001)
					hint.hintUp.alpha = hint.hintDown.alpha = 0.00001;
			}
		};
		
		hint.onOut.callback = hint.onUp.callback = function() {
			onButtonUp?.dispatch(hint, name, uniqueID);
			if (hint.alpha != 0.00001 && !VSliceAllowed)
				hint.alpha = 0.00001;
			if (hint.hintUp != null && hint.hintDown != null && !VSliceAllowed) {
				if (hint.hintUp.alpha != globalAlpha || hint.hintDown.alpha != globalAlpha)
					hint.hintUp.alpha = hint.hintDown.alpha = globalAlpha;
			}
		};
		
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		
		return hint;
	}
}