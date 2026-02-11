package states;

import backend.WeekData;
import backend.Mods;

import flixel.FlxBasic;
import flixel.graphics.FlxGraphic;
import flash.geom.Rectangle;
import haxe.Json;

import flixel.util.FlxSpriteUtil;
import objects.AttachedSprite;
import objects.Alphabet; 
import options.ModSettingsSubState;

import openfl.display.BitmapData;
import lime.utils.Assets;

import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class ModsMenuState extends MusicBeatState
{
	var bg:FlxSprite;
	var icon:FlxSprite;
	var modName:Alphabet;
	var modDesc:FlxText;
	var modRestartText:FlxText;
	var modsList:ModsList = null;

	// MODERN UI: Sidebar Elementleri
	var sideBarBG:FlxSprite;
	var sideBarWidth:Int = 450;

	var buttonReload:MenuButton;
	var buttonEnableAll:MenuButton;
	var buttonDisableAll:MenuButton;
	var buttons:Array<MenuButton> = [];
	var settingsButton:MenuButton;
	
	var bgButtons:FlxSprite;

	var modsGroup:FlxTypedGroup<ModItem>;
	var curSelectedMod:Int = 0;
	
	var hoveringOnMods:Bool = true;
	var curSelectedButton:Int = 0;
	///-1 = Enable/Disable All, -2 = Reload
	
	var noModsSine:Float = 0;
	var noModsTxt:FlxText;

	var _lastControllerMode:Bool = false;
	var startMod:String = null;
	
	// İkon Tween animasyonu için hedef Y pozisyonu
	var iconTargetY:Float = 0;

	public function new(startMod:String = null)
	{
		this.startMod = startMod;
		super();
	}

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		persistentUpdate = false;
		modsList = Mods.parseList();
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Mods Menu - Modernized", null);
		#end

		// 1. ARKA PLAN
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF665AFF;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		// 2. MODERN SIDEBAR
		sideBarBG = new FlxSprite(FlxG.width - sideBarWidth, 0).makeGraphic(sideBarWidth, FlxG.height, FlxColor.BLACK);
		sideBarBG.alpha = 0.7;
		add(sideBarBG);

		var separator = new FlxSprite(sideBarBG.x, 0).makeGraphic(4, FlxG.height, FlxColor.WHITE);
		separator.alpha = 0.2;
		add(separator);

		modsGroup = new FlxTypedGroup<ModItem>();

		for (i => mod in modsList.all)
		{
			if(startMod == mod) curSelectedMod = i;
			var modItem:ModItem = new ModItem(mod);
			modItem.text.fieldWidth = sideBarWidth - 110; 
			modItem.text.size = 20;

			if(modsList.disabled.contains(mod))
			{
				modItem.icon.color = 0xFFFF6666;
				modItem.text.color = FlxColor.GRAY;
			}
			modsGroup.add(modItem);
		}
		centerMod = curSelectedMod;

		var mod:ModItem = modsGroup.members[curSelectedMod];
		if(mod != null) bg.color = mod.bgColor;

		// 3. BUTONLAR (ÜST KISIM)
		var buttonWidth = 180;
		var buttonHeight = 60;
		var topButtonY = 20;

		// Reload Butonu
		buttonReload = new MenuButton(sideBarBG.x + 20, topButtonY, buttonWidth, buttonHeight, "YENİDEN YÜKLE", reload);
		buttonReload.bg.color = FlxColor.BLUE;
		buttonReload.bg.alpha = 0.8;
		add(buttonReload);

		// Enable/Disable All
		var enDisX = sideBarBG.x + sideBarWidth - buttonWidth - 20;
		
		buttonEnableAll = new MenuButton(enDisX, topButtonY, buttonWidth, buttonHeight, "HEPSINI AÇ", function() {
			for (mod in modsGroup.members)
			{
				if(modsList.disabled.contains(mod.folder))
				{
					modsList.disabled.remove(mod.folder);
					modsList.enabled.push(mod.folder);
					mod.icon.color = FlxColor.WHITE;
					mod.text.color = FlxColor.WHITE;
				}
			}
			updateModDisplayData();
			checkToggleButtons(); // Buton durumlarını güncelle
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		});
		buttonEnableAll.bg.color = FlxColor.GREEN;
		add(buttonEnableAll);

		buttonDisableAll = new MenuButton(enDisX, topButtonY, buttonWidth, buttonHeight, "HEPSINI KAPA", function() {
			// FIX: Enable/Disable mantığı düzeltildi
			for (mod in modsGroup.members)
			{
				if(modsList.enabled.contains(mod.folder))
				{
					modsList.enabled.remove(mod.folder);
					modsList.disabled.push(mod.folder);
					mod.icon.color = 0xFFFF6666;
					mod.text.color = FlxColor.GRAY;
				}
			}
			updateModDisplayData();
			checkToggleButtons();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		});
		buttonDisableAll.bg.color = 0xFFFF6666;
		add(buttonDisableAll);
		
		checkToggleButtons();

		if(modsList.all.length < 1)
		{
			buttonDisableAll.visible = buttonDisableAll.enabled = false;
			buttonEnableAll.visible = true;
			noModsTxt = new FlxText(0, 0, FlxG.width, Language.getPhrase('no_mods_installed', 'MOD YÜKLENMEDİ\nÇIKMAK İÇİN GERİ TUŞUNA BASIN'), 48);
			noModsTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			noModsTxt.screenCenter();
			add(noModsTxt);
			noModsTxt.x = -175;
			FlxG.autoPause = false;
			changeSelectedMod();
			return super.create();
		}

		// 4. SOL TARAF - SHOWCASE
		icon = new FlxSprite(0, 0);
		icon.antialiasing = ClientPrefs.data.antialiasing;
		add(icon);

		modName = new Alphabet(50, 50, "", true);
		add(modName);

		modDesc = new FlxText(50, FlxG.height - 200, sideBarBG.x - 100, "", 24);
		modDesc.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		modDesc.borderSize = 2;
		add(modDesc);

		modRestartText = new FlxText(50, FlxG.height - 50, sideBarBG.x - 100, "* YENİDEN BAŞLATMA GEREKLİ", 20);
		modRestartText.setFormat(Paths.font("vcr.ttf"), 20, 0xFFFF4444, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		modRestartText.borderSize = 1.5;
		add(modRestartText);

		// 5. KONTROL BUTONLARI (DOCK)
		var dockHeight = 100;
		bgButtons = new FlxSprite(sideBarBG.x, FlxG.height - dockHeight).makeGraphic(sideBarWidth, dockHeight, FlxColor.BLACK);
		bgButtons.alpha = 0.5;
		add(bgButtons);

		var buttonsX = sideBarBG.x + 25;
		var buttonsY = FlxG.height - 85;
		var btnSize = 70;
		var gap = 15;

		// En Üste Taşı
		var button = new MenuButton(buttonsX, buttonsY, btnSize, btnSize, Paths.image('modsMenuButtons'), function() moveModToPosition(0), 54, 54);
		button.icon.animation.add('icon', [0]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);
		
		// Yukarı Taşı
		button = new MenuButton(buttonsX + (btnSize + gap), buttonsY, btnSize, btnSize, Paths.image('modsMenuButtons'), function() moveModToPosition(curSelectedMod - 1), 54, 54);
		button.icon.animation.add('icon', [1]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);
		
		// Aşağı Taşı
		button = new MenuButton(buttonsX + (btnSize + gap) * 2, buttonsY, btnSize, btnSize, Paths.image('modsMenuButtons'), function() moveModToPosition(curSelectedMod + 1), 54, 54);
		button.icon.animation.add('icon', [2]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);

		// Ayarlar
		settingsButton = new MenuButton(buttonsX + (btnSize + gap) * 3, buttonsY, btnSize, btnSize, Paths.image('modsMenuButtons'), function()
		{
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			if(curMod != null && curMod.settings != null && curMod.settings.length > 0)
			{
				openSubState(new ModSettingsSubState(curMod.settings, curMod.folder, curMod.name));
			}
		}, 54, 54);
		settingsButton.icon.animation.add('icon', [3]);
		settingsButton.icon.animation.play('icon', true);
		add(settingsButton);
		buttons.push(settingsButton);

		// Aç/Kapat
		button = new MenuButton(buttonsX + (btnSize + gap) * 4, buttonsY, btnSize, btnSize, Paths.image('modsMenuButtons'), function()
		{
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			var mod:String = curMod.folder;
			if(!modsList.disabled.contains(mod)) //Enable
			{
				modsList.enabled.remove(mod);
				modsList.disabled.push(mod);
			}
			else //Disable
			{
				modsList.disabled.remove(mod);
				modsList.enabled.push(mod);
			}
			curMod.icon.color = modsList.disabled.contains(mod) ? 0xFFFF6666 : FlxColor.WHITE;
			curMod.text.color = modsList.disabled.contains(mod) ? FlxColor.GRAY : FlxColor.WHITE;

			if(curMod.mustRestart) waitingToRestart = true;
			updateModDisplayData();
			checkToggleButtons();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}, 54, 54);
		button.icon.animation.add('icon', [4]);
		button.icon.animation.play('icon', true);
		add(button);
		buttons.push(button);
		
		button.focusChangeCallback = function(focus:Bool) {
			if(!focus)
				button.bg.color = modsList.enabled.contains(modsGroup.members[curSelectedMod].folder) ? FlxColor.GREEN : 0xFFFF6666;
		};

		if(modsList.all.length < 2)
		{
			buttons[0].enabled = false;
			buttons[1].enabled = false;
			buttons[2].enabled = false;
		}

		if(modsList.all.length < 1)
		{
			for (btn in buttons) btn.enabled = false;
			button.focusChangeCallback = null;
		}
		
		add(modsGroup);
		_lastControllerMode = controls.controllerMode;

		changeSelectedMod();
		super.create();
	}
	
	var nextAttempt:Float = 1;
	var holdingMod:Bool = false;
	var mouseOffsets:FlxPoint = new FlxPoint();
	var holdingElapsed:Float = 0;
	var gottaClickAgain:Bool = false;
	var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		if(controls.BACK && hoveringOnMods)
		{
			saveTxt();
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(waitingToRestart)
			{
				TitleState.initialized = false;
				TitleState.closedState = false;
				FlxG.sound.music.fadeOut(0.3);
				if(FreeplayState.vocals != null)
				{
					FreeplayState.vocals.fadeOut(0.3);
					FreeplayState.vocals = null;
				}
				FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
			}
			else MusicBeatState.switchState(new MainMenuState());
			persistentUpdate = false;
			FlxG.autoPause = ClientPrefs.data.autoPause;
			FlxG.mouse.visible = false;
			return;
		}

		if(Math.abs(FlxG.mouse.deltaX) > 10 || Math.abs(FlxG.mouse.deltaY) > 10)
		{
			controls.controllerMode = false;
			if(!FlxG.mouse.visible) FlxG.mouse.visible = true;
		}
		
		if(controls.controllerMode != _lastControllerMode)
		{
			if(controls.controllerMode) FlxG.mouse.visible = false;
			_lastControllerMode = controls.controllerMode;
		}

		if(controls.UI_DOWN_R || controls.UI_UP_R) holdTime = 0;
		if(modsList.all.length > 0)
		{
			if(controls.controllerMode && holdingMod)
			{
				holdingMod = false;
				holdingElapsed = 0;
				updateItemPositions();
			}

			var lastMode = hoveringOnMods;
			if(modsList.all.length > 1)
			{
				if(FlxG.mouse.justPressed)
				{
					for (i in centerMod-4...centerMod+5)
					{
						if (i < 0 || i >= modsGroup.members.length) continue;
						var mod = modsGroup.members[i];
						if(mod != null && mod.visible && FlxG.mouse.overlaps(mod))
						{
							hoveringOnMods = true;
							var button = getButton();
							button.ignoreCheck = button.onFocus = false;
							mouseOffsets.x = FlxG.mouse.x - mod.x;
							mouseOffsets.y = FlxG.mouse.y - mod.y;
							// Mouse tıklamasında tween yönü hesaplama
							var direction = (i > curSelectedMod) ? 1 : -1;
							curSelectedMod = i;
							changeSelectedMod(direction);
							break;
						}
					}
					hoveringOnMods = true;
					var button = getButton();
					button.ignoreCheck = button.onFocus = false;
					gottaClickAgain = false;
				}

				if(hoveringOnMods)
				{
					var shiftMult:Int = (FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyPressed(LEFT_SHOULDER) || FlxG.gamepads.anyPressed(RIGHT_SHOULDER)) ? 4 : 1;
					if(controls.UI_DOWN_P)
						changeSelectedMod(shiftMult);
					else if(controls.UI_UP_P)
						changeSelectedMod(-shiftMult);
					else if(FlxG.mouse.wheel != 0)
						changeSelectedMod(-FlxG.mouse.wheel * shiftMult, true);
					else if(FlxG.keys.justPressed.HOME || FlxG.keys.justPressed.END)
					{
						if(FlxG.keys.justPressed.END) curSelectedMod = modsList.all.length-1;
						else curSelectedMod = 0;
						changeSelectedMod();
					}
					else if(controls.UI_UP || controls.UI_DOWN)
					{
						var lastHoldTime:Float = holdTime;
						holdTime += elapsed;
						if(holdTime > 0.5 && Math.floor(lastHoldTime * 8) != Math.floor(holdTime * 8)) changeSelectedMod(shiftMult * (controls.UI_UP ? -1 : 1));
					}
					else if(FlxG.mouse.pressed && !gottaClickAgain)
					{
						var curMod:ModItem = modsGroup.members[curSelectedMod];
						if(curMod != null)
						{
							if(!holdingMod && FlxG.mouse.justMoved && FlxG.mouse.overlaps(curMod)) holdingMod = true;
							if(holdingMod)
							{
								var moved:Bool = false;
								for (i in centerMod-4...centerMod+5)
								{
									if (i < 0 || i >= modsGroup.members.length) continue;
									var mod = modsGroup.members[i];
									if(mod != null && mod.visible && FlxG.mouse.overlaps(mod) && curSelectedMod != i)
									{
										moveModToPosition(i);
										moved = true;
										break;
									}
								}
								
								if(!moved)
								{
									var topLimit = 100;
									var botLimit = FlxG.height - 100;
									var factor:Float = -1;
									if(FlxG.mouse.y < topLimit) factor = Math.abs(Math.max(0.2, Math.min(0.5, 0.5 - (topLimit - FlxG.mouse.y) / 100)));
									else if(FlxG.mouse.y > botLimit) factor = Math.abs(Math.max(0.2, Math.min(0.5, 0.5 - (FlxG.mouse.y - botLimit) / 100)));

									if(factor >= 0)
									{
										holdingElapsed += elapsed;
										if(holdingElapsed >= factor)
										{
											holdingElapsed = 0;
											var newPos = curSelectedMod;
											if(FlxG.mouse.y < topLimit) newPos--;
											else newPos++;
											moveModToPosition(Std.int(Math.max(0, Math.min(modsGroup.length - 1, newPos))));
										}
									}
								}
								curMod.x = FlxG.mouse.x - mouseOffsets.x;
								curMod.y = FlxG.mouse.y - mouseOffsets.y;
							}
						}
					}
					else if(FlxG.mouse.justReleased && holdingMod)
					{
						holdingMod = false;
						holdingElapsed = 0;
						updateItemPositions();
					}
				}
			}

			if(lastMode == hoveringOnMods)
			{
				if(hoveringOnMods)
				{
					if(controls.UI_RIGHT_P)
					{
						hoveringOnMods = false;
						var button = getButton();
						button.ignoreCheck = button.onFocus = false;
						curSelectedButton = 0;
						changeSelectedButton();
					}
				}
				else 
				{
					if(controls.BACK)
					{
						hoveringOnMods = true;
						var button = getButton();
						button.ignoreCheck = button.onFocus = false;
						changeSelectedMod();
					}
					else if(controls.ACCEPT)
					{
						var button = getButton();
						if(button.onClick != null) button.onClick();
					}
					else if(curSelectedButton < 0)
					{
						if(controls.UI_UP_P)
						{
							switch(curSelectedButton)
							{
								case -2:
									curSelectedMod = 0;
									hoveringOnMods = true;
									var button = getButton();
									button.ignoreCheck = button.onFocus = false;
									changeSelectedMod();
								case -1:
									changeSelectedButton(-1);
							}
						}
						else if(controls.UI_DOWN_P)
						{
							switch(curSelectedButton)
							{
								case -2:
									changeSelectedButton(1);
								case -1:
									curSelectedMod = 0;
									hoveringOnMods = true;
									var button = getButton();
									button.ignoreCheck = button.onFocus = false;
									changeSelectedMod();
							}
						}
						else if(controls.UI_RIGHT_P)
						{
							var button = getButton();
							button.ignoreCheck = button.onFocus = false;
							curSelectedButton = 0;
							changeSelectedButton();
						}
					}
					else if(controls.UI_LEFT_P) changeSelectedButton(-1);
					else if(controls.UI_RIGHT_P) changeSelectedButton(1);
				}
			}
		}
		else
		{
			noModsSine += 180 * elapsed;
			noModsTxt.alpha = 1 - Math.sin((Math.PI * noModsSine) / 180);
			nextAttempt -= elapsed;
			if(nextAttempt < 0)
			{
				nextAttempt = 1;
				@:privateAccess
				Mods.updateModList();
				modsList = Mods.parseList();
				if(modsList.all.length > 0) reload();
			}
		}
		super.update(elapsed);
	}

	function changeSelectedButton(add:Int = 0)
	{
		var max = buttons.length - 1;
		var button = getButton();
		button.ignoreCheck = button.onFocus = false;
		curSelectedButton += add;
		if(curSelectedButton < -2) curSelectedButton = -2;
		else if(curSelectedButton > max) curSelectedButton = max;

		var button = getButton();
		button.ignoreCheck = button.onFocus = true;

		var curMod:ModItem = modsGroup.members[curSelectedMod];
		if(curMod != null) curMod.selectBg.visible = false;
		
		if(curSelectedButton < 0) bgButtons.alpha = 0.5;
		else bgButtons.alpha = 0.8;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function getButton()
	{
		switch(curSelectedButton)
		{
			case -2: return buttonReload;
			case -1: return buttonEnableAll.enabled ? buttonEnableAll : buttonDisableAll;
		}

		if(modsList.all.length < 1) return buttonReload;
		return buttons[Std.int(Math.max(0, Math.min(buttons.length-1, curSelectedButton)))];
	}

	function changeSelectedMod(add:Int = 0, isMouseWheel:Bool = false)
	{
		var max = modsList.all.length - 1;
		if(max < 0) return;

		if(hoveringOnMods)
		{
			var button = getButton();
			button.ignoreCheck = button.onFocus = false;
		}

		var lastSelected = curSelectedMod;
		curSelectedMod += add;
		var limited:Bool = false;
		if(curSelectedMod < 0) { curSelectedMod = 0; limited = true; }
		else if(curSelectedMod > max) { curSelectedMod = max; limited = true; }
		
		holdingMod = false;
		holdingElapsed = 0;
		gottaClickAgain = true;
		
		updateModDisplayData();
		
		// YENİ: ICON TWEEN ANIMASYONU
		// Eğer "add" 0 değilse (yani bir hareket varsa) tween uygula
		if (add != 0) 
		{
			FlxTween.cancelTweensOf(icon);
			// Aşağı basıldıysa (add > 0), ikon alttan gelsin (+50), yukarı ise üstten (-50)
			var startOffsetY = (add > 0) ? 50 : -50;
			
			icon.y = iconTargetY + startOffsetY;
			icon.alpha = 0;
			
			FlxTween.tween(icon, {y: iconTargetY, alpha: 1}, 0.35, {ease: FlxEase.quartOut});
		}
		else
		{
			// Hareket yoksa (ilk açılış gibi) direkt yerine koy
			icon.y = iconTargetY;
			icon.alpha = 1;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		if(hoveringOnMods)
		{
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			if(curMod != null) curMod.selectBg.visible = true;
		}
	}

	function updateModDisplayData()
	{
		var curMod:ModItem = modsGroup.members[curSelectedMod];
		if(curMod == null) return;

		FlxTween.cancelTweensOf(bg);
		FlxTween.color(bg, 0.6, bg.color, curMod.bgColor);

		if(Math.abs(centerMod - curSelectedMod) > 2)
		{
			if(centerMod < curSelectedMod) centerMod = curSelectedMod - 2;
			else centerMod = curSelectedMod + 2;
		}
		updateItemPositions();

		icon.loadGraphic(curMod.icon.graphic, true, 150, 150);
		icon.antialiasing = curMod.icon.antialiasing;
		
		if(curMod.totalFrames > 0)
		{
			icon.animation.add("icon", [for (i in 0...curMod.totalFrames) i], curMod.iconFps);
			icon.animation.play("icon");
			icon.animation.curAnim.curFrame = curMod.icon.animation.curAnim.curFrame;
		}

		var leftSpaceCenter = (FlxG.width - sideBarWidth) / 2;
		icon.scale.set(2, 2);
		icon.updateHitbox();
		
		// Hedef Y pozisyonunu hesapla ve değişkene ata (Tween için kullanılacak)
		iconTargetY = (FlxG.height / 2) - icon.height/2 - 50;
		// X pozisyonunu hemen ayarla
		icon.x = leftSpaceCenter - icon.width/2;
		
		// Eğer bu fonksiyon bir hareket (changeSelectedMod) dışından çağırıldıysa (örn: mouse ile sürükleme)
		// Icon yerini güncelle
		if (holdingMod) icon.y = iconTargetY;

		modName.text = curMod.name;
		modName.setPosition(50, 50);
		if (modName.width > sideBarBG.x - 60) modName.scaleX = (sideBarBG.x - 60) / modName.width;
		else modName.scaleX = 1;

		modRestartText.visible = curMod.mustRestart;
		modDesc.text = curMod.desc;

		for (button in buttons) if(button.focusChangeCallback != null) button.focusChangeCallback(button.onFocus);
		settingsButton.enabled = (curMod.settings != null && curMod.settings.length > 0);
	}

	var centerMod:Int = 3;
	function updateItemPositions()
	{
		var maxVisible = centerMod + 5;
		var minVisible = centerMod - 5; 

		for (i => mod in modsGroup.members)
		{
			if(mod == null) continue;

			mod.visible = (i >= minVisible && i <= maxVisible);
			mod.x = sideBarBG.x + 20;
			
			var centerScreenY = FlxG.height / 2;
			mod.y = centerScreenY + ((i - centerMod) * 90);
			
			mod.alpha = 0.6;
			if(i == curSelectedMod) 
			{
				mod.alpha = 1;
				mod.x += 10;
			}
			mod.selectBg.visible = (i == curSelectedMod && hoveringOnMods);
		}
	}

	var waitingToRestart:Bool = false;
	function moveModToPosition(?mod:String = null, position:Int = 0)
	{
		if(mod == null) mod = modsList.all[curSelectedMod];
		if(position >= modsList.all.length) position = 0;
		else if(position < 0) position = modsList.all.length-1;

		var id:Int = modsList.all.indexOf(mod);
		if(position == id) return;

		var curMod:ModItem = modsGroup.members[id];
		if(curMod == null) return;

		if(curMod.mustRestart || modsGroup.members[position].mustRestart) waitingToRestart = true;

		modsGroup.remove(curMod, true);
		modsList.all.remove(mod);
		modsGroup.insert(position, curMod);
		modsList.all.insert(position, mod);

		curSelectedMod = position;
		centerMod = curSelectedMod; // Listeyi takip et
		updateModDisplayData();
		updateItemPositions();
		
		if(!hoveringOnMods)
		{
			var curMod:ModItem = modsGroup.members[curSelectedMod];
			if(curMod != null) curMod.selectBg.visible = false;
		}
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function checkToggleButtons()
	{
		buttonEnableAll.visible = buttonEnableAll.enabled = (modsList.disabled.length > 0);
		buttonDisableAll.visible = buttonDisableAll.enabled = !buttonEnableAll.visible;
		// Butonların görünürlüğü değiştiğinde alpha değerlerini de resetleyelim
		buttonEnableAll.alpha = buttonEnableAll.visible ? 1 : 0;
		buttonDisableAll.alpha = buttonDisableAll.visible ? 1 : 0;
	}

	function reload()
	{
		saveTxt();
		FlxG.autoPause = ClientPrefs.data.autoPause;
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		var curMod:ModItem = modsGroup.members[curSelectedMod];
		MusicBeatState.switchState(new ModsMenuState(curMod != null ? curMod.folder : null));
	}
	
	function saveTxt()
	{
		var fileStr:String = '';
		for (mod in modsList.all)
		{
			if(mod.trim().length < 1) continue;
			if(fileStr.length > 0) fileStr += '\n';

			var on = '1';
			if(modsList.disabled.contains(mod)) on = '0';
			fileStr += '$mod|$on';
		}

		var path:String = 'modsList.txt';
		File.saveContent(path, fileStr);
		Mods.parseList();
		Mods.loadTopMod();
	}
}

class ModItem extends FlxSpriteGroup
{
	public var selectBg:FlxSprite;
	public var icon:FlxSprite;
	public var text:FlxText;
	public var totalFrames:Int = 0;

	// options
	public var name:String = 'Unknown Mod';
	public var desc:String = 'No description provided.';
	public var iconFps:Int = 10;
	public var bgColor:FlxColor = 0xFF665AFF;
	public var pack:Dynamic = null;
	public var folder:String = 'unknownMod';
	public var mustRestart:Bool = false;
	public var settings:Array<Dynamic> = null;

	public function new(folder:String)
	{
		super();

		this.folder = folder;
		pack = Mods.getPack(folder);
		var path:String = Paths.mods('$folder/data/settings.json');
		if(FileSystem.exists(path))
		{
			try
			{
				settings = tjson.TJSON.parse(File.getContent(path));
			}
			catch(e:Dynamic) {}
		}

		selectBg = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		selectBg.alpha = 0.2;
		selectBg.visible = false;
		add(selectBg);

		icon = new FlxSprite(5, 5);
		icon.antialiasing = ClientPrefs.data.antialiasing;
		add(icon);
		
		text = new FlxText(95, 38, 230, "", 16);
		text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.borderSize = 2;
		text.y -= Std.int(text.height / 2);
		add(text);

		var isPixel = false;
		var file:String = Paths.mods('$folder/pack.png');
		if (!FileSystem.exists(file))
		{
			file = Paths.mods('$folder/pack-pixel.png');
			isPixel = true;
		}
		
		var bmp:BitmapData = null;
		if (FileSystem.exists(file)) bmp = BitmapData.fromFile(file);
		else isPixel = false;

		if(FileSystem.exists(file))
		{
			icon.loadGraphic(Paths.cacheBitmap(file, bmp), true, 150, 150);
			if(isPixel) icon.antialiasing = false;
		}
		else icon.loadGraphic(Paths.image('unknownMod'), true, 150, 150);
		icon.scale.set(0.5, 0.5);
		icon.updateHitbox();
		
		this.name = folder;
		if(pack != null)
		{
			if(pack.name != null) this.name = pack.name;
			if(pack.description != null) this.desc = pack.description;
			if(pack.iconFramerate != null) this.iconFps = pack.iconFramerate;
			if(pack.color != null)
			{
				this.bgColor = FlxColor.fromRGB(pack.color[0] != null ? pack.color[0] : 170,
											  pack.color[1] != null ? pack.color[1] : 0,
											  pack.color[2] != null ? pack.color[2] : 255);
			}
			this.mustRestart = (pack.restart == true);
		}
		text.text = this.name;

		if(bmp != null)
		{
			totalFrames = Math.floor(bmp.width / 150) * Math.floor(bmp.height / 150);
			icon.animation.add("icon", [for (i in 0...totalFrames) i], iconFps);
			icon.animation.play("icon");
		}
		
		selectBg.scale.set(400, 80);
		selectBg.updateHitbox();
		icon.y = (80 - icon.height) / 2;
		text.y = (80 - text.height) / 2;
	}
}

class MenuButton extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var textOn:Alphabet;
	public var textOff:Alphabet;
	public var icon:FlxSprite;
	public var onClick:Void->Void = null;
	public var enabled(default, set):Bool = true;
	public function new(x:Float, y:Float, width:Int, height:Int, ?text:String = null, ?img:FlxGraphic = null, onClick:Void->Void = null, animWidth:Int = 0, animHeight:Int = 0)
	{
		super(x, y);
		bg = FlxSpriteUtil.drawRoundRect(new FlxSprite().makeGraphic(width, height, FlxColor.TRANSPARENT), 0, 0, width, height, 25, 25, FlxColor.WHITE);
		bg.color = FlxColor.BLACK;
		add(bg);

		if(text != null)
		{
			// FIX: Text hizalaması için manuel offset yerine dinamik hesaplama
			textOn = new Alphabet(0, 0, "", false);
			textOn.setScale(0.4);
			textOn.text = text;
			textOn.alpha = 0.8;
			textOn.visible = false;
			// Alphabet yüksekliği scale işleminden sonra güncellenmediği için manuel merkezliyoruz
			textOn.x = (width - textOn.width) / 2;
			textOn.y = (height - textOn.height) / 2; 
			add(textOn);
			
			textOff = new Alphabet(0, 0, "", true);
			textOff.setScale(0.35);
			textOff.text = text;
			textOff.alpha = 0.6;
			textOff.x = (width - textOff.width) / 2;
			textOff.y = (height - textOff.height) / 2;
			add(textOff);
		}
		else if(img != null)
		{
			icon = new FlxSprite();
			if(animWidth > 0 || animHeight > 0) icon.loadGraphic(img, true, animWidth, animHeight);
			else icon.loadGraphic(img);
			icon.x = (width - icon.width) / 2;
			icon.y = (height - icon.height) / 2;
			add(icon);
		}

		this.onClick = onClick;
		setButtonVisibility(false);
	}

	public var focusChangeCallback:Bool->Void = null;
	public var onFocus(default, set):Bool = false;
	public var ignoreCheck:Bool = false;
	private var _needACheck:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(!enabled)
		{
			onFocus = false;
			return;
		}

		if(!ignoreCheck && !Controls.instance.controllerMode && (FlxG.mouse.justPressed || FlxG.mouse.justMoved) && FlxG.mouse.visible)
			onFocus = FlxG.mouse.overlaps(this);
		
		if(onFocus && onClick != null && FlxG.mouse.justPressed)
			onClick();

		if(_needACheck)
		{
			_needACheck = false;
			if(!Controls.instance.controllerMode)
				setButtonVisibility(FlxG.mouse.overlaps(this));
		}
	}

	function set_onFocus(newValue:Bool)
	{
		var lastFocus:Bool = onFocus;
		onFocus = newValue;
		if(onFocus != lastFocus && enabled) setButtonVisibility(onFocus);
		return newValue;
	}

	function set_enabled(newValue:Bool)
	{
		enabled = newValue;
		setButtonVisibility(false);
		alpha = enabled ? 1 : 0.4;

		_needACheck = enabled;
		return newValue;
	}

	public function setButtonVisibility(focusVal:Bool)
	{
		alpha = 1;
		bg.color = focusVal ? FlxColor.WHITE : FlxColor.BLACK;
		bg.alpha = focusVal ? 0.9 : 0.6;

		var focusAlpha = focusVal ? 1 : 0.6;
		if(textOn != null && textOff != null)
		{
			textOn.alpha = textOff.alpha = focusAlpha;
			textOn.visible = focusVal;
			textOff.visible = !focusVal;
		}
		else if(icon != null)
		{
			icon.alpha = focusAlpha;
			icon.color = focusVal ? FlxColor.BLACK : FlxColor.WHITE;
		}

		if(!enabled) alpha = 0.4;
		if(focusChangeCallback != null) focusChangeCallback(focusVal);
	}
}