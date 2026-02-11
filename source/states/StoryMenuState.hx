package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import flixel.group.FlxGroup;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.util.FlxGradient;
import flixel.addons.display.FlxBackdrop;
import flixel.ui.FlxBar;

import objects.MenuItem;
import objects.MenuCharacter;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import backend.StageData;

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	// ===== ULTRA MODERN UI REVOLUTION =====
	
	// Advanced Background System
	var bgParallaxBack:FlxSprite;
	var bgParallaxMid:FlxSprite;
	var bgParallaxFront:FlxSprite;
	var bgGradient:FlxSprite;
	var particleSystem:FlxTypedGroup<FlxSprite>;
	var dynamicOverlay:FlxSprite;
	
	// Card-Based Week Display
	var weekCardsContainer:FlxTypedGroup<WeekCard>;
	var cardScrollVelocity:Float = 0;
	var targetCardScroll:Float = 0;
	
	// Modern Stats Panel
	var statsPanel:FlxSprite;
	var scoreDisplay:FlxText;
	var accuracyDisplay:FlxText;
	var rankDisplay:FlxSprite;
	var weekCompletionBar:FlxBar;
	var totalSongsText:FlxText;
	var completedSongsText:FlxText;
	
	// Achievement Badges
	var badgeContainer:FlxTypedGroup<FlxSprite>;
	var weekBadges:Array<String> = [];
	
	// Enhanced Navigation
	var modernTopBar:FlxSprite;
	var modernBottomBar:FlxSprite;
	var sidePreviewPanel:FlxSprite;
	var miniPreviewSprite:FlxSprite;
	
	// Interactive Elements
	var quickPlayBtn:FlxSprite;
	var randomWeekBtn:FlxSprite;
	var viewStatsBtn:FlxSprite;
	var settingsBtn:FlxSprite;
	var backBtn:FlxSprite;
	
	// Difficulty System Revamp
	var difficultyCard:FlxSprite;
	var difficultyIcon:FlxSprite;
	var difficultyLabel:FlxText;
	var difficultyStars:FlxTypedGroup<FlxSprite>;
	var difficultyDescription:FlxText;
	
	// Track Preview System
	var trackPreviewContainer:FlxSprite;
	var trackCardGroup:FlxTypedGroup<TrackCard>;
	var playingPreviewIndex:Int = -1;
	
	// Animation System
	var transitionOverlay:FlxSprite;
	var glowEffect:FlxSprite;
	var pulseEffect:FlxSprite;
	
	// Character Display Enhanced
	var characterSpotlight:FlxSprite;
	var characterNameTag:FlxText;
	var characterQuote:FlxText;
	
	// Core Variables
	private static var lastDifficultyName:String = '';
	var curDifficulty:Int = 1;
	private static var curWeek:Int = 0;
	
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var loadedWeeks:Array<WeekData> = [];
	
	// Interaction States
	var isTransitioning:Bool = false;
	var hoverTween:FlxTween;
	var selectedCard:WeekCard;
	
	// Visual Polish
	var mouseFollowLight:FlxSprite;
	var scanlineEffect:FlxBackdrop;
	var vignetteOverlay:FlxSprite;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		persistentUpdate = persistentDraw = true;
		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);
		// ===== LOAD WEEKS WITH SAFETY CHECK =====
		loadedWeeks = [];
		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			if(weekFile == null) continue; // NULL KONTROLÜ
    
			var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);
			if(!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				loadedWeeks.push(weekFile);
			}
		}

		if(loadedWeeks.length == 0)
		{
			trace("ERROR: No weeks loaded!");
			MusicBeatState.switchState(new MainMenuState());
			return;
		}

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("🎯 Browsing Story Campaigns", null);
		#end

		if(WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("⚠️ NO STORY WEEKS FOUND\n\nPress ACCEPT to open Week Editor\nPress BACK to return to Main Menu",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
		}

		if(curWeek >= WeekData.weeksList.length) curWeek = 0;

		// ===== PARALLAX BACKGROUND SYSTEM =====
		createParallaxBackground();
		
		// ===== PARTICLE SYSTEM =====
		createParticleSystem();
		
		// ===== GRADIENT OVERLAY =====
		bgGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, 
			[0xFF0a0a0a, 0xFF1a1a2e, 0xFF16213e], 1, 90);
		bgGradient.alpha = 0.85;
		add(bgGradient);
		
		// ===== SCANLINE RETRO EFFECT =====
		
		// ===== MODERN TOP BAR =====
		createModernTopBar();
		
		// ===== SIDE PREVIEW PANEL =====
		createSidePreviewPanel();
		
		// ===== WEEK CARDS SYSTEM =====
		createWeekCards();
		
		// ===== CHARACTER SPOTLIGHT =====
		createCharacterDisplay();
		
		// ===== STATS PANEL =====
		createStatsPanel();
		
		// ===== TRACK PREVIEW CARDS =====
		createTrackPreview();
		
		// ===== DIFFICULTY CARD SYSTEM =====
		createDifficultyCard();
		
		// ===== INTERACTIVE BUTTONS =====
		createInteractiveButtons();
		
		// ===== MODERN BOTTOM BAR =====
		createModernBottomBar();
		
		// ===== VISUAL POLISH =====
		createVisualEffects();
		
		// ===== MOUSE FOLLOW LIGHT =====
		mouseFollowLight = new FlxSprite().makeGraphic(300, 300, 0xFFffffff);
		mouseFollowLight.blend = ADD;
		mouseFollowLight.alpha = 0.03;
		add(mouseFollowLight);
		
		// ===== INITIALIZE =====
		loadedWeeks = [];
		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);
			if(!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				loadedWeeks.push(weekFile);
			}
		}
		
		changeWeek();
		changeDifficulty();

		// ===== ENTRANCE ANIMATION =====
		playEntranceAnimation();

		super.create();
	}

	function createParallaxBackground():Void
	{
		bgParallaxBack = new FlxSprite().loadGraphic(Paths.image('menubackgrounds/menuDesat'));
		bgParallaxBack.scrollFactor.set(0.1, 0.1);
		bgParallaxBack.setGraphicSize(Std.int(bgParallaxBack.width * 1.2));
		bgParallaxBack.updateHitbox();
		bgParallaxBack.screenCenter();
		bgParallaxBack.color = 0xFF2a3d5c;
		bgParallaxBack.alpha = 0.4;
		add(bgParallaxBack);
		
		bgParallaxMid = new FlxSprite().loadGraphic(Paths.image('menubackgrounds/menuDesat'));
		bgParallaxMid.scrollFactor.set(0.3, 0.3);
		bgParallaxMid.setGraphicSize(Std.int(bgParallaxMid.width * 1.1));
		bgParallaxMid.updateHitbox();
		bgParallaxMid.screenCenter();
		bgParallaxMid.color = 0xFF3d5a80;
		bgParallaxMid.alpha = 0.5;
		add(bgParallaxMid);
		
		bgParallaxFront = new FlxSprite().loadGraphic(Paths.image('menubackgrounds/menuDesat'));
		bgParallaxFront.scrollFactor.set(0.5, 0.5);
		bgParallaxFront.updateHitbox();
		bgParallaxFront.screenCenter();
		bgParallaxFront.color = 0xFF5a7d9a;
		bgParallaxFront.alpha = 0.3;
		add(bgParallaxFront);
	}

	function createParticleSystem():Void
	{
		particleSystem = new FlxTypedGroup<FlxSprite>();
		add(particleSystem);
		
		for(i in 0...25)
		{
			var particle:FlxSprite = new FlxSprite();
			particle.makeGraphic(4, 4, FlxColor.WHITE);
			particle.alpha = FlxG.random.float(0.1, 0.4);
			particle.x = FlxG.random.float(0, FlxG.width);
			particle.y = FlxG.random.float(0, FlxG.height);
			particle.velocity.y = FlxG.random.float(-30, -10);
			particle.acceleration.y = FlxG.random.float(-5, 5);
			particleSystem.add(particle);
		}
	}

	function createModernTopBar():Void
	{
		modernTopBar = new FlxSprite(0, -120).makeGraphic(FlxG.width, 120, 0xFF000000);
		modernTopBar.alpha = 0.9;
		add(modernTopBar);
		
		FlxTween.tween(modernTopBar, {y: 0}, 0.6, {ease: FlxEase.expoOut, startDelay: 0.2});
		
		// Logo/Title
		var titleText:FlxText = new FlxText(30, 20, 0, "📖 STORY MODE", 38);
		titleText.setFormat(Paths.font("vcr.ttf"), 38, FlxColor.WHITE, LEFT);
		titleText.setBorderStyle(OUTLINE, 0xFF000000, 2);
		titleText.alpha = 0;
		add(titleText);
		FlxTween.tween(titleText, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.4});
		
		// Campaign Progress
		var progressLabel:FlxText = new FlxText(FlxG.width - 320, 25, 0, "CAMPAIGN PROGRESS", 16);
		progressLabel.setFormat(Paths.font("vcr.ttf"), 16, 0xFF00d4ff, LEFT);
		progressLabel.alpha = 0;
		add(progressLabel);
		FlxTween.tween(progressLabel, {alpha: 0.8}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.5});
		
		var progressBarBg:FlxSprite = new FlxSprite(FlxG.width - 320, 50).makeGraphic(300, 20, 0xFF1a1a1a);
		progressBarBg.alpha = 0;
		add(progressBarBg);
		FlxTween.tween(progressBarBg, {alpha: 0.8}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.5});
		
		weekCompletionBar = new FlxBar(FlxG.width - 318, 52, LEFT_TO_RIGHT, 296, 16, this, "curWeek", 0, 10);
		weekCompletionBar.createFilledBar(0xFF2a2a2a, 0xFF00ff88, true, 0xFF00cc66);
		weekCompletionBar.alpha = 0;
		add(weekCompletionBar);
		FlxTween.tween(weekCompletionBar, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.6});
		
		// Week Counter
		totalSongsText = new FlxText(FlxG.width - 320, 75, 300, "Week 1 / 7", 14);
		totalSongsText.setFormat(Paths.font("vcr.ttf"), 14, 0xFFaaaaaa, RIGHT);
		totalSongsText.alpha = 0;
		add(totalSongsText);
		FlxTween.tween(totalSongsText, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.7});
	}

	function createSidePreviewPanel():Void
	{
		sidePreviewPanel = new FlxSprite(FlxG.width, 120).makeGraphic(420, FlxG.height - 240, 0xFF0f0f0f);
		sidePreviewPanel.alpha = 0.95;
		add(sidePreviewPanel);
		
		FlxTween.tween(sidePreviewPanel, {x: FlxG.width - 420}, 0.7, {ease: FlxEase.expoOut, startDelay: 0.3});
		
		// Preview Image
		miniPreviewSprite = new FlxSprite(FlxG.width - 390, 150).loadGraphic(Paths.image('menubackgrounds/menu_stage'));
		miniPreviewSprite.setGraphicSize(360, 200);
		miniPreviewSprite.updateHitbox();
		miniPreviewSprite.alpha = 0;
		add(miniPreviewSprite);
		FlxTween.tween(miniPreviewSprite, {alpha: 0.9}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.8});
		
		// Info Label
		var previewLabel:FlxText = new FlxText(FlxG.width - 390, 360, 360, "WEEK PREVIEW", 20);
		previewLabel.setFormat(Paths.font("vcr.ttf"), 20, 0xFF00d4ff, CENTER);
		previewLabel.setBorderStyle(OUTLINE, 0xFF000000, 2);
		previewLabel.alpha = 0;
		add(previewLabel);
		FlxTween.tween(previewLabel, {alpha: 1}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.9});
	}

	function createWeekCards():Void
	{
		weekCardsContainer = new FlxTypedGroup<WeekCard>();
		add(weekCardsContainer);
		
		for(i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);
			
			if(!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				var card:WeekCard = new WeekCard(60, 160 + (i * 140), weekFile, i, isLocked);
				card.ID = i;
				weekCardsContainer.add(card);
			}
		}
	}

	function createCharacterDisplay():Void
	{
		characterSpotlight = new FlxSprite(FlxG.width / 2 - 300, 140).makeGraphic(600, 400, 0xFF0a0a0a);
		characterSpotlight.alpha = 0.6;
		add(characterSpotlight);
    
		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		add(grpWeekCharacters);
    
		// NULL KONTROLÜ EKLE
		if(loadedWeeks.length > 0 && loadedWeeks[0] != null)
		{
			WeekData.setDirectoryFromWeek(loadedWeeks[0]);
			var charArray:Array<String> = loadedWeeks[0].weekCharacters;
        
			// weekCharacters null kontrolü
			if(charArray != null && charArray.length > 0)
			{
				for (char in 0...3)
				{
					var characterName:String = char < charArray.length ? charArray[char] : 'bf'; // fallback
					var xPos:Float = (FlxG.width / 2 - 200) + (char * 200);
					var weekCharacterThing:MenuCharacter = new MenuCharacter(xPos, characterName);
					weekCharacterThing.y = 200;
					grpWeekCharacters.add(weekCharacterThing);
				}
			}
			else
			{
            // Fallback karakterler
				var defaultChars:Array<String> = ['dad', 'bf', 'gf'];
				for (char in 0...3)
				{
					var xPos:Float = (FlxG.width / 2 - 200) + (char * 200);
					var weekCharacterThing:MenuCharacter = new MenuCharacter(xPos, defaultChars[char]);
					weekCharacterThing.y = 200;
					grpWeekCharacters.add(weekCharacterThing);
				}
			}
		}
    
		characterNameTag = new FlxText(FlxG.width / 2 - 300, 560, 600, "BOYFRIEND", 28);
		characterNameTag.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, CENTER);
		characterNameTag.setBorderStyle(OUTLINE, 0xFF000000, 3);
		add(characterNameTag);
    
		characterQuote = new FlxText(FlxG.width / 2 - 300, 595, 600, '"Time to show what I got!"', 18);
		characterQuote.setFormat(Paths.font("vcr.ttf"), 18, 0xFFaaaaaa, CENTER, OUTLINE, 0xFF000000);
		add(characterQuote);
	}

	function createStatsPanel():Void
	{
		statsPanel = new FlxSprite(60, FlxG.height - 220).makeGraphic(500, 180, 0xFF0f0f0f);
		statsPanel.alpha = 0.9;
		add(statsPanel);
		
		var statsTitle:FlxText = new FlxText(80, FlxG.height - 205, 0, "📊 STATISTICS", 22);
		statsTitle.setFormat(Paths.font("vcr.ttf"), 22, 0xFF00d4ff, LEFT);
		statsTitle.setBorderStyle(OUTLINE, 0xFF000000, 2);
		add(statsTitle);
		
		scoreDisplay = new FlxText(80, FlxG.height - 170, 0, "WEEK SCORE: 0", 20);
		scoreDisplay.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
		add(scoreDisplay);
		
		accuracyDisplay = new FlxText(80, FlxG.height - 140, 0, "BEST ACCURACY: N/A", 18);
		accuracyDisplay.setFormat(Paths.font("vcr.ttf"), 18, 0xFFffaa00, LEFT);
		add(accuracyDisplay);
		
		completedSongsText = new FlxText(80, FlxG.height - 110, 0, "SONGS COMPLETED: 0/3", 18);
		completedSongsText.setFormat(Paths.font("vcr.ttf"), 18, 0xFF00ff88, LEFT);
		add(completedSongsText);
		
		// Rank Display
		rankDisplay = new FlxSprite(450, FlxG.height - 190).loadGraphic(Paths.image('rankings/S'));
		rankDisplay.setGraphicSize(80, 80);
		rankDisplay.updateHitbox();
		rankDisplay.alpha = 0.8;
		add(rankDisplay);
	}

	function createTrackPreview():Void
	{
		trackPreviewContainer = new FlxSprite(FlxG.width - 390, 390).makeGraphic(360, 280, 0xFF0a0a0a);
		trackPreviewContainer.alpha = 0.8;
		add(trackPreviewContainer);
		
		var trackTitle:FlxText = new FlxText(FlxG.width - 380, 405, 0, "🎵 TRACKLIST", 18);
		trackTitle.setFormat(Paths.font("vcr.ttf"), 18, 0xFFff6b9d, LEFT);
		trackTitle.setBorderStyle(OUTLINE, 0xFF000000, 2);
		add(trackTitle);
		
		trackCardGroup = new FlxTypedGroup<TrackCard>();
		add(trackCardGroup);
	}

	function createDifficultyCard():Void
	{
		difficultyCard = new FlxSprite(FlxG.width / 2 - 200, FlxG.height - 220).makeGraphic(400, 180, 0xFF0a0a0a);
		difficultyCard.alpha = 0.9;
		add(difficultyCard);
		
		var diffTitle:FlxText = new FlxText(FlxG.width / 2 - 180, FlxG.height - 205, 0, "⚔️ DIFFICULTY", 22);
		diffTitle.setFormat(Paths.font("vcr.ttf"), 22, 0xFFff6b9d, LEFT);
		diffTitle.setBorderStyle(OUTLINE, 0xFF000000, 2);
		add(diffTitle);
		
		Difficulty.resetList();
		if(lastDifficultyName == '') lastDifficultyName = Difficulty.getDefault();
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
		
		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		
		var leftArrow = new FlxSprite(FlxG.width / 2 - 160, FlxG.height - 150);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		add(leftArrow);
		
		difficultyLabel = new FlxText(FlxG.width / 2 - 100, FlxG.height - 145, 200, "NORMAL", 32);
		difficultyLabel.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		difficultyLabel.setBorderStyle(OUTLINE, 0xFF000000, 3);
		add(difficultyLabel);
		
		var rightArrow = new FlxSprite(FlxG.width / 2 + 110, FlxG.height - 150);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right");
		rightArrow.animation.play('idle');
		add(rightArrow);
		
		// Star Rating
		difficultyStars = new FlxTypedGroup<FlxSprite>();
		add(difficultyStars);
		
		for(i in 0...5)
		{
			var star:FlxSprite = new FlxSprite((FlxG.width / 2 - 80) + (i * 35), FlxG.height - 100);
			star.loadGraphic(Paths.image('star'));
			star.setGraphicSize(25, 25);
			star.updateHitbox();
			star.alpha = 0.3;
			difficultyStars.add(star);
		}
		
		difficultyDescription = new FlxText(FlxG.width / 2 - 180, FlxG.height - 65, 360, "Balanced challenge for all players", 14);
		difficultyDescription.setFormat(Paths.font("vcr.ttf"), 14, 0xFFaaaaaa, CENTER);
		add(difficultyDescription);
	}

	function createInteractiveButtons():Void
	{
		// Quick Play Button
		quickPlayBtn = new FlxSprite(FlxG.width - 390, FlxG.height - 180).makeGraphic(160, 50, 0xFF00d4ff);
		quickPlayBtn.alpha = 0.8;
		add(quickPlayBtn);
		
		var quickPlayText:FlxText = new FlxText(quickPlayBtn.x, quickPlayBtn.y + 12, 160, "⚡ QUICK PLAY", 16);
		quickPlayText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.BLACK, CENTER);
		quickPlayText.bold = true;
		add(quickPlayText);
		
		// Random Week Button
		randomWeekBtn = new FlxSprite(FlxG.width - 210, FlxG.height - 180).makeGraphic(160, 50, 0xFFff6b9d);
		randomWeekBtn.alpha = 0.8;
		add(randomWeekBtn);
		
		var randomText:FlxText = new FlxText(randomWeekBtn.x, randomWeekBtn.y + 12, 160, "🎲 RANDOM", 16);
		randomText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.BLACK, CENTER);
		randomText.bold = true;
		add(randomText);
		
		// View Full Stats
		viewStatsBtn = new FlxSprite(FlxG.width - 390, FlxG.height - 120).makeGraphic(160, 50, 0xFF9d4edd);
		viewStatsBtn.alpha = 0.8;
		add(viewStatsBtn);
		
		var statsText:FlxText = new FlxText(viewStatsBtn.x, viewStatsBtn.y + 12, 160, "📈 STATS", 16);
		statsText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.BLACK, CENTER);
		statsText.bold = true;
		add(statsText);
		
		// Settings
		settingsBtn = new FlxSprite(FlxG.width - 210, FlxG.height - 120).makeGraphic(160, 50, 0xFFffaa00);
		settingsBtn.alpha = 0.8;
		add(settingsBtn);
		
		var settingsText:FlxText = new FlxText(settingsBtn.x, settingsBtn.y + 12, 160, "⚙️ MODIFIERS", 16);
		settingsText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.BLACK, CENTER);
		settingsText.bold = true;
		add(settingsText);
	}

	function createModernBottomBar():Void
	{
		modernBottomBar = new FlxSprite(0, FlxG.height).makeGraphic(FlxG.width, 60, 0xFF000000);
		modernBottomBar.alpha = 0.9;
		add(modernBottomBar);
		
		FlxTween.tween(modernBottomBar, {y: FlxG.height - 60}, 0.6, {ease: FlxEase.expoOut, startDelay: 0.3});
		
		// Controls Guide
		var controlsGuide:FlxText = new FlxText(30, FlxG.height - 45, FlxG.width - 60, 
			"[↑↓] Navigate  [←→] Difficulty  [ENTER] Select  [R] Reset Score  [CTRL] Modifiers  [ESC] Back", 14);
		controlsGuide.setFormat(Paths.font("vcr.ttf"), 14, 0xFFaaaaaa, CENTER);
		controlsGuide.alpha = 0;
		add(controlsGuide);
		FlxTween.tween(controlsGuide, {alpha: 0.8}, 0.5, {ease: FlxEase.quadOut, startDelay: 0.8});
	}

	function createVisualEffects():Void
	{
		// Vignette
		vignetteOverlay = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, 
			[0x00000000, 0x88000000], 1, 0, true);
		vignetteOverlay.blend = MULTIPLY;
		vignetteOverlay.alpha = 0.7;
		add(vignetteOverlay);
		
		// Glow Effect
		glowEffect = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFffffff);
		glowEffect.blend = ADD;
		glowEffect.alpha = 0;
		add(glowEffect);
		
		// Pulse Effect
		pulseEffect = new FlxSprite().makeGraphic(FlxG.width, 5, 0xFF00d4ff);
		pulseEffect.y = 120;
		pulseEffect.alpha = 0.5;
		add(pulseEffect);
		
		FlxTween.tween(pulseEffect, {alpha: 0.8}, 1, {ease: FlxEase.sineInOut, type: PINGPONG});
	}

	function playEntranceAnimation():Void
	{
		FlxG.camera.zoom = 1.1;
		FlxTween.tween(FlxG.camera, {zoom: 1}, 0.8, {ease: FlxEase.expoOut});
		
		FlxG.camera.flash(FlxColor.BLACK, 0.6);
	}

	override function closeSubState() {
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	override function update(elapsed:Float)
	{
		if(WeekData.weeksList.length < 1)
		{
			if (controls.BACK && !movedBack && !selectedWeek)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				movedBack = true;
				exitAnimation();
			}
			super.update(elapsed);
			return;
		}

		// ===== PARALLAX EFFECT =====
		var mouseXPercent:Float = FlxG.mouse.screenX / FlxG.width;
		var mouseYPercent:Float = FlxG.mouse.screenY / FlxG.height;
		
		bgParallaxBack.x = FlxMath.lerp(bgParallaxBack.x, -50 + (mouseXPercent * 100), elapsed * 2);
		bgParallaxBack.y = FlxMath.lerp(bgParallaxBack.y, -50 + (mouseYPercent * 100), elapsed * 2);
		
		bgParallaxMid.x = FlxMath.lerp(bgParallaxMid.x, -30 + (mouseXPercent * 60), elapsed * 3);
		bgParallaxMid.y = FlxMath.lerp(bgParallaxMid.y, -30 + (mouseYPercent * 60), elapsed * 3);
		
		bgParallaxFront.x = FlxMath.lerp(bgParallaxFront.x, -10 + (mouseXPercent * 20), elapsed * 4);
		bgParallaxFront.y = FlxMath.lerp(bgParallaxFront.y, -10 + (mouseYPercent * 20), elapsed * 4);
		
		// ===== MOUSE FOLLOW LIGHT =====
		mouseFollowLight.x = FlxMath.lerp(mouseFollowLight.x, FlxG.mouse.screenX - 150, elapsed * 5);
		mouseFollowLight.y = FlxMath.lerp(mouseFollowLight.y, FlxG.mouse.screenY - 150, elapsed * 5);
		
		// ===== PARTICLE SYSTEM UPDATE =====
		for(particle in particleSystem.members)
		{
			if(particle.y < -10)
			{
				particle.y = FlxG.height + 10;
				particle.x = FlxG.random.float(0, FlxG.width);
			}
		}

		// ===== SCORE LERP =====
		if(intendedScore != lerpScore)
		{
			lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
			if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;
			scoreDisplay.text = "WEEK SCORE: " + lerpScore;
		}

		// ===== WEEK CARDS SMOOTH SCROLL =====
		targetCardScroll = curWeek * 140;
		cardScrollVelocity += (targetCardScroll - cardScrollVelocity) * elapsed * 8;
		
		for(card in weekCardsContainer.members)
		{
			var targetY:Float = 160 + (card.ID * 140) - cardScrollVelocity;
			card.y = FlxMath.lerp(targetY, card.y, Math.exp(-elapsed * 10));
			
			// Scale & Alpha based on selection
			var distance:Float = Math.abs(card.ID - curWeek);
			var scaleFactor:Float = distance == 0 ? 1.05 : Math.max(0.85, 1.0 - (distance * 0.08));
			var alphaFactor:Float = distance == 0 ? 1.0 : Math.max(0.5, 1.0 - (distance * 0.2));
			
			card.scale.set(
				FlxMath.lerp(scaleFactor, card.scale.x, Math.exp(-elapsed * 12)),
				FlxMath.lerp(scaleFactor, card.scale.y, Math.exp(-elapsed * 12))
			);
			card.alpha = FlxMath.lerp(alphaFactor, card.alpha, Math.exp(-elapsed * 8));
		}

		if (!movedBack && !selectedWeek && !isTransitioning)
		{
			// ===== NAVIGATION =====
			if (controls.UI_UP_P)
			{
				changeWeek(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}

			if (controls.UI_DOWN_P)
			{
				changeWeek(1);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}

			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				changeWeek(-FlxG.mouse.wheel);
			}

			// ===== DIFFICULTY =====
			if (controls.UI_RIGHT_P)
			{
				changeDifficulty(1);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
			}
			else if (controls.UI_LEFT_P)
			{
				changeDifficulty(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
			}

			// ===== BUTTON INTERACTIONS =====
			if(FlxG.mouse.overlaps(quickPlayBtn) && FlxG.mouse.justPressed)
			{
				selectWeek();
			}
			
			if(FlxG.mouse.overlaps(randomWeekBtn) && FlxG.mouse.justPressed)
			{
				curWeek = FlxG.random.int(0, loadedWeeks.length - 1);
				changeWeek(0);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			
			if(FlxG.mouse.overlaps(settingsBtn) && FlxG.mouse.justPressed)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			// ===== CONTROLS =====
			if(FlxG.keys.justPressed.CONTROL)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
			}
			else if(controls.RESET)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
			}
			else if (controls.ACCEPT)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			exitAnimation();
		}

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (!weekIsLocked(loadedWeeks[curWeek].fileName))
		{
			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
			for (i in 0...leWeek.length) {
				songArray.push(leWeek[i][0]);
			}

			try
			{
				PlayState.storyPlaylist = songArray;
				PlayState.isStoryMode = true;
				selectedWeek = true;
				isTransitioning = true;
	
				var diffic = Difficulty.getFilePath(curDifficulty);
				if(diffic == null) diffic = '';
	
				PlayState.storyDifficulty = curDifficulty;
	
				Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
				PlayState.campaignScore = 0;
				PlayState.campaignMisses = 0;
			}
			catch(e:Dynamic)
			{
				trace('ERROR! $e');
				return;
			}
			
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				// ===== ULTRA MODERN SELECTION ANIMATION =====
				FlxG.camera.flash(0xFF00d4ff, 0.3);
				FlxG.camera.shake(0.005, 0.3);
				
				// Glow effect
				FlxTween.tween(glowEffect, {alpha: 0.3}, 0.2, {ease: FlxEase.quadOut,
					onComplete: function(t:FlxTween) {
						FlxTween.tween(glowEffect, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
					}
				});
				
				// Zoom in on selected card
				if(weekCardsContainer.members[curWeek] != null)
				{
					FlxTween.tween(weekCardsContainer.members[curWeek].scale, {x: 1.2, y: 1.2}, 0.4, {ease: FlxEase.backOut});
				}
				
				// Character celebration
				for (char in grpWeekCharacters.members)
				{
					if (char.character != '' && char.hasConfirmAnimation)
					{
						char.animation.play('confirm');
					}
				}
				
				stopspamming = true;
			}

			var directory = StageData.forceNextDirectory;
			LoadingState.loadNextDirectory();
			StageData.forceNextDirectory = directory;

			@:privateAccess
			if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
			{
				Paths.freeGraphicsFromMemory();
			}
			LoadingState.prepareToSong();
			
			new FlxTimer().start(1.0, function(tmr:FlxTimer)
			{
				#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
				LoadingState.loadAndSwitchState(new PlayState(), true);
				FreeplayState.destroyFreeplayVocals();
			});
			
			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
		}
		else 
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.camera.shake(0.01, 0.2);
		}
	}

	function exitAnimation():Void
	{
		isTransitioning = true;
		FlxTween.tween(FlxG.camera, {zoom: 1.1}, 0.5, {ease: FlxEase.expoIn});
		FlxG.camera.fade(FlxColor.BLACK, 0.5, false, function() {
			MusicBeatState.switchState(new MainMenuState());
		});
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);

		var diff:String = Difficulty.getString(curDifficulty, false);
		
		difficultyLabel.text = diff.toUpperCase();
		
		// Star rating based on difficulty
		var starCount:Int = curDifficulty + 1;
		for(i in 0...difficultyStars.members.length)
		{
			difficultyStars.members[i].alpha = i < starCount ? 1.0 : 0.3;
		}
		
		// Update description
		switch(curDifficulty)
		{
			case 0:
				difficultyDescription.text = "Perfect for beginners and casual players";
			case 1:
				difficultyDescription.text = "Balanced challenge for all players";
			case 2:
				difficultyDescription.text = "Intense challenge for experienced players";
			default:
				difficultyDescription.text = "Custom difficulty setting";
		}
		
		lastDifficultyName = diff;

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= loadedWeeks.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = loadedWeeks.length - 1;

		var leWeek:WeekData = loadedWeeks[curWeek];
		WeekData.setDirectoryFromWeek(leWeek);

		// Update week counter
		totalSongsText.text = 'Week ${curWeek + 1} / ${loadedWeeks.length}';
		
		// Update character
		var weekArray:Array<String> = leWeek.weekCharacters;
		for (i in 0...grpWeekCharacters.length) {
			grpWeekCharacters.members[i].changeCharacter(weekArray[i]);
		}
		
		// Update character name
		if(weekArray[1] != null && weekArray[1] != '')
		{
			characterNameTag.text = weekArray[1].toUpperCase();
		}

		// Update preview image
		var assetName:String = leWeek.weekBackground;
		if(assetName != null && assetName.length > 0)
		{
			miniPreviewSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + assetName));
			miniPreviewSprite.setGraphicSize(360, 200);
			miniPreviewSprite.updateHitbox();
		}

		// Update tracks
		updateTrackList();
		
		PlayState.storyWeek = curWeek;

		Difficulty.loadFromWeek();

		if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		var newPos:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}
		
		changeDifficulty(0);
		
		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}

	function updateTrackList():Void
	{
		trackCardGroup.clear();
		
		var leWeek:WeekData = loadedWeeks[curWeek];
		for (i in 0...leWeek.songs.length)
		{
			var trackCard:TrackCard = new TrackCard(FlxG.width - 370, 440 + (i * 70), leWeek.songs[i][0], i);
			trackCardGroup.add(trackCard);
		}
		
		completedSongsText.text = 'SONGS COMPLETED: 0/${leWeek.songs.length}';
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}
}

