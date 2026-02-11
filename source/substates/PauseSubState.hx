package substates;

import backend.WeekData;
import backend.Highscore;
import backend.Song;
import flixel.util.FlxStringUtil;
import flixel.util.FlxGradient;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import states.StoryMenuState;
import states.FreeplayState;
import options.OptionsState;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var menuCards:FlxTypedGroup<FlxSprite>;
	var menuIcons:FlxTypedGroup<FlxSprite>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit to menu'];
	var difficultyChoices = [];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	// Modern UI Elements
	var topBar:FlxSprite;
	var bottomBar:FlxSprite;
	var sidePanel:FlxSprite;
	var bgOverlay:FlxSprite;
	var glowEffect:FlxSprite;
	var particleEmitter:FlxEmitter;
	
	var songInfoText:FlxText;
	var difficultyText:FlxText;
	var deathText:FlxText;
	var timeElapsedText:FlxText;
	var progressBar:FlxSprite;
	var progressBarBG:FlxSprite;
	
	// Turkish translations
	var menuTranslations:Map<String, String> = [
		'Resume' => 'DEVAM ET',
		'Restart Song' => 'YENİDEN BAŞLAT',
		'Change Difficulty' => 'ZORLUK DEĞİŞTİR',
		'Options' => 'AYARLAR',
		'Exit to menu' => 'MENÜYE DÖN',
		'Leave Charting Mode' => 'CHART MODUNDAN ÇIK',
		'Skip Time' => 'ZAMANI ATLA',
		'End Song' => 'ŞARKIYI BİTİR',
		'Toggle Practice Mode' => 'ALIŞTIRMA MODU',
		'Toggle Botplay' => 'BOT MODU',
		'BACK' => 'GERİ'
	];
	
	// Menu icons (emoji style)
	var menuIconMap:Map<String, String> = [
		'Resume' => '▶️',
		'Restart Song' => '🔄',
		'Change Difficulty' => '⚡',
		'Options' => '⚙️',
		'Exit to menu' => '🚪',
		'Leave Charting Mode' => '📊',
		'Skip Time' => '⏩',
		'End Song' => '⏹️',
		'Toggle Practice Mode' => '🎓',
		'Toggle Botplay' => '🤖'
	];
	
	// Animation
	var animTimer:Float = 0;
	var pulseTimer:Float = 0;

	public static var songName:String = null;

	override function create()
	{
		if(Difficulty.list.length < 2) menuItemsOG.remove('Change Difficulty');
		
		if(PlayState.chartingMode)
		{
			menuItemsOG.insert(2, 'Leave Charting Mode');
			var num:Int = 0;
			if(!PlayState.instance.startingSong)
			{
				num = 1;
				menuItemsOG.insert(3, 'Skip Time');
			}
			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		} 
		else if(PlayState.instance.practiceMode && !PlayState.instance.startingSong)
			menuItemsOG.insert(3, 'Skip Time');
			
		menuItems = menuItemsOG;

		for (i in 0...Difficulty.list.length) {
			var diff:String = Difficulty.getString(i);
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');

		pauseMusic = new FlxSound();
		try
		{
			var pauseSong:String = getPauseSong();
			if(pauseSong != null) pauseMusic.loadEmbedded(Paths.music(pauseSong), true, true);
		}
		catch(e:Dynamic) {}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		// ═══════════════════════════════════════
		// 1. ANIMATED BACKGROUND
		// ═══════════════════════════════════════
		
		bgOverlay = FlxGradient.createGradientFlxSprite(
			FlxG.width,
			FlxG.height,
			[0x00000000, 0xAA000000, 0xFF000000],
			1, 90
		);
		bgOverlay.scrollFactor.set();
		bgOverlay.alpha = 0;
		add(bgOverlay);
		
		FlxTween.tween(bgOverlay, {alpha: 1}, 0.5, {ease: FlxEase.quartOut});
		
		// Particle system
		createParticleSystem();
		
		// Center glow effect
		glowEffect = new FlxSprite(FlxG.width / 2 - 400, FlxG.height / 2 - 400);
		glowEffect.makeGraphic(800, 800, FlxColor.CYAN);
		glowEffect.blend = ADD;
		glowEffect.alpha = 0;
		glowEffect.scrollFactor.set();
		add(glowEffect);
		
		FlxTween.tween(glowEffect, {alpha: 0.08}, 0.8, {ease: FlxEase.quartOut});

		// ═══════════════════════════════════════
		// 2. TOP INFO PANEL
		// ═══════════════════════════════════════
		
		topBar = new FlxSprite(0, -150).makeGraphic(FlxG.width, 140, 0xEE000000);
		topBar.scrollFactor.set();
		add(topBar);
		
		FlxTween.tween(topBar, {y: 0}, 0.6, {ease: FlxEase.expoOut, startDelay: 0.1});
		
		// Song name
		songInfoText = new FlxText(30, 20, FlxG.width - 60, PlayState.SONG.song, 42);
		songInfoText.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF00FFFF);
		songInfoText.borderSize = 3;
		songInfoText.scrollFactor.set();
		songInfoText.alpha = 0;
		add(songInfoText);
		
		FlxTween.tween(songInfoText, {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.3});
		
		// Difficulty
		difficultyText = new FlxText(30, 70, 0, "ZORLUK: " + Difficulty.getString().toUpperCase(), 28);
		difficultyText.setFormat(Paths.font('vcr.ttf'), 28, 0xFFFFAA00, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		difficultyText.borderSize = 2;
		difficultyText.scrollFactor.set();
		difficultyText.alpha = 0;
		add(difficultyText);
		
		FlxTween.tween(difficultyText, {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.4});
		
		// Death counter
		deathText = new FlxText(30, 105, 0, "💀 ÖLÜM SAYISI: " + PlayState.deathCounter, 24);
		deathText.setFormat(Paths.font('vcr.ttf'), 24, 0xFFFF4444, LEFT);
		deathText.scrollFactor.set();
		deathText.alpha = 0;
		add(deathText);
		
		FlxTween.tween(deathText, {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.5});

		// ═══════════════════════════════════════
		// 3. BOTTOM INFO BAR
		// ═══════════════════════════════════════
		
		bottomBar = new FlxSprite(0, FlxG.height).makeGraphic(FlxG.width, 100, 0xEE000000);
		bottomBar.scrollFactor.set();
		add(bottomBar);
		
		FlxTween.tween(bottomBar, {y: FlxG.height - 100}, 0.6, {ease: FlxEase.expoOut, startDelay: 0.2});
		
		// Progress bar background
		progressBarBG = new FlxSprite(30, FlxG.height - 70).makeGraphic(FlxG.width - 60, 20, 0xFF333333);
		progressBarBG.scrollFactor.set();
		progressBarBG.alpha = 0;
		add(progressBarBG);
		
		// Progress bar fill
		progressBar = new FlxSprite(30, FlxG.height - 70).makeGraphic(10, 20, 0xFF00FFFF);
		progressBar.scrollFactor.set();
		progressBar.alpha = 0;
		add(progressBar);
		
		FlxTween.tween(progressBarBG, {alpha: 0.8}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.6});
		FlxTween.tween(progressBar, {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.6});
		
		// Time elapsed text
		timeElapsedText = new FlxText(30, FlxG.height - 45, FlxG.width - 60, "00:00 / 00:00", 20);
		timeElapsedText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER);
		timeElapsedText.scrollFactor.set();
		timeElapsedText.alpha = 0;
		add(timeElapsedText);
		
		FlxTween.tween(timeElapsedText, {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.7});

		// ═══════════════════════════════════════
		// 4. PRACTICE/CHARTING MODE INDICATORS
		// ═══════════════════════════════════════
		
		practiceText = new FlxText(FlxG.width - 250, 20, 220, "🎓 ALIŞTIRMA MODU", 24);
		practiceText.setFormat(Paths.font('vcr.ttf'), 24, 0xFF71FD92, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		practiceText.borderSize = 2;
		practiceText.scrollFactor.set();
		practiceText.visible = PlayState.instance.practiceMode;
		practiceText.alpha = 0;
		add(practiceText);
		
		if(practiceText.visible)
			FlxTween.tween(practiceText, {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.8});

		var chartingText:FlxText = new FlxText(FlxG.width - 250, 50, 220, "📊 CHART MODU", 24);
		chartingText.setFormat(Paths.font('vcr.ttf'), 24, 0xFFFFAA00, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		chartingText.borderSize = 2;
		chartingText.scrollFactor.set();
		chartingText.visible = PlayState.chartingMode;
		chartingText.alpha = 0;
		add(chartingText);
		
		if(chartingText.visible)
			FlxTween.tween(chartingText, {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.9});

		// ═══════════════════════════════════════
		// 5. MENU CARDS
		// ═══════════════════════════════════════
		
		menuCards = new FlxTypedGroup<FlxSprite>();
		add(menuCards);
		
		menuIcons = new FlxTypedGroup<FlxSprite>();
		add(menuIcons);
		
		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		// ═══════════════════════════════════════
		// 6. ERROR DISPLAY
		// ═══════════════════════════════════════
		
		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xDD000000);
		missingTextBG.scrollFactor.set();
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 28);
		missingText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.borderSize = 3;
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		regenMenu();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		super.create();
	}
	
	function createParticleSystem()
	{
		particleEmitter = new FlxEmitter(FlxG.width / 2, FlxG.height / 2, 30);
		
		for (i in 0...30)
		{
			var particle:FlxParticle = new FlxParticle();
			particle.makeGraphic(3, 3, FlxColor.CYAN);
			particle.exists = false;
			particleEmitter.add(particle);
		}
		
		particleEmitter.launchMode = FlxEmitterMode.CIRCLE;
		particleEmitter.velocity.set(-100, -100, 100, 100);
		particleEmitter.lifespan.set(2, 4);
		particleEmitter.alpha.set(0.3, 0.6, 0, 0);
		particleEmitter.scale.set(1, 1.5, 0.5, 0.5);
		particleEmitter.start(false, 0.1);
		
		add(particleEmitter);
	}
	
	function getPauseSong()
	{
		var formattedSongName:String = (songName != null ? Paths.formatToSongPath(songName) : '');
		var formattedPauseMusic:String = Paths.formatToSongPath(ClientPrefs.data.pauseMusic);
		if(formattedSongName == 'none' || (formattedSongName != 'none' && formattedPauseMusic == 'none')) return null;

		return (formattedSongName != '') ? formattedSongName : formattedPauseMusic;
	}

	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;
	
	override function update(elapsed:Float)
	{
		cantUnpause -= elapsed;
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);
		
		// ═══════════════════════════════════════
		// ANIMATION UPDATES
		// ═══════════════════════════════════════
		
		animTimer += elapsed;
		pulseTimer += elapsed;
		
		// Pulse glow effect
		if (glowEffect != null)
		{
			glowEffect.alpha = 0.08 + Math.sin(pulseTimer * 2) * 0.04;
			glowEffect.angle += elapsed * 10;
		}
		
		// Update progress bar
		if (FlxG.sound.music != null && progressBar != null)
		{
			var progress:Float = (Conductor.songPosition / FlxG.sound.music.length);
			progressBar.scale.x = Math.max(0, Math.min(1, progress)) * (FlxG.width - 60);
			
			// Color shift based on progress
			var hue:Float = progress * 180; // Cyan to Green
			progressBar.color = FlxColor.fromHSB(hue, 0.8, 1);
		}
		
		// Update time text
		if (FlxG.sound.music != null && timeElapsedText != null)
		{
			var curTime:String = FlxStringUtil.formatTime(Math.max(0, Math.floor(Conductor.songPosition / 1000)), false);
			var totalTime:String = FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
			timeElapsedText.text = curTime + " / " + totalTime;
		}

		// ═══════════════════════════════════════
		// INPUT HANDLING
		// ═══════════════════════════════════════

		if(controls.BACK)
		{
			close();
			return;
		}

		if(FlxG.keys.justPressed.F5)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			PlayState.nextReloadAll = true;
			MusicBeatState.resetState();
		}

		updateSkipTextStuff();
		
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}

		var daSelected:String = menuItems[curSelected];
		switch (daSelected)
		{
			case 'Skip Time':
				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime -= 1000;
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime += 1000;
					holdTime = 0;
				}

				if(controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
					if(holdTime > 0.5)
					{
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if(curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
					else if(curTime < 0) curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
		}

		if (controls.ACCEPT && (cantUnpause <= 0 || !controls.controllerMode))
		{
			if (menuItems == difficultyChoices)
			{
				var songLowercase:String = Paths.formatToSongPath(PlayState.SONG.song);
				var poop:String = Highscore.formatSong(songLowercase, curSelected);
				try
				{
					if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected))
					{
						Song.loadFromJson(poop, songLowercase);
						PlayState.storyDifficulty = curSelected;
						MusicBeatState.resetState();
						FlxG.sound.music.volume = 0;
						PlayState.changedDifficulty = true;
						PlayState.chartingMode = false;
						return;
					}
				}
				catch(e:haxe.Exception)
				{
					trace('ERROR! ${e.message}');
	
					var errorStr:String = e.message;
					if(errorStr.startsWith('[lime.utils.Assets] ERROR:')) 
						errorStr = '❌ DOSYA BULUNAMADI:\n' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length-1);
					else 
						errorStr = '❌ HATA:\n' + errorStr + '\n\n' + e.stack;

					missingText.text = errorStr;
					missingText.screenCenter(Y);
					missingText.visible = true;
					missingTextBG.visible = true;
					FlxG.sound.play(Paths.sound('cancelMenu'));
					
					// Flash error
					FlxG.camera.flash(FlxColor.RED, 0.3);

					super.update(elapsed);
					return;
				}

				menuItems = menuItemsOG;
				regenMenu();
			}

			switch (daSelected)
			{
				case "Resume":
					// Smooth close animation
					FlxTween.tween(bgOverlay, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
					FlxTween.tween(topBar, {y: -150}, 0.3, {ease: FlxEase.backIn});
					FlxTween.tween(bottomBar, {y: FlxG.height}, 0.3, {ease: FlxEase.backIn});
					
					for (item in grpMenuShit.members)
					{
						FlxTween.tween(item, {alpha: 0}, 0.2, {ease: FlxEase.quartIn});
					}
					
					new FlxTimer().start(0.3, function(tmr:FlxTimer) {
						close();
					});
					
				case 'Change Difficulty':
					menuItems = difficultyChoices;
					deleteSkipTimeText();
					regenMenu();
					
				case 'Toggle Practice Mode':
					PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
					PlayState.changedDifficulty = true;
					practiceText.visible = PlayState.instance.practiceMode;
					
					// Visual feedback
					FlxG.camera.flash(PlayState.instance.practiceMode ? 0xFF71FD92 : FlxColor.WHITE, 0.2);
					FlxG.sound.play(Paths.sound('confirmMenu'));
					
				case "Restart Song":
					// Epic restart animation
					FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function() {
						restartSong();
					});
					FlxG.camera.shake(0.01, 0.5);
					
				case "Leave Charting Mode":
					FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function() {
						restartSong();
						PlayState.chartingMode = false;
					});
					
				case 'Skip Time':
					if(curTime < Conductor.songPosition)
					{
						PlayState.startOnTime = curTime;
						restartSong(true);
					}
					else
					{
						if (curTime != Conductor.songPosition)
						{
							PlayState.instance.clearNotesBefore(curTime);
							PlayState.instance.setSongTime(curTime);
						}
						close();
					}
					
				case 'End Song':
					close();
					PlayState.instance.notes.clear();
					PlayState.instance.unspawnNotes = [];
					PlayState.instance.finishSong(true);
					
				case 'Toggle Botplay':
					PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
					PlayState.changedDifficulty = true;
					PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
					PlayState.instance.botplayTxt.alpha = 1;
					PlayState.instance.botplaySine = 0;
					
					// Visual feedback
					FlxG.camera.flash(PlayState.instance.cpuControlled ? 0xFF9271FD : FlxColor.WHITE, 0.2);
					FlxG.sound.play(Paths.sound('confirmMenu'));
					
				case 'Options':
					PlayState.instance.paused = true;
					PlayState.instance.vocals.volume = 0;
					PlayState.instance.canResync = false;
					MusicBeatState.switchState(new OptionsState());
					if(ClientPrefs.data.pauseMusic != 'None')
					{
						FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), pauseMusic.volume);
						FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
						FlxG.sound.music.time = pauseMusic.time;
					}
					OptionsState.onPlayState = true;
					
				case "Exit to menu":
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;

					PlayState.instance.canResync = false;
					Mods.loadTopMod();
					
					// Smooth transition
					FlxG.camera.fade(FlxColor.BLACK, 0.6, false, function() {
						if(PlayState.isStoryMode)
							MusicBeatState.switchState(new StoryMenuState());
						else 
							MusicBeatState.switchState(new FreeplayState());

						FlxG.sound.playMusic(Paths.music('freakyMenu'));
					});
					
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
					FlxG.camera.followLerp = 0;
			}
		}
	}

	function deleteSkipTimeText()
	{
		if(skipTimeText != null)
		{
			skipTimeText.kill();
			remove(skipTimeText);
			skipTimeText.destroy();
		}
		skipTimeText = null;
		skipTimeTracker = null;
	}

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused = true;
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		MusicBeatState.resetState();
	}

	override function destroy()
	{
		pauseMusic.destroy();
		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		// Camera shake on selection change
		FlxG.camera.shake(0.002, 0.1);
		
		for (num => item in grpMenuShit.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.5;
			
			// Scale effect
			item.scale.set(0.9, 0.9);
			
			if (item.targetY == 0)
			{
				item.alpha = 1;
				item.scale.set(1.1, 1.1);
				
				// Pulse animation
				FlxTween.cancelTweensOf(item.scale);
				FlxTween.tween(item.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.elasticOut});
				
				if(item == skipTimeTracker)
				{
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
		}
		
		// Update card visuals
		for (i in 0...menuCards.length)
		{
			var card = menuCards.members[i];
			if (card == null) continue;
			
			if (i == curSelected)
			{
				FlxTween.cancelTweensOf(card);
				FlxTween.tween(card, {alpha: 1}, 0.2, {ease: FlxEase.quartOut});
				FlxTween.tween(card.scale, {x: 1.05, y: 1.05}, 0.2, {ease: FlxEase.quartOut});
			}
			else
			{
				FlxTween.cancelTweensOf(card);
				FlxTween.tween(card, {alpha: 0.6}, 0.2, {ease: FlxEase.quartOut});
				FlxTween.tween(card.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.quartOut});
			}
		}
		
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	function regenMenu():Void 
	{
		// Clear old menu
		for (i in 0...grpMenuShit.members.length)
		{
			var obj:Alphabet = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}
		
		// Clear old cards
		for (i in 0...menuCards.length)
		{
			var card:FlxSprite = menuCards.members[0];
			if (card != null)
			{
				card.kill();
				menuCards.remove(card, true);
				card.destroy();
			}
		}

		// Create new menu with modern cards
		for (num => str in menuItems) 
		{
			// Get Turkish translation
			var displayText:String = menuTranslations.exists(str) ? menuTranslations.get(str) : str;
			
			// Create menu card background
			var card:FlxSprite = new FlxSprite(0, 0).makeGraphic(600, 80, 0x88000000);
			card.scrollFactor.set();
			card.ID = num;
			card.alpha = 0;
			menuCards.add(card);
			
			// Create text
			var item = new Alphabet(120, 320, displayText, true);
			item.isMenuItem = true;
			item.targetY = num;
			item.scrollFactor.set();
			grpMenuShit.add(item);
			
			// Entrance animation
			FlxTween.tween(card, {alpha: 0.6}, 0.4, {
				ease: FlxEase.quartOut,
				startDelay: 0.05 * num
			});

			if(str == 'Skip Time')
			{
				skipTimeText = new FlxText(0, 0, 0, '', 64);
				skipTimeText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.CYAN, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;
				skipTimeTracker = item;
				add(skipTimeText);

				updateSkipTextStuff();
				updateSkipTimeText();
			}
		}
		
		curSelected = 0;
		changeSelection();
	}
	
	function updateSkipTextStuff()
	{
		if(skipTimeText == null || skipTimeTracker == null) return;

		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText()
	{
		if (skipTimeText == null) return;
		
		var currentTimeStr:String = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false);
		var totalTimeStr:String = FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
		
		skipTimeText.text = '⏩ ' + currentTimeStr + ' / ' + totalTimeStr;
		
		// Color based on position
		var progress:Float = curTime / FlxG.sound.music.length;
		var hue:Float = progress * 180;
		skipTimeText.color = FlxColor.fromHSB(hue, 0.8, 1);
	}
}