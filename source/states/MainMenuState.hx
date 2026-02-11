package states;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import objects.Alphabet;
import flixel.input.keyboard.FlxKey;
import backend.Achievements;
import backend.WeekData;
import backend.Highscore;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.util.FlxTimer;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import objects.HealthIcon;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '1.0.4';
	public static var curSelected:Int = 0;
	
	var menuItems:FlxTypedGroup<FlxSpriteGroup>;
	var optionShit:Array<String> = [
		'hikaye_modu',
		'serbest_oyun',
		#if MODS_ALLOWED 'modlar', #end
		#if ACHIEVEMENTS_ALLOWED 'basarimlar', #end
		'yapimcilar',
		'ayarlar',
		'galeri'
	];

	// ═══════════════════════════════════════════════════════════════
	// ANALOG HORROR TEMA DEĞİŞKENLERİ
	// ═══════════════════════════════════════════════════════════════
	
	// Arka Plan Katmanları
	var bg:FlxSprite;
	var staticOverlay:FlxSprite;
	var scanlines:FlxSprite;
	var vhsOverlay:FlxSprite;
	var crtCurve:FlxSprite;
	var vhsTrackingLines:Array<FlxSprite> = [];
	var colorBleeding:FlxSprite;
	
	// VHS UI Elemanları
	var recIndicator:FlxSprite;
	var recText:FlxText;
	var recBlinking:Bool = true;
	var timestampText:FlxText;
	var channelText:FlxText;
	var trackingText:FlxText;
	var playIcon:FlxText;
	
	// Emergency Broadcast Elemanları
	var emergencyHeader:FlxSprite;
	var emergencyText:FlxText;
	var emergencySubtext:FlxText;
	var warningStripes:FlxSprite;
	
	// Bozuk Sinyal Efektleri
	var signalLoss:FlxSprite;
	var noSignalText:FlxText;
	var pleaseStandBy:FlxText;
	var technicalDiff:FlxText;
	
	// Glitch Partikülleri
	var glitchBlocks:Array<FlxSprite> = [];
	var deadPixels:Array<FlxSprite> = [];
	
	// Menü Paneli
	var menuPanel:FlxSprite;
	var menuBorder:FlxSprite;
	var selectionBar:FlxSprite;
	var selectionGlow:FlxSprite;
	
	// Sağ Panel - Bilgi
	var infoPanel:FlxSprite;
	var infoBorder:FlxSprite;
	var programTitle:FlxText;
	var programDesc:FlxText;
	var programWarning:FlxText;
	var testPattern:FlxSprite;
	
	// Alt Bilgi
	var bottomBar:FlxSprite;
	var broadcastInfo:FlxText;
	var frequencyText:FlxText;
	var copyrightText:FlxText;
	
	// Analog Mesajlar
	var subliminalTexts:Array<FlxText> = [];
	var hiddenMessage:FlxText;
	var corruptedText:FlxText;
	
	// Efekt Değişkenleri
	var vhsTimer:Float = 0;
	var staticTimer:Float = 0;
	var glitchTimer:Float = 0;
	var trackingOffset:Float = 0;
	var signalStrength:Float = 1.0;
	var isGlitching:Bool = false;
	var frameCounter:Int = 0;
	var tapeTime:Float = 0;
	
	// Korku Zamanlaması
	var scareTimer:Float = 0;
	var nextScareTime:Float = 12;
	var distortionLevel:Float = 0;
	
	// Kamera
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var selectedSomethin:Bool = false;
	
	// Cheat Sistemi
	var cheatSequence:Array<Int> = [];
	var cheatPattern:Array<Int> = [0, 3, 3, 2]; 
	var cheatLastInputTime:Float = 0;
	var cheatTimeout:Float = 1.5;
	var prevUp:Bool = false;
	var prevRight:Bool = false;
	var prevLeft:Bool = false;

	// ═══════════════════════════════════════════════════════════════
	// ANALOG HORROR RENKLERİ
	// ═══════════════════════════════════════════════════════════════
	
	var vhsBlue:FlxColor = 0xFF1a1a2e;
	var vhsGreen:FlxColor = 0xFF00ff41;
	var vhsYellow:FlxColor = 0xFFffcc00;
	var vhsOrange:FlxColor = 0xFFff6600;
	var vhsRed:FlxColor = 0xFFcc0000;
	var vhsWhite:FlxColor = 0xFFe0e0e0;
	var vhsGray:FlxColor = 0xFF808080;
	var crtGreen:FlxColor = 0xFF33ff33;
	var staticWhite:FlxColor = 0xFFcccccc;

	// ═══════════════════════════════════════════════════════════════
	// MENÜ VERİLERİ - ANALOG HORROR
	// ═══════════════════════════════════════════════════════════════
	
	var menuTitles:Map<String, String> = [
		'hikaye_modu' => "PROGRAM 01",
		'serbest_oyun' => "PROGRAM 02",
		'modlar' => "PROGRAM 03",
		'basarimlar' => "PROGRAM 04",
		'yapimcilar' => "PROGRAM 05",
		'ayarlar' => "PROGRAM 06",
		'galeri' => "niga"
	];
	
	var menuSubtitles:Map<String, String> = [
		'hikaye_modu' => "// STORY MODE",
		'serbest_oyun' => "// FREEPLAY",
		'modlar' => "// MODIFICATIONS",
		'basarimlar' => "// ACHIEVEMENTS",
		'yapimcilar' => "// CREDITS",
		'ayarlar' => "// SETTINGS",
		'galeri' => "// GALLERY"
	];

	var menuDescriptions:Map<String, String> = [
		'hikaye_modu' => "BU PROGRAM, HERKES İÇİN UYGUN OLMAYAN İÇERİK BİRLİKTELİĞİ İÇERMEKTEDİR.\n\nİZLEYİCİLERİN İHTİYATLI DAVRANMALARI ÖNERİLİR.",
		'serbest_oyun' => "YAYININIZI SEÇİN.\nTÜM FREKANSLAR MEVCUTTUR.\n\nSİNYAL GÜCÜ: DEĞİŞKEN",
		'modlar' => "UNAUTHORIZED TRANSMISSIONS\nDETECTED ON THIS CHANNEL.\n\nPROCEED WITH CAUTION.",
		'basarimlar' => "YOUR VIEWING HISTORY\nHAS BEEN RECORDED.\n\nTHIS CANNOT BE UNDONE.",
		'yapimcilar' => "THE FOLLOWING INDIVIDUALS\nARE RESPONSIBLE FOR\nTHIS BROADCAST.",
		'ayarlar' => "ADJUST YOUR RECEIVER.\nOPTIMAL SETTINGS RECOMMENDED.\n\nDO NOT ADJUST YOUR SET.",
		'galeri' => "niga2"
	];
	
	var creepyBroadcasts:Array<String> = [
		"DO NOT LOOK AWAY FROM YOUR SCREEN",
		"THIS IS NOT A TEST",
		"STAY TUNED FOR FURTHER INSTRUCTIONS",
		"THE FOLLOWING MESSAGE IS MANDATORY",
		"YOU ARE BEING WATCHED",
		"TRANSMISSION WILL RESUME SHORTLY",
		"PLEASE REMAIN CALM",
		"DO NOT ATTEMPT TO CHANGE THE CHANNEL",
		"THIS BROADCAST IS FOR YOU",
		"WE KNOW YOU ARE THERE"
	];
	
	var technicalMessages:Array<String> = [
		"SIGNAL LOST",
		"NO CARRIER",
		"PLEASE STAND BY",
		"TECHNICAL DIFFICULTIES",
		"WEAK SIGNAL",
		"INTERFERENCE DETECTED",
		"TRACKING ADJUST",
		"HEAD CLEANING REQUIRED"
	];

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("CHANNEL 00 - STANDBY", null);
		#end

		persistentUpdate = persistentDraw = true;

		// ═══════════════════════════════════════════════════════════════
		// ANALOG HORROR ARKA PLAN
		// ═══════════════════════════════════════════════════════════════
		
		// Ana arka plan - koyu mavi VHS rengi
		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, vhsBlue);
		add(bg);
		
		// VHS renk bozulması (color bleeding)
		colorBleeding = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000033);
		colorBleeding.alpha = 0.1;
		add(colorBleeding);
		
		// VHS tracking çizgileri
		createVHSTrackingLines();
		
		// Glitch blokları
		createGlitchBlocks();
		
		// Dead pixels
		createDeadPixels();
		
		// Statik overlay
		staticOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, staticWhite);
		staticOverlay.alpha = 0.02;
		add(staticOverlay);
		
		// Scanlines
		createScanlines();
		
		// CRT curve efekti (köşe karartma)
		createCRTEffect();

		// ═══════════════════════════════════════════════════════════════
		// EMERGENCY BROADCAST HEADER
		// ═══════════════════════════════════════════════════════════════
		
		// Uyarı çizgileri
		warningStripes = new FlxSprite(0, 0).makeGraphic(FlxG.width, 60, vhsYellow);
		add(warningStripes);
		
		// Siyah çizgiler
		for(i in 0...8)
		{
			var stripe = new FlxSprite(i * 160, 0).makeGraphic(80, 60, 0xFF000000);
			add(stripe);
		}
		
		// Emergency header
		emergencyHeader = new FlxSprite(0, 60).makeGraphic(FlxG.width, 50, 0xFF000000);
		add(emergencyHeader);
		
		var headerLine = new FlxSprite(0, 108).makeGraphic(FlxG.width, 3, vhsYellow);
		add(headerLine);
		
		emergencyText = new FlxText(0, 68, FlxG.width, "▶ ACIL DURUM YAYINI ◀", 28);
		emergencyText.setFormat(Paths.font("vcr.ttf"), 28, vhsYellow, CENTER);
		add(emergencyText);
		
		emergencySubtext = new FlxText(0, 95, FlxG.width, "BU BIR DENEME DEGILDIR • KANAL 00", 12);
		emergencySubtext.setFormat(Paths.font("vcr.ttf"), 12, vhsGray, CENTER);
		add(emergencySubtext);

		// ═══════════════════════════════════════════════════════════════
		// VHS UI ELEMANlARI
		// ═══════════════════════════════════════════════════════════════
		
		// REC indicator
		recIndicator = new FlxSprite(30, 130).makeGraphic(12, 12, vhsRed);
		add(recIndicator);
		
		recText = new FlxText(48, 127, 60, "● KAYIT", 16);
		recText.setFormat(Paths.font("vcr.ttf"), 16, vhsRed, LEFT);
		add(recText);
		
		// Timestamp
		timestampText = new FlxText(30, 150, 200, "00:00:00:00", 14);
		timestampText.setFormat(Paths.font("vcr.ttf"), 14, vhsWhite, LEFT);
		add(timestampText);
		
		// Channel
		channelText = new FlxText(FlxG.width - 130, 127, 120, "CH-00", 18);
		channelText.setFormat(Paths.font("vcr.ttf"), 18, vhsGreen, RIGHT);
		add(channelText);
		
		// Play icon
		playIcon = new FlxText(FlxG.width - 130, 150, 120, "▶ OYNAT", 14);
		playIcon.setFormat(Paths.font("vcr.ttf"), 14, vhsWhite, RIGHT);
		add(playIcon);
		
		// Tracking text
		trackingText = new FlxText(FlxG.width - 180, 170, 170, "OYNATILIYOR ████████", 12);
		trackingText.setFormat(Paths.font("vcr.ttf"), 12, vhsGray, RIGHT);
		add(trackingText);

		// ═══════════════════════════════════════════════════════════════
		// MENÜ PANELİ
		// ═══════════════════════════════════════════════════════════════
		
		// Menü çerçevesi
		menuBorder = new FlxSprite(40, 200).makeGraphic(360, 380, vhsYellow);
		menuBorder.alpha = 0.8;
		add(menuBorder);
		
		// Menü paneli
		menuPanel = new FlxSprite(45, 205).makeGraphic(350, 370, 0xFF0a0a15);
		add(menuPanel);
		
		// Panel başlığı
		var menuHeader = new FlxSprite(45, 205).makeGraphic(350, 35, 0xFF1a1a30);
		add(menuHeader);
		
		var menuTitle = new FlxText(55, 212, 330, "█ KANAL SEÇ █", 18);
		menuTitle.setFormat(Paths.font("vcr.ttf"), 18, vhsGreen, CENTER);
		add(menuTitle);
		
		// Seçim çubuğu
		selectionGlow = new FlxSprite(50, 0).makeGraphic(340, 50, vhsGreen);
		selectionGlow.alpha = 0.1;
		add(selectionGlow);
		
		selectionBar = new FlxSprite(45, 0).makeGraphic(5, 45, vhsGreen);
		add(selectionBar);
		
		// Menü öğeleri
		menuItems = new FlxTypedGroup<FlxSpriteGroup>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var itemGroup = new FlxSpriteGroup();
			
			// Program numarası
			var numText = new FlxText(60, 8, 30, "0" + (i + 1), 16);
			numText.setFormat(Paths.font("vcr.ttf"), 16, vhsYellow, LEFT);
			itemGroup.add(numText);
			
			// Program başlığı
			var titleText = menuTitles.exists(optionShit[i]) ? menuTitles.get(optionShit[i]) : "PROGRAM";
			var itemText = new FlxText(100, 5, 200, titleText, 20);
			itemText.setFormat(Paths.font("vcr.ttf"), 20, vhsWhite, LEFT);
			itemGroup.add(itemText);
			
			// Alt başlık
			var subText = menuSubtitles.exists(optionShit[i]) ? menuSubtitles.get(optionShit[i]) : "";
			var subTitle = new FlxText(100, 28, 200, subText, 12);
			subTitle.setFormat(Paths.font("vcr.ttf"), 12, vhsGray, LEFT);
			itemGroup.add(subTitle);
			
			// Sinyal göstergesi
			var signalBars = new FlxText(310, 12, 50, "▮▮▮▯▯", 14);
			signalBars.setFormat(Paths.font("vcr.ttf"), 14, vhsGreen, RIGHT);
			itemGroup.add(signalBars);
			
			itemGroup.ID = i;
			menuItems.add(itemGroup);
		}

		// ═══════════════════════════════════════════════════════════════
		// SAĞ PANEL - PROGRAM BİLGİSİ
		// ═══════════════════════════════════════════════════════════════
		
		// Info çerçevesi
		infoBorder = new FlxSprite(440, 200).makeGraphic(370, 280, vhsYellow);
		infoBorder.alpha = 0.8;
		add(infoBorder);
		
		// Info paneli
		infoPanel = new FlxSprite(445, 205).makeGraphic(360, 270, 0xFF0a0a15);
		add(infoPanel);
		
		// Test pattern (opsiyonel görsel)
		testPattern = new FlxSprite(455, 215).makeGraphic(80, 60, vhsGray);
		add(testPattern);
		createMiniTestPattern();
		
		// Program başlığı
		programTitle = new FlxText(550, 220, 240, "PROGRAM 01", 24);
		programTitle.setFormat(Paths.font("vcr.ttf"), 24, vhsGreen, LEFT);
		add(programTitle);
		
		// Program açıklaması
		programDesc = new FlxText(455, 290, 340, "", 16);
		programDesc.setFormat(Paths.font("vcr.ttf"), 16, vhsWhite, LEFT);
		add(programDesc);
		
		// Uyarı metni
		programWarning = new FlxText(455, 420, 340, "", 12);
		programWarning.setFormat(Paths.font("vcr.ttf"), 12, vhsOrange, LEFT);
		add(programWarning);

		// ═══════════════════════════════════════════════════════════════
		// BOZUK SİNYAL OVERLAY
		// ═══════════════════════════════════════════════════════════════
		
		signalLoss = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		signalLoss.alpha = 0;
		add(signalLoss);
		
		noSignalText = new FlxText(0, FlxG.height / 2 - 50, FlxG.width, "SİNYAL YOK", 64);
		noSignalText.setFormat(Paths.font("vcr.ttf"), 64, vhsWhite, CENTER);
		noSignalText.alpha = 0;
		add(noSignalText);
		
		pleaseStandBy = new FlxText(0, FlxG.height / 2 + 30, FlxG.width, "LÜTFEN BEKLEYIN", 32);
		pleaseStandBy.setFormat(Paths.font("vcr.ttf"), 32, vhsYellow, CENTER);
		pleaseStandBy.alpha = 0;
		add(pleaseStandBy);
		
		technicalDiff = new FlxText(0, FlxG.height / 2 + 80, FlxG.width, "", 18);
		technicalDiff.setFormat(Paths.font("vcr.ttf"), 18, vhsGray, CENTER);
		technicalDiff.alpha = 0;
		add(technicalDiff);

		// ═══════════════════════════════════════════════════════════════
		// GİZLİ MESAJLAR
		// ═══════════════════════════════════════════════════════════════
		
		// Subliminal texts
		for(i in 0...5)
		{
			var subText = new FlxText(
				FlxG.random.float(100, FlxG.width - 300),
				FlxG.random.float(150, FlxG.height - 150),
				300,
				creepyBroadcasts[FlxG.random.int(0, creepyBroadcasts.length - 1)],
				FlxG.random.int(14, 24)
			);
			subText.setFormat(Paths.font("vcr.ttf"), FlxG.random.int(14, 24), vhsWhite, CENTER);
			subText.alpha = 0;
			add(subText);
			subliminalTexts.push(subText);
		}
		
		// Gizli mesaj
		hiddenMessage = new FlxText(0, FlxG.height / 2, FlxG.width, "", 48);
		hiddenMessage.setFormat(Paths.font("vcr.ttf"), 48, vhsRed, CENTER);
		hiddenMessage.alpha = 0;
		add(hiddenMessage);
		
		// Bozuk metin
		corruptedText = new FlxText(0, 0, FlxG.width, "", 20);
		corruptedText.setFormat(Paths.font("vcr.ttf"), 20, vhsGreen, CENTER);
		corruptedText.alpha = 0;
		add(corruptedText);

		// ═══════════════════════════════════════════════════════════════
		// ALT BAR
		// ═══════════════════════════════════════════════════════════════
		
		bottomBar = new FlxSprite(0, FlxG.height - 60).makeGraphic(FlxG.width, 60, 0xFF000000);
		add(bottomBar);
		
		var bottomLine = new FlxSprite(0, FlxG.height - 60).makeGraphic(FlxG.width, 2, vhsYellow);
		bottomLine.alpha = 0.5;
		add(bottomLine);
		
		broadcastInfo = new FlxText(30, FlxG.height - 50, 400, "YAYIN ADRESI: PET-V25-UMUT_EDITION", 14);
		broadcastInfo.setFormat(Paths.font("vcr.ttf"), 14, vhsGray, LEFT);
		add(broadcastInfo);
		
		frequencyText = new FlxText(30, FlxG.height - 30, 300, "FREKANS: 42.00 MHz • STEREO", 12);
		frequencyText.setFormat(Paths.font("vcr.ttf"), 12, vhsGray, LEFT);
		add(frequencyText);
		
		copyrightText = new FlxText(FlxG.width - 350, FlxG.height - 40, 340, "© SametGkTe", 11);
		copyrightText.setFormat(Paths.font("vcr.ttf"), 11, vhsGray, RIGHT);
		add(copyrightText);

		// ═══════════════════════════════════════════════════════════════
		// VHS OVERLAY (en üstte)
		// ═══════════════════════════════════════════════════════════════
		
		vhsOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
		vhsOverlay.alpha = 0.05;
		add(vhsOverlay);

		// ═══════════════════════════════════════════════════════════════
		// KAMERA
		// ═══════════════════════════════════════════════════════════════
		
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		
		camFollow.screenCenter();
		camFollowPos.screenCenter();
		FlxG.camera.follow(camFollowPos, null, 1);

		changeItem();
		
		// VHS başlangıç efekti
		signalLoss.alpha = 1;
		noSignalText.alpha = 1;
		
		new FlxTimer().start(1.5, function(tmr:FlxTimer) {
			FlxTween.tween(signalLoss, {alpha: 0}, 0.5);
			FlxTween.tween(noSignalText, {alpha: 0}, 0.5);
			triggerVHSGlitch(0.3);
		});
		
		nextScareTime = FlxG.random.float(15, 30);
		
		super.create();
	}
	
	// ═══════════════════════════════════════════════════════════════
	// VHS EFEKT FONKSİYONLARI
	// ═══════════════════════════════════════════════════════════════
	
	function createVHSTrackingLines()
	{
		for(i in 0...5)
		{
			var line = new FlxSprite(0, FlxG.random.float(0, FlxG.height));
			line.makeGraphic(FlxG.width, Std.int(FlxG.random.float(2, 8)), staticWhite);
			line.alpha = 0;
			add(line);
			vhsTrackingLines.push(line);
		}
	}
	
	function createGlitchBlocks()
	{
		for(i in 0...15)
		{
			var block = new FlxSprite(
				FlxG.random.float(0, FlxG.width),
				FlxG.random.float(0, FlxG.height)
			);
			block.makeGraphic(
				Std.int(FlxG.random.float(20, 100)),
				Std.int(FlxG.random.float(5, 30)),
				FlxG.random.bool(50) ? vhsGreen : vhsBlue
			);
			block.alpha = 0;
			add(block);
			glitchBlocks.push(block);
		}
	}
	
	function createDeadPixels()
	{
		for(i in 0...30)
		{
			var pixel = new FlxSprite(
				FlxG.random.float(0, FlxG.width),
				FlxG.random.float(0, FlxG.height)
			);
			pixel.makeGraphic(2, 2, FlxG.random.bool(50) ? vhsWhite : 0xFF000000);
			pixel.alpha = FlxG.random.float(0.3, 0.8);
			pixel.visible = FlxG.random.bool(30);
			add(pixel);
			deadPixels.push(pixel);
		}
	}
	
	function createScanlines()
	{
		scanlines = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
		
		// Scanline efekti simülasyonu
		for(y in 0...Std.int(FlxG.height / 3))
		{
			var line = new FlxSprite(0, y * 3).makeGraphic(FlxG.width, 1, 0x15000000);
			add(line);
		}
	}
	
	function createCRTEffect()
	{
		// Köşe karartma
		var cornerTL = FlxGradient.createGradientFlxSprite(200, 200, [0x88000000, 0x00000000], 1, 135);
		cornerTL.setPosition(0, 0);
		add(cornerTL);
		
		var cornerTR = FlxGradient.createGradientFlxSprite(200, 200, [0x88000000, 0x00000000], 1, 225);
		cornerTR.setPosition(FlxG.width - 200, 0);
		add(cornerTR);
		
		var cornerBL = FlxGradient.createGradientFlxSprite(200, 200, [0x88000000, 0x00000000], 1, 45);
		cornerBL.setPosition(0, FlxG.height - 200);
		add(cornerBL);
		
		var cornerBR = FlxGradient.createGradientFlxSprite(200, 200, [0x88000000, 0x00000000], 1, -45);
		cornerBR.setPosition(FlxG.width - 200, FlxG.height - 200);
		add(cornerBR);
	}
	
	function createMiniTestPattern()
	{
		// Basit test pattern renkleri
		var colors = [0xFFFFFFFF, 0xFFFFFF00, 0xFF00FFFF, 0xFF00FF00, 0xFFFF00FF, 0xFFFF0000, 0xFF0000FF];
		for(i in 0...7)
		{
			var bar = new FlxSprite(455 + i * 11, 215).makeGraphic(11, 60, colors[i]);
			bar.alpha = 0.8;
			add(bar);
		}
	}
	
	function triggerVHSGlitch(duration:Float = 0.2)
	{
		isGlitching = true;
		
		// Ekran sarsıntısı
		FlxG.camera.shake(0.008, duration);
		
		// Statik artış
		staticOverlay.alpha = 0.15;
		FlxTween.tween(staticOverlay, {alpha: 0.02}, duration);
		
		// Tracking lines
		for(line in vhsTrackingLines)
		{
			line.y = FlxG.random.float(0, FlxG.height);
			line.alpha = FlxG.random.float(0.1, 0.4);
			FlxTween.tween(line, {alpha: 0, y: line.y + FlxG.random.float(-50, 50)}, duration);
		}
		
		// Glitch blocks
		for(block in glitchBlocks)
		{
			if(FlxG.random.bool(40))
			{
				block.x = FlxG.random.float(0, FlxG.width);
				block.y = FlxG.random.float(0, FlxG.height);
				block.alpha = FlxG.random.float(0.2, 0.6);
				FlxTween.tween(block, {alpha: 0}, duration * 2);
			}
		}
		
		// Color bleeding
		colorBleeding.x = FlxG.random.float(-10, 10);
		FlxTween.tween(colorBleeding, {x: 0}, duration);
		
		new FlxTimer().start(duration, function(tmr:FlxTimer) {
			isGlitching = false;
		});
	}
	
	function triggerSignalLoss()
	{
		signalLoss.alpha = 0.9;
		noSignalText.alpha = 1;
		pleaseStandBy.alpha = 1;
		technicalDiff.text = technicalMessages[FlxG.random.int(0, technicalMessages.length - 1)];
		technicalDiff.alpha = 1;
		
		FlxG.camera.shake(0.02, 0.5);
		
		new FlxTimer().start(FlxG.random.float(1, 2.5), function(tmr:FlxTimer) {
			FlxTween.tween(signalLoss, {alpha: 0}, 0.5);
			FlxTween.tween(noSignalText, {alpha: 0}, 0.5);
			FlxTween.tween(pleaseStandBy, {alpha: 0}, 0.5);
			FlxTween.tween(technicalDiff, {alpha: 0}, 0.5);
			triggerVHSGlitch(0.3);
		});
	}
	
	function triggerSubliminalMessage()
	{
		var text = subliminalTexts[FlxG.random.int(0, subliminalTexts.length - 1)];
		text.text = creepyBroadcasts[FlxG.random.int(0, creepyBroadcasts.length - 1)];
		text.x = FlxG.random.float(100, FlxG.width - 400);
		text.y = FlxG.random.float(150, FlxG.height - 150);
		text.alpha = 0.8;
		
		FlxTween.tween(text, {alpha: 0}, FlxG.random.float(0.5, 2));
	}
	
	function triggerHiddenMessage()
	{
		var messages = [
			"LOOK BEHIND YOU",
			"WE SEE YOU",
			"DON'T TRUST THEM",
			"IT'S TOO LATE",
			"HELP ME",
			"RUN"
		];
		
		hiddenMessage.text = messages[FlxG.random.int(0, messages.length - 1)];
		hiddenMessage.alpha = 0.9;
		
		FlxG.camera.flash(vhsRed, 0.1);
		FlxG.camera.shake(0.02, 0.3);
		
		FlxTween.tween(hiddenMessage, {alpha: 0}, 0.5);
	}
	
	function updateVHSTimestamp()
	{
		tapeTime += 1/60;
		var hours = Std.int(tapeTime / 3600);
		var minutes = Std.int((tapeTime % 3600) / 60);
		var seconds = Std.int(tapeTime % 60);
		var frames = Std.int((tapeTime * 30) % 30);
		
		timestampText.text = StringTools.lpad(Std.string(hours), "0", 2) + ":" +
							 StringTools.lpad(Std.string(minutes), "0", 2) + ":" +
							 StringTools.lpad(Std.string(seconds), "0", 2) + ":" +
							 StringTools.lpad(Std.string(frames), "0", 2);
	}

	// ═══════════════════════════════════════════════════════════════
	// UPDATE
	// ═══════════════════════════════════════════════════════════════

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		vhsTimer += elapsed;
		staticTimer += elapsed;
		glitchTimer += elapsed;
		scareTimer += elapsed;
		frameCounter++;
		
		updateVHSTimestamp();

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * elapsed;

		var lerpVal:Float = FlxMath.bound(elapsed * 9, 0, 1);
		camFollowPos.setPosition(
			FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal),
			FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal)
		);
		
		// VHS efektleri güncelle
		updateVHSEffects(elapsed);
		
		// Analog horror zamanlaması
		if(scareTimer > nextScareTime && !selectedSomethin)
		{
			scareTimer = 0;
			nextScareTime = FlxG.random.float(10, 25);
			
			var scareType = FlxG.random.int(0, 10);
			if(scareType < 3)
				triggerVHSGlitch(FlxG.random.float(0.1, 0.3));
			else if(scareType < 5)
				triggerSubliminalMessage();
			else if(scareType < 7)
				triggerSignalLoss();
			else if(scareType == 7)
				triggerHiddenMessage();
			else
				// Sadece statik artış
				staticOverlay.alpha = FlxG.random.float(0.05, 0.15);
		}

		if (!selectedSomethin)
		{
			handleCheats(elapsed);

			if (controls.UI_UP_P) changeItem(-1);
			if (controls.UI_DOWN_P) changeItem(1);
			if (FlxG.mouse.wheel != 0) changeItem(-FlxG.mouse.wheel);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				
				// VHS kapatma efekti
				triggerSignalLoss();
				
				new FlxTimer().start(2, function(tmr:FlxTimer) {
					MusicBeatState.switchState(new TitleState());
				});
			}

			if (controls.ACCEPT)
			{
				selectEntry();
			}
			else if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
		}

		// Menü pozisyonları
		updateMenuPositions(elapsed, lerpVal);
	}
	
	function updateVHSEffects(elapsed:Float)
	{
		// REC yanıp sönme
		if(frameCounter % 30 == 0)
		{
			recIndicator.visible = !recIndicator.visible;
			recText.alpha = recIndicator.visible ? 1 : 0.3;
		}
		
		// Statik noise
		if(staticTimer > 0.05)
		{
			staticTimer = 0;
			staticOverlay.alpha = FlxMath.lerp(staticOverlay.alpha, 0.02, 0.1);
			
			// Rastgele dead pixel
			if(FlxG.random.bool(5))
			{
				var pixel = deadPixels[FlxG.random.int(0, deadPixels.length - 1)];
				pixel.visible = !pixel.visible;
			}
		}
		
		// Tracking offset
		trackingOffset = Math.sin(vhsTimer * 2) * 2;
		menuPanel.x = 45 + trackingOffset * 0.5;
		
		// Tracking text güncelle
		var trackingLevel = Std.int(Math.abs(Math.sin(vhsTimer)) * 8);
		var trackingBar = "";
		for(i in 0...8)
		{
			trackingBar += i < trackingLevel ? "█" : "░";
		}
		trackingText.text = "TRACKING " + trackingBar;
		
		// Rastgele küçük glitch
		if(FlxG.random.bool(0.2) && !isGlitching)
		{
			triggerVHSGlitch(0.05);
		}
		
		// Color bleeding pulse
		colorBleeding.alpha = 0.05 + Math.sin(vhsTimer * 3) * 0.03;
		
		// Channel değişimi efekti
		if(FlxG.random.bool(0.1))
		{
			channelText.text = "CH-" + StringTools.lpad(Std.string(FlxG.random.int(0, 99)), "0", 2);
		}
		else
		{
			channelText.text = "CH-00";
		}
		
		// Emergency text glitch
		if(FlxG.random.bool(0.3))
		{
			emergencyText.x = FlxG.random.float(-2, 2);
		}
		else
		{
			emergencyText.x = 0;
		}
	}
	
	function updateMenuPositions(elapsed:Float, lerpVal:Float)
	{
		var startY = 250;
		var spacing = 55;
		
		menuItems.forEach(function(spr:FlxSpriteGroup)
		{
			var targetY = startY + spr.ID * spacing;
			spr.y = FlxMath.lerp(spr.y, targetY, lerpVal);
			
			if (spr.ID == curSelected) {
				spr.x = FlxMath.lerp(spr.x, 55, lerpVal);
				spr.alpha = 1;
				
				// VHS titreme
				spr.x += Math.sin(vhsTimer * 10) * FlxG.random.float(0, 0.5);
				
				selectionGlow.y = FlxMath.lerp(selectionGlow.y, spr.y - 3, lerpVal);
				selectionBar.y = FlxMath.lerp(selectionBar.y, spr.y + 3, lerpVal);
			} else {
				spr.x = FlxMath.lerp(spr.x, 50, lerpVal);
				spr.alpha = 0.5;
			}
		});
		
		// Selection glow pulse
		selectionGlow.alpha = 0.08 + Math.sin(vhsTimer * 4) * 0.04;
		selectionBar.alpha = 0.6 + Math.sin(vhsTimer * 6) * 0.4;
	}

	function changeItem(change:Int = 0)
	{
		curSelected += change;
		if (curSelected >= menuItems.length) curSelected = 0;
		if (curSelected < 0) curSelected = menuItems.length - 1;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		// VHS kanal değişimi efekti
		triggerVHSGlitch(0.1);
		channelText.text = "CH-0" + (curSelected + 1);

		var choice:String = optionShit[curSelected];
		
		// Program bilgisini güncelle
		programTitle.text = menuTitles.exists(choice) ? menuTitles.get(choice) : "PROGRAM";
		programDesc.text = menuDescriptions.exists(choice) ? menuDescriptions.get(choice) : "";
		
		// Uyarı
		if(FlxG.random.bool(30))
		{
			programWarning.text = "⚠ " + technicalMessages[FlxG.random.int(0, technicalMessages.length - 1)];
		}
		else
		{
			programWarning.text = "";
		}
		
		// Animasyon
		programTitle.alpha = 0;
		programDesc.alpha = 0;
		FlxTween.tween(programTitle, {alpha: 1}, 0.3);
		FlxTween.tween(programDesc, {alpha: 1}, 0.5);
	}

	function selectEntry()
	{
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound('confirmMenu'));
		
		// VHS durma efekti
		triggerVHSGlitch(0.5);
		playIcon.text = "■ DUR";

		menuItems.forEach(function(spr:FlxSpriteGroup)
		{
			if (curSelected != spr.ID)
			{
				FlxTween.tween(spr, {alpha: 0, x: -100}, 0.5, {ease: FlxEase.quadIn});
			}
			else
			{
				FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
				{
					// Sinyal kaybı geçişi
					signalLoss.alpha = 1;
					noSignalText.text = "KANAL DEĞİŞTİRİLİYOR...";
					noSignalText.alpha = 1;
					
					new FlxTimer().start(0.5, function(tmr:FlxTimer) {
						var daChoice:String = optionShit[curSelected];
						switch (daChoice)
						{
							case 'hikaye_modu': MusicBeatState.switchState(new StoryMenuState());
							case 'serbest_oyun': MusicBeatState.switchState(new FreeplayState());
							#if MODS_ALLOWED
							case 'modlar': MusicBeatState.switchState(new ModsMenuState());
							#end
							case 'basarimlar': MusicBeatState.switchState(new AchievementsMenuState());
							case 'yapimcilar': MusicBeatState.switchState(new CreditsState());
							case 'ayarlar': 
								MusicBeatState.switchState(new OptionsState());
								OptionsState.onPlayState = false;
							case 'galeri': MusicBeatState.switchState(new GalleryState());
						}
					});
				});
			}
		});

		// UI çıkış
		FlxTween.tween(menuBorder, {x: -400}, 0.5, {ease: FlxEase.backIn});
		FlxTween.tween(menuPanel, {x: -400}, 0.5, {ease: FlxEase.backIn});
		FlxTween.tween(infoBorder, {x: FlxG.width + 50}, 0.5, {ease: FlxEase.backIn});
		FlxTween.tween(infoPanel, {x: FlxG.width + 50}, 0.5, {ease: FlxEase.backIn});
		FlxTween.tween(warningStripes, {y: -100}, 0.5, {ease: FlxEase.backIn});
		FlxTween.tween(emergencyHeader, {y: -100}, 0.5, {ease: FlxEase.backIn});
		FlxTween.tween(bottomBar, {y: FlxG.height + 50}, 0.5, {ease: FlxEase.backIn});
	}

	function handleCheats(elapsed:Float)
	{
		var upNow = controls.UI_UP_P;
		var rightNow = controls.UI_RIGHT_P;
		var leftNow = controls.UI_LEFT_P;

		if (upNow && !prevUp) { cheatSequence.push(0); cheatLastInputTime = 0; }
		if (rightNow && !prevRight) { cheatSequence.push(3); cheatLastInputTime = 0; }
		if (leftNow && !prevLeft) { cheatSequence.push(2); cheatLastInputTime = 0; }

		prevUp = upNow; prevRight = rightNow; prevLeft = leftNow;
		cheatLastInputTime += elapsed;
		if (cheatLastInputTime > cheatTimeout) cheatSequence = [];

		if (cheatSequence.length > cheatPattern.length) cheatSequence.shift();
		if (cheatSequence.toString() == cheatPattern.toString()) {
			selectedSomethin = true;
			
			// Korku geçişi
			triggerHiddenMessage();
			triggerSignalLoss();
			
			new FlxTimer().start(2.5, function(tmr:FlxTimer) {
				MusicBeatState.switchState(new CodeMenuState());
			});
		}
	}
}