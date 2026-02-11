package options;

import states.MainMenuState;
import backend.StageData;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxObject;
import flixel.util.FlxGradient;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Nota Renkleri',
		'Kontroller',
		'Gecikme Ve Kombo',
		'Grafikler',
		'Arayüz',
		'Oynanis',
		'P.E.T Ayarlari'
		#if TRANSLATIONS_ALLOWED , 'Dil' #end
	];
	
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var categoryCards:FlxTypedGroup<FlxSprite>;
	private var categoryIcons:FlxTypedGroup<FlxText>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	// Modern UI Elements
	var bg:FlxSprite;
	var bgGradient:FlxSprite;
	var topBar:FlxSprite;
	var bottomBar:FlxSprite;
	var titleText:FlxText;
	var descText:FlxText;
	var particleEmitter:FlxEmitter;
	var glowEffect:FlxSprite;
	
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var bgColorTween:FlxTween;
	
	// Animation
	var animTimer:Float = 0;
	var pulseTimer:Float = 0;

	// Category colors
	var optionsColor:Map<String, Array<Int>> = [
		'Nota Renkleri' => [0xFF666666, 0xFF888888],
		'Kontroller' => [0xFFE0A32A, 0xFFFF9900],
		'Gecikme Ve Kombo' => [0xFFAA0044, 0xFFFF0066],
		'Grafikler' => [0xFF31B0D1, 0xFF00CCFF],
		'Arayüz' => [0xFF8D58FD, 0xFFAA77FF],
		'Oynanis' => [0xFF58FD69, 0xFF77FF88],
		'Dil' => [0xFFFFD700, 0xFFFFEE00]
	];
	
	// Category icons (text-based)
	var optionsIcons:Map<String, String> = [
		'Nota Renkleri' => '♪',
		'Kontroller' => '⌨',
		'Gecikme Ve Kombo' => '⏱',
		'Grafikler' => '📺',
		'Arayüz' => '🎨',
		'Oynanis' => '🎮',
		'Dil' => '🌐'
	];
	
	// Category descriptions
	var optionsDesc:Map<String, String> = [
		'Nota Renkleri' => 'Notaların Renklerini ve Görünümünü Özelleştirin',
		'Kontroller' => 'Klavye ve Gamepad Tuş Atamalarını Yapın',
		'Gecikme Ve Kombo' => 'Ses/Video Gecikme ve Kombo Gösterimini Ayarlayın',
		'Grafikler' => 'Grafik Kalitesi ve Performans Ayarları',
		'Arayüz' => 'Menü ve Oyun İçi Görsel Öğeleri Düzenleyin',
		'Oynanis' => 'Oyun Mekaniği ve Zorluk Ayarları',
		'Dil' => 'Oyun Dilini Değiştirin',
		'P.E.T Ayarlari' => 'Psych Engine Türkiye nin Ayarlarını Yönetin.'
	];

	function openSelectedSubstate(label:String) {
		// Smooth transition animation
		FlxTween.tween(bgGradient, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
		FlxTween.tween(topBar, {y: -150}, 0.3, {ease: FlxEase.backIn});
		FlxTween.tween(bottomBar, {y: FlxG.height}, 0.3, {ease: FlxEase.backIn});
		
		for (card in categoryCards)
		{
			FlxTween.tween(card, {alpha: 0}, 0.2, {ease: FlxEase.quartIn});
		}
		
		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			switch(label)
			{
				case 'Nota Renkleri':
					openSubState(new options.NotesColorSubState());
				case 'Kontroller':
					openSubState(new options.ControlsSubState());
				case 'Grafikler':
					openSubState(new options.GraphicsSettingsSubState());
				case 'Arayüz':
					openSubState(new options.VisualsSettingsSubState());
				case 'Oynanis':
					openSubState(new options.GameplaySettingsSubState());
				case 'Gecikme Ve Kombo':
					MusicBeatState.switchState(new options.NoteOffsetState());
				case 'Dil':
					openSubState(new options.LanguageSubState());
				case 'P.E.T Ayarlari':
					openSubState(new options.PETSettingsState());
			}
		});
	}

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Ayarlar Menüsü", null);
		#end

		// ═══════════════════════════════════════
		// 1. ANIMATED BACKGROUND SYSTEM
		// ═══════════════════════════════════════

		// Base background
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.3));
		bg.updateHitbox();
		bg.screenCenter();
		bg.alpha = 0.3;
		bg.scrollFactor.set(0.05, 0.05);
		add(bg);
		
		// Gradient overlay
		bgGradient = FlxGradient.createGradientFlxSprite(
			FlxG.width,
			FlxG.height,
			[0xFF1a1a2e, 0xFF16213e, 0xFF0f3460],
			1, 90
		);
		bgGradient.alpha = 0;
		bgGradient.scrollFactor.set();
		add(bgGradient);
		
		FlxTween.tween(bgGradient, {alpha: 0.9}, 0.8, {ease: FlxEase.quartOut});
		
		// Particle system
		createParticleSystem();
		
		// Center glow
		glowEffect = new FlxSprite(FlxG.width / 2 - 400, FlxG.height / 2 - 400);
		glowEffect.makeGraphic(800, 800, FlxColor.WHITE);
		glowEffect.blend = ADD;
		glowEffect.alpha = 0;
		glowEffect.scrollFactor.set();
		add(glowEffect);
		
		FlxTween.tween(glowEffect, {alpha: 0.08}, 1, {ease: FlxEase.quartOut});

		// ═══════════════════════════════════════
		// 2. TOP BAR
		// ═══════════════════════════════════════
		
		topBar = new FlxSprite(0, -150).makeGraphic(FlxG.width, 120, 0xDD000000);
		topBar.scrollFactor.set();
		add(topBar);
		
		FlxTween.tween(topBar, {y: 0}, 0.8, {ease: FlxEase.expoOut, startDelay: 0.2});
		
		titleText = new FlxText(50, 30, FlxG.width - 100, "AYARLAR", 56);
		titleText.setFormat(Paths.font("vcr.ttf"), 56, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF8D58FD);
		titleText.borderSize = 3;
		titleText.scrollFactor.set();
		titleText.alpha = 0;
		add(titleText);
		
		FlxTween.tween(titleText, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.4});
		
		var subtitleText:FlxText = new FlxText(50, 85, FlxG.width - 100, "Oyununuzu Kişileştirin!", 24);
		subtitleText.setFormat(Paths.font("vcr.ttf"), 24, 0xFFCCCCCC, LEFT);
		subtitleText.scrollFactor.set();
		subtitleText.alpha = 0;
		add(subtitleText);
		
		FlxTween.tween(subtitleText, {alpha: 0.7}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.6});

		// ═══════════════════════════════════════
		// 3. BOTTOM INFO BAR
		// ═══════════════════════════════════════
		
		bottomBar = new FlxSprite(0, FlxG.height).makeGraphic(FlxG.width, 100, 0xDD000000);
		bottomBar.scrollFactor.set();
		add(bottomBar);
		
		FlxTween.tween(bottomBar, {y: FlxG.height - 100}, 0.8, {ease: FlxEase.expoOut, startDelay: 0.3});
		
		descText = new FlxText(50, FlxG.height - 70, FlxG.width - 100, "", 28);
		descText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.borderSize = 2;
		descText.scrollFactor.set();
		descText.alpha = 0;
		add(descText);
		
		FlxTween.tween(descText, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.8});

		// ═══════════════════════════════════════
		// 4. CATEGORY CARDS
		// ═══════════════════════════════════════
		
		categoryCards = new FlxTypedGroup<FlxSprite>();
		add(categoryCards);
		
		categoryIcons = new FlxTypedGroup<FlxText>();
		add(categoryIcons);
		
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (num => option in options)
		{
			// Card background
			var card:FlxSprite = new FlxSprite(0, 0).makeGraphic(600, 90, 0x88000000);
			card.ID = num;
			card.alpha = 0;
			card.scrollFactor.set();
			categoryCards.add(card);
			
			// Icon
			var icon:FlxText = new FlxText(0, 0, 80, optionsIcons.get(option), 64);
			icon.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER);
			icon.ID = num;
			icon.alpha = 0;
			icon.scrollFactor.set();
			categoryIcons.add(icon);
			
			// Option text
			var optionText:Alphabet = new Alphabet(0, 0, Language.getPhrase('options_$option', option), false);
			optionText.isMenuItem = true;
			optionText.targetY = num;
			optionText.ID = num;
			optionText.alpha = 0;
			optionText.scrollFactor.set();
			grpOptions.add(optionText);
			
			// Staggered entrance animation
			FlxTween.tween(card, {alpha: 0.8}, 0.5, {
				ease: FlxEase.quartOut,
				startDelay: 0.5 + (num * 0.08)
			});
			FlxTween.tween(icon, {alpha: 1}, 0.5, {
				ease: FlxEase.quartOut,
				startDelay: 0.6 + (num * 0.08)
			});
			FlxTween.tween(optionText, {alpha: 1}, 0.5, {
				ease: FlxEase.quartOut,
				startDelay: 0.7 + (num * 0.08)
			});
		}

		// Camera setup
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		
		camFollow.screenCenter();
		camFollowPos.screenCenter();
		FlxG.camera.follow(camFollowPos, null, 1);
		
		changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}
	
	function createParticleSystem()
	{
		particleEmitter = new FlxEmitter(FlxG.width / 2, 60, 50);
		particleEmitter.width = FlxG.width;
		
		for (i in 0...50)
		{
			var particle:FlxParticle = new FlxParticle();
			particle.makeGraphic(4, 4, FlxColor.WHITE);
			particle.exists = false;
			particleEmitter.add(particle);
		}
		
		particleEmitter.launchMode = FlxEmitterMode.SQUARE;
		particleEmitter.velocity.set(-40, 60, 40, 180);
		particleEmitter.lifespan.set(3, 6);
		particleEmitter.alpha.set(0.15, 0.35, 0, 0);
		particleEmitter.scale.set(1, 1.5, 0.5, 0.5);
		particleEmitter.start(false, 0.08);
		
		add(particleEmitter);
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Ayarlar Menüsü", null);
		#end
		
		// Re-entrance animation
		FlxTween.tween(bgGradient, {alpha: 0.9}, 0.4, {ease: FlxEase.quartOut});
		FlxTween.tween(topBar, {y: 0}, 0.4, {ease: FlxEase.backOut});
		FlxTween.tween(bottomBar, {y: FlxG.height - 100}, 0.4, {ease: FlxEase.backOut});
		
		for (card in categoryCards)
		{
			FlxTween.tween(card, {alpha: 0.8}, 0.3, {ease: FlxEase.quartOut});
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		// ═══════════════════════════════════════
		// ANIMATION UPDATES
		// ═══════════════════════════════════════
		
		animTimer += elapsed;
		pulseTimer += elapsed;
		
		// Smooth camera
		var lerpVal:Float = Math.max(0, Math.min(1, elapsed * 7.5));
		camFollowPos.setPosition(
			FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal),
			FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal)
		);

		// Rotate background
		if (bg != null) {
			bg.angle = Math.sin(animTimer * 0.4) * 3;
		}
		
		// Pulse glow
		if (glowEffect != null) {
			glowEffect.alpha = 0.08 + Math.sin(pulseTimer * 2) * 0.04;
			glowEffect.angle += elapsed * 12;
		}

		// ═══════════════════════════════════════
		// INPUT HANDLING
		// ═══════════════════════════════════════

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			
			// Exit animation
			FlxTween.tween(bgGradient, {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
			FlxTween.tween(topBar, {y: -150}, 0.4, {ease: FlxEase.backIn});
			FlxTween.tween(bottomBar, {y: FlxG.height}, 0.4, {ease: FlxEase.backIn});
			
			for (card in categoryCards)
			{
				FlxTween.tween(card, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
			}
			
			new FlxTimer().start(0.4, function(tmr:FlxTimer)
			{
				if(onPlayState)
				{
					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(new PlayState());
					FlxG.sound.music.volume = 0;
				}
				else
					MusicBeatState.switchState(new MainMenuState());
			});
		}
		else if (controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			
			// Selection feedback
			var selectedCard = categoryCards.members[curSelected];
			if (selectedCard != null)
			{
				FlxTween.cancelTweensOf(selectedCard.scale);
				selectedCard.scale.set(1.1, 1.1);
				FlxTween.tween(selectedCard.scale, {x: 1, y: 1}, 0.4, {ease: FlxEase.elasticOut});
			}
			
			openSelectedSubstate(options[curSelected]);
		}
		
		// ═══════════════════════════════════════
		// CARD POSITIONING
		// ═══════════════════════════════════════
		
		var startY:Float = 200;
		var spacing:Float = 110;
		
		for (num => item in grpOptions.members)
		{
			var targetY:Float = startY + ((num - curSelected) * spacing);
			item.y = FlxMath.lerp(item.y, targetY, elapsed * 10);
			item.x = FlxMath.lerp(item.x, 200, elapsed * 10);
			
			// Update card
			var card = categoryCards.members[num];
			if (card != null)
			{
				card.x = FlxMath.lerp(card.x, 80, elapsed * 10);
				card.y = FlxMath.lerp(card.y, item.y - 15, elapsed * 10);
				
				if (num == curSelected)
				{
					card.alpha = FlxMath.lerp(card.alpha, 1, elapsed * 10);
				}
				else
				{
					card.alpha = FlxMath.lerp(card.alpha, 0.6, elapsed * 10);
				}
			}
			
			// Update icon
			var icon = categoryIcons.members[num];
			if (icon != null)
			{
				icon.x = card.x + 20;
				icon.y = card.y + 10;
				icon.alpha = item.alpha;
			}
		}
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		FlxG.sound.play(Paths.sound('scrollMenu'));

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			item.scale.set(0.85, 0.85);
			
			if (item.targetY == 0)
			{
				item.alpha = 1;
				
				// Bounce effect
				FlxTween.cancelTweensOf(item.scale);
				item.scale.set(1, 1);
				FlxTween.tween(item.scale, {x: 1.08, y: 1.08}, 0.25, {ease: FlxEase.backOut});
				
				camFollow.y = item.getGraphicMidpoint().y;
			}
		}
		
		// Update description
		var selectedOption = options[curSelected];
		if (optionsDesc.exists(selectedOption))
			descText.text = optionsDesc.get(selectedOption);
		
		// Update background color
		if (optionsColor.exists(selectedOption))
		{
			var colors = optionsColor.get(selectedOption);
			
			if (bgColorTween != null) bgColorTween.cancel();
			
			var newGradient = FlxGradient.createGradientFlxSprite(
				FlxG.width,
				FlxG.height,
				colors.concat([0xFF0a0a0a]),
				1, 90
			);
			newGradient.alpha = 0;
			newGradient.scrollFactor.set();
			
			insert(members.indexOf(bgGradient), newGradient);
			FlxTween.tween(bgGradient, {alpha: 0}, 0.6, {
				onComplete: function(twn:FlxTween) {
					remove(bgGradient);
					bgGradient = newGradient;
				}
			});
			FlxTween.tween(newGradient, {alpha: 0.9}, 0.6);
		}
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}