// ===== CUSTOM WEEK CARD CLASS =====
class WeekCard extends FlxSprite
{
	public var weekData:WeekData;
	public var weekIndex:Int;
	public var isLocked:Bool;
	public var cardBg:FlxSprite;
	public var weekTitle:FlxText;
	public var lockIcon:FlxSprite;
	
	public function new(x:Float, y:Float, data:WeekData, index:Int, locked:Bool)
	{
		super(x, y);
		
		weekData = data;
		weekIndex = index;
		isLocked = locked;
		
		makeGraphic(600, 120, isLocked ? 0xFF2a2a2a : 0xFF1a1a2e);
		alpha = 0.9;
		
		var weekName:String = data.storyName != null ? data.storyName : 'Week ${index + 1}';
		
		weekTitle = new FlxText(20, 20, 560, weekName.toUpperCase(), 28);
		weekTitle.setFormat(Paths.font("vcr.ttf"), 28, isLocked ? 0xFF666666 : FlxColor.WHITE, LEFT);
		weekTitle.setBorderStyle(OUTLINE, 0xFF000000, 2);
		
		if(isLocked)
		{
			var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
			lockIcon = new FlxSprite(520, 35);
			lockIcon.frames = ui_tex;
			lockIcon.animation.addByPrefix('lock', 'lock');
			lockIcon.animation.play('lock');
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if(weekTitle != null)
		{
			weekTitle.x = x + 20;
			weekTitle.y = y + 20;
		}
		
		if(lockIcon != null)
		{
			lockIcon.x = x + 520;
			lockIcon.y = y + 35;
		}
	}
	
	override function draw()
	{
		super.draw();
		if(weekTitle != null) weekTitle.draw();
		if(lockIcon != null) lockIcon.draw();
	}
}

// ===== CUSTOM TRACK CARD CLASS =====
class TrackCard extends FlxSprite
{
	public var songName:String;
	public var trackIndex:Int;
	public var trackText:FlxText;
	
	public function new(x:Float, y:Float, song:String, index:Int)
	{
		super(x, y);
		
		songName = song;
		trackIndex = index;
		
		makeGraphic(340, 60, 0xFF1a1a1a);
		alpha = 0.8;
		
		trackText = new FlxText(15, 18, 310, '${index + 1}. ${song}', 18);
		trackText.setFormat(Paths.font("vcr.ttf"), 18, 0xFFff6b9d, LEFT);
		trackText.setBorderStyle(OUTLINE, 0xFF000000, 2);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if(trackText != null)
		{
			trackText.x = x + 15;
			trackText.y = y + 18;
		}
	}
	
	override function draw()
	{
		super.draw();
		if(trackText != null) trackText.draw();
	}
}