package states;

import backend.Discord;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.util.FlxGradient;
import objects.AttachedSprite;
import states.ThanksCreditsState;
import states.MysteryConfirmState;
import flixel.effects.FlxFlicker;

class CreditsState extends MusicBeatState
{
	// Veri Değişkenleri
	private var creditsStuff:Array<Array<String>> = [];
	var curSelected:Int = 0;
	var curLinkSelected:Int = 0;
	var inLinkSelection:Bool = false;

	// --- GÖRSEL NESNELER ---
	
	// Arka Planlar
	var bg:FlxSprite;
	var gridBG:FlxBackdrop;
	var rightSideCover:FlxSprite;
	var leftPanel:FlxSprite;
	var gradientOverlay:FlxSprite;
	
	// GİZEMLİ TEMA DEĞİŞKENLERİ
	var mysteryOverlay:FlxSprite;
	var glitchTimer:Float = 0;
	var isMysteryCredit:Bool = false;
	var staticNoise:FlxSprite;
	var eyeSprite:FlxSprite;
	var mysteryParticles:Array<FlxSprite> = [];
	
	// Sağ Taraf (Karakter Vitrini)
	var charIcon:FlxSprite;
	var charName:Alphabet;
	var charRoleBox:FlxSprite;
	var charRole:FlxText;

	// Sol Taraf (Linkler ve Liste)
	var leftName:FlxText;
	var leftNameShadow:FlxText;
	
	var linkContainers:Array<{name:String, container:FlxSprite, icon:FlxSprite, text:FlxText, url:String}> = [];
	var activeLinkIndices:Array<Int> = [];
	
	var helpText:FlxText;
	var helpBg:FlxSprite;

	var intendedColor:FlxColor;
	
	var currentLinks:Map<String, String> = [
		"youtube" => "",
		"tiktok" => "",
		"twitter" => "",
		"github" => "",
		"gamebanana" => "",
		"discord" => ""
	];

	var SPLIT_X:Int = 640;

	// Gizemli uyarı metni
	var mysteryWarningText:FlxText;
	var warningAlpha:Float = 0;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Credits Menüsünde", null);
		#end

		persistentUpdate = true;
		
		// 1. Ana Arka Plan
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.screenCenter();
		add(bg);

		// 2. Sağ Taraf Kapağı
		rightSideCover = new FlxSprite(SPLIT_X, 0).makeGraphic(FlxG.width - SPLIT_X, FlxG.height, FlxColor.WHITE);
		rightSideCover.antialiasing = ClientPrefs.data.antialiasing;
		add(rightSideCover);

		// 3. Grid
		gridBG = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x22FFFFFF, 0x0));
		gridBG.velocity.set(30, 30);
		gridBG.alpha = 0;
		FlxTween.tween(gridBG, {alpha: 1}, 0.8, {ease: FlxEase.quartOut});
		add(gridBG);
		
		// 4. Gradient Overlay
		gradientOverlay = FlxGradient.createGradientFlxSprite(
			SPLIT_X, 
			FlxG.height, 
			[0x00000000, 0x33000000, 0x66000000], 
			1, 
			0
		);
		add(gradientOverlay);
		
		// 5. Sol Panel
		leftPanel = new FlxSprite(0, 0).makeGraphic(SPLIT_X, FlxG.height, FlxColor.BLACK);
		leftPanel.alpha = 0.3;
		add(leftPanel);

		// --- GİZEMLİ TEMA ELEMANlARI ---
		
		// Statik gürültü efekti
		staticNoise = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		staticNoise.alpha = 0;
		add(staticNoise);
		
		// Karanlık overlay
		mysteryOverlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF1a0a0a);
		mysteryOverlay.alpha = 0;
		add(mysteryOverlay);
		
		// Göz sprite (gizemli credit için)
		eyeSprite = new FlxSprite(0, 0);
		if(Paths.fileExists('images/credits/mystery_eye.png', IMAGE))
			eyeSprite.loadGraphic(Paths.image('credits/mystery_eye'));
		else
			eyeSprite.makeGraphic(100, 100, FlxColor.RED);
		eyeSprite.alpha = 0;
		eyeSprite.screenCenter();
		add(eyeSprite);
		
		// Gizemli uyarı metni
		mysteryWarningText = new FlxText(0, FlxG.height - 150, FlxG.width, "", 20);
		mysteryWarningText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		mysteryWarningText.borderSize = 2;
		mysteryWarningText.alpha = 0;
		add(mysteryWarningText);

		// --- MODLARI YÜKLE ---
		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled) pushModCreditsToList(mod);
		#end
		
		if (creditsStuff.length == 0)
			pushDefaultCredits();

		// --- SAĞ TARAF NESNELERİ ---
		
		// İkon
		charIcon = new FlxSprite(0, 0);
		charIcon.antialiasing = ClientPrefs.data.antialiasing;
		add(charIcon);

		// Büyük İsim
		charName = new Alphabet(0, 0, "", true);
		charName.scaleX = 0.8;
		charName.scaleY = 0.8;
		add(charName);

		// Rol Kutusu
		charRoleBox = FlxGradient.createGradientFlxSprite(
			FlxG.width - SPLIT_X, 
			120, 
			[0x00000000, 0xAA000000, 0xDD000000], 
			1, 
			90
		);
		charRoleBox.x = SPLIT_X;
		charRoleBox.y = FlxG.height - 120;
		add(charRoleBox);

		// Rol Yazısı
		charRole = new FlxText(SPLIT_X + 20, FlxG.height - 85, (FlxG.width - SPLIT_X) - 40, "", 24);
		charRole.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		charRole.borderSize = 2.5;
		add(charRole);

		// --- SOL TARAF NESNELERİ ---
		
		// İsim Gölgesi
		leftNameShadow = new FlxText(5, 105, SPLIT_X, "Name", 52);
		leftNameShadow.setFormat(Paths.font("vcr.ttf"), 52, 0xFF000000, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		leftNameShadow.alpha = 0.3;
		add(leftNameShadow);
		
		// Sol Üst İsim
		leftName = new FlxText(10, 100, SPLIT_X - 20, "Name", 52);
		leftName.setFormat(Paths.font("vcr.ttf"), 52, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		leftName.borderSize = 3;
		add(leftName);
		
		// Linkler
		initializeLinkContainers();
		
		// Yardım Metni Arka Planı
		helpBg = new FlxSprite(0, FlxG.height - 70).makeGraphic(SPLIT_X, 70, 0xAA000000);
		add(helpBg);
		
		// Yardım Metni
		helpText = new FlxText(10, FlxG.height - 60, SPLIT_X - 20, "değiştirmek için ^ veya v tuşlarını kullanın\nCTRL: Credits Akışını İzle", 16);
		helpText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		helpText.alignment = CENTER;
		helpText.alpha = 1;
		add(helpText);

		// Partiküller oluştur (gizemli tema için)
		createMysteryParticles();

		changeSelection();
		super.create();
	}

	function createMysteryParticles()
	{
		for(i in 0...20)
		{
			var particle = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			particle.makeGraphic(Std.int(FlxG.random.float(2, 6)), Std.int(FlxG.random.float(2, 6)), FlxColor.RED);
			particle.alpha = 0;
			particle.velocity.y = FlxG.random.float(-50, -20);
			particle.velocity.x = FlxG.random.float(-10, 10);
			add(particle);
			mysteryParticles.push(particle);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (FlxG.sound.music.volume < 0.7) FlxG.sound.music.volume += 0.5 * elapsed;
		
		// GİZEMLİ TEMA GÜNCELLEME
		updateMysteryEffects(elapsed);
		
		// Mouse Scroll Desteği
		#if desktop
		if(FlxG.mouse.wheel != 0)
		{
			if(!inLinkSelection)
			{
				changeSelection(-FlxG.mouse.wheel);
			}
			else
			{
				changeLinkSelection(FlxG.mouse.wheel);
			}
		}
		#end
		
		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var leftP = controls.UI_LEFT_P;
		var rightP = controls.UI_RIGHT_P;
		var accept = controls.ACCEPT;
		var back = controls.BACK;

		// CTRL ile Credits Roll açma
		if(FlxG.keys.justPressed.CONTROL)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			MusicBeatState.switchState(new ThanksCreditsState());
			return;
		}

		if (back)
		{
			if(inLinkSelection)
			{
				toggleLinkSelection(false);
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
			return;
		}

		if (!inLinkSelection)
		{
			if (upP) changeSelection(-1);
			if (downP) changeSelection(1);
			
			if ((leftP || accept) && !isHeader(curSelected))
			{
				// GİZEMLİ CREDIT KONTROLÜ - "tumU" veya "Tumu" ismine basıldığında
				var currentName = creditsStuff[curSelected][0].toLowerCase();
				if(currentName == "tumu" || currentName == "tumu")
				{
					triggerMysterySequence();
					return;
				}
				
				toggleLinkSelection(true);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
		}
		else
		{
			if (upP || downP) changeLinkSelection(1);
			
			if (rightP)
			{
				toggleLinkSelection(false);
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}

			if (accept)
			{
				var linkToOpen:String = getSelectedLinkUrl();
				if(linkToOpen != null && linkToOpen.length > 4)
				{
					CoolUtil.browserLoad(linkToOpen);
				}
				else
				{
					FlxG.camera.shake(0.005, 0.5);
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			}
		}
	}
	
	// GİZEMLİ SEKANS BAŞLATMA
	function triggerMysterySequence()
	{
		// Glitch efekti
		FlxG.camera.shake(0.02, 0.5);
		
		// Korkutucu ses (varsa)
		if(Paths.fileExists('sounds/mystery_trigger.ogg', SOUND))
			FlxG.sound.play(Paths.sound('mystery_trigger'));
		else
			FlxG.sound.play(Paths.sound('confirmMenu'));
		
		// Ekran kararması efekti
		FlxTween.tween(mysteryOverlay, {alpha: 1}, 0.5, {
			ease: FlxEase.quartIn,
			onComplete: function(twn:FlxTween) {
				// MysteryConfirmState'e geç
				MusicBeatState.switchState(new MysteryConfirmState());
			}
		});
	}
	
	// GİZEMLİ EFEKTLER GÜNCELLEME
	function updateMysteryEffects(elapsed:Float)
	{
		var currentName = "";
		if(creditsStuff.length > 0 && curSelected < creditsStuff.length)
			currentName = creditsStuff[curSelected][0].toLowerCase();
		
		isMysteryCredit = (currentName == "tumu" || currentName == "tumu");
		
		if(isMysteryCredit)
		{
			glitchTimer += elapsed;
			
			// Overlay karartma
			mysteryOverlay.alpha = FlxMath.lerp(mysteryOverlay.alpha, 0.4, 0.05);
			
			// Statik gürültü
			if(glitchTimer > 0.1)
			{
				glitchTimer = 0;
				staticNoise.alpha = FlxG.random.float(0, 0.15);
				
				// Rastgele glitch
				if(FlxG.random.bool(5))
				{
					FlxG.camera.shake(0.005, 0.1);
				}
			}
			
			// Uyarı metni
			mysteryWarningText.text = getRandomWarningText();
			mysteryWarningText.alpha = FlxMath.lerp(mysteryWarningText.alpha, 0.7 + Math.sin(glitchTimer * 5) * 0.3, 0.1);
			
			// Partiküller
			for(p in mysteryParticles)
			{
				p.alpha = FlxMath.lerp(p.alpha, 0.6, 0.05);
				if(p.y < -10)
				{
					p.y = FlxG.height + 10;
					p.x = FlxG.random.float(0, FlxG.width);
				}
			}
			
			// Göz efekti (rastgele görünme)
			if(FlxG.random.bool(0.5))
			{
				eyeSprite.alpha = 0.3;
				eyeSprite.x = FlxG.random.float(0, FlxG.width - 100);
				eyeSprite.y = FlxG.random.float(0, FlxG.height - 100);
				FlxTween.tween(eyeSprite, {alpha: 0}, 0.5);
			}
			
			// İsim titremesi
			if(leftName != null)
			{
				leftName.x = (SPLIT_X / 2) - (leftName.width / 2) + FlxG.random.float(-2, 2);
				leftName.color = FlxG.random.bool(10) ? FlxColor.RED : FlxColor.WHITE;
			}
			
			// Grid'i kırmızıya çevir
			gridBG.color = FlxColor.interpolate(gridBG.color, 0xFF330000, 0.05);
		}
		else
		{
			// Normal duruma dön
			mysteryOverlay.alpha = FlxMath.lerp(mysteryOverlay.alpha, 0, 0.1);
			staticNoise.alpha = FlxMath.lerp(staticNoise.alpha, 0, 0.1);
			mysteryWarningText.alpha = FlxMath.lerp(mysteryWarningText.alpha, 0, 0.1);
			eyeSprite.alpha = 0;
			
			for(p in mysteryParticles)
			{
				p.alpha = FlxMath.lerp(p.alpha, 0, 0.1);
			}
			
			gridBG.color = FlxColor.interpolate(gridBG.color, FlxColor.WHITE, 0.05);
			
			if(leftName != null)
				leftName.color = FlxColor.WHITE;
		}
	}
	
	function getRandomWarningText():String
	{
		var warnings = [
			"Bunu Yapmak İstediğinden Eminmisin?",
			"GERİ DÖNÜŞ YOK...",
			"DEVAM ET... EĞER CESARETİN VARSA...",
			"BİRİLERİ İZLİYOR...",
			"SEÇİMİNİ YAP...",
			"KARANLIK YAKLAŞIYOR...",
			"...",
			"ENTER'A BAS... EĞER HAZIRSAN..."
		];
		return warnings[Std.int(FlxG.random.float(0, warnings.length))];
	}

	override function beatHit()
	{
		super.beatHit();
		
		if(charIcon != null)
		{
			charIcon.scale.set(1.1, 1.1);
			FlxTween.tween(charIcon.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.elasticOut});
		}
		
		// Gizemli creditte ekstra beat efekti
		if(isMysteryCredit)
		{
			FlxG.camera.zoom = 1.02;
			FlxTween.tween(FlxG.camera, {zoom: 1}, 0.3, {ease: FlxEase.quartOut});
		}
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var prevSelected:Int = curSelected;

		curSelected += change;
		if (curSelected < 0) curSelected = creditsStuff.length - 1;
		if (curSelected >= creditsStuff.length) curSelected = 0;
		
		if(isHeader(curSelected))
		{
			changeSelection(change > 0 ? 1 : -1);
			return;
		}

		var data = creditsStuff[curSelected];
		
		// İsimler
		charName.text = data[0];
		
		var centerRight = SPLIT_X + ((FlxG.width - SPLIT_X) / 2);
		charName.x = centerRight - (charName.width / 2); 
		charName.y = (FlxG.height * 0.55);

		// Uzun isimlerde font boyutunu küçült
		var nameText = data[0];
		var fontSize = 52;
		if(nameText.length > 12)
		{
			fontSize = Std.int(52 * (12 / nameText.length));
			if(fontSize < 24) fontSize = 24;
		}
		
		leftName.text = nameText;
		leftName.size = fontSize;
		leftName.x = (SPLIT_X / 2) - (leftName.width / 2);
		
		// Gölgeyi güncelle
		leftNameShadow.text = nameText;
		leftNameShadow.size = fontSize;
		leftNameShadow.x = leftName.x + 3;
		leftNameShadow.y = leftName.y + 3;
		
		charRole.text = data[2];
		
		// İkon Animasyonu
		if(change != 0 && charIcon.graphic != null)
		{
			var ghostIcon:FlxSprite = new FlxSprite(charIcon.x, charIcon.y);
			ghostIcon.loadGraphic(charIcon.graphic);
			ghostIcon.scale.copyFrom(charIcon.scale);
			ghostIcon.updateHitbox();
			ghostIcon.offset.copyFrom(charIcon.offset);
			ghostIcon.antialiasing = charIcon.antialiasing;
			ghostIcon.alpha = 1;
			insert(members.indexOf(charIcon), ghostIcon);

			var slideDistance:Int = 100;
			var moveY:Int = (change == 1) ? -slideDistance : slideDistance;

			FlxTween.tween(ghostIcon, {y: charIcon.y + moveY, alpha: 0}, 0.35, {
				ease: FlxEase.quartOut,
				onComplete: function(twn:FlxTween) {
					ghostIcon.destroy();
				}
			});
		}

		// Yeni İkonu Yükle
		var iconName = data[1];
		var iconPath = 'credits/' + iconName;
		if(!Paths.fileExists('images/$iconPath.png', IMAGE)) iconPath = 'credits/missing_icon';
		
		charIcon.loadGraphic(Paths.image(iconPath));
		
		var scale = 1.0;
		if(charIcon.width > 200) scale = 0.8;
		charIcon.setGraphicSize(Std.int(charIcon.width * 1.3 * scale));
		charIcon.updateHitbox();
		
		var targetY = (FlxG.height * 0.35) - (charIcon.height / 2);
		charIcon.x = centerRight - (charIcon.width / 2);
		
		if(change != 0)
		{
			FlxTween.cancelTweensOf(charIcon);

			var startOffset:Int = (change == 1) ? 100 : -100;
			
			charIcon.y = targetY + startOffset;
			charIcon.alpha = 0;

			FlxTween.tween(charIcon, {y: targetY, alpha: 1}, 0.35, {ease: FlxEase.quartOut});
		}
		else
		{
			charIcon.y = targetY;
			charIcon.alpha = 1;
		}

		// Renk
		var newColor:FlxColor = CoolUtil.colorFromString(data[4]);
		if(newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.cancelTweensOf(rightSideCover);
			
			FlxTween.color(bg, 1, bg.color, intendedColor);
			FlxTween.color(rightSideCover, 1, rightSideCover.color, intendedColor);
		}

		parseAndCategorizeLinks(data[3]);
		updateLinkVisuals();
	}

	function initializeLinkContainers()
	{
		var linkData = [
			{name: "youtube", imageName: "yt", fallbackColor: 0xFFFF0000},
			{name: "tiktok", imageName: "tt", fallbackColor: 0xFF000000},
			{name: "twitter", imageName: "twitter", fallbackColor: 0xFF1DA1F2},
			{name: "discord", imageName: "discord", fallbackColor: 0xFF5865F2},
			{name: "github", imageName: "github", fallbackColor: 0xFF333333},
			{name: "gamebanana", imageName: "gamebanana", fallbackColor: 0xFFE1A000}
		];

		for(linkInfo in linkData)
		{
			var container = FlxGradient.createGradientFlxSprite(
				520, 
				100, 
				[0xBB111111, 0xDD000000], 
				1, 
				0
			);
			container.alpha = 0.9;
			add(container);

			var icon = new FlxSprite(0, 0);
			var iconPath = 'credits/${linkInfo.imageName}';
			if(Paths.fileExists('images/$iconPath.png', IMAGE))
			{
				icon.loadGraphic(Paths.image(iconPath));
			}
			else
			{
				icon.makeGraphic(80, 80, linkInfo.fallbackColor);
			}
			icon.setGraphicSize(80, 80);
			icon.updateHitbox();
			add(icon);

			var text = new FlxText(0, 0, 420, "@" + linkInfo.name, 32);
			text.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.borderSize = 2;
			add(text);

			linkContainers.push({
				name: linkInfo.name,
				container: container,
				icon: icon,
				text: text,
				url: ""
			});
		}
	}

	function parseAndCategorizeLinks(rawLinks:String)
	{
		for(link in linkContainers)
		{
			link.url = "";
		}
		activeLinkIndices = [];

		if(rawLinks == null || rawLinks.length == 0) return;

		var linkArray = rawLinks.split('|');

		for(linkUrl in linkArray)
		{
			if(linkUrl == null || linkUrl.length < 5) continue;

			var domain = extractDomainFromUrl(linkUrl);
			
			for(i in 0...linkContainers.length)
			{
				if(linkContainers[i].name == domain)
				{
					linkContainers[i].url = linkUrl;
					activeLinkIndices.push(i);
					break;
				}
			}
		}

		if(activeLinkIndices.length > 0)
		{
			curLinkSelected = 0;
		}
	}

	function extractDomainFromUrl(url:String):String
	{
		var domain = "unknown";

		if(url.indexOf("youtube.com") != -1 || url.indexOf("youtu.be") != -1)
			domain = "youtube";
		else if(url.indexOf("tiktok.com") != -1)
			domain = "tiktok";
		else if(url.indexOf("twitter.com") != -1 || url.indexOf("x.com") != -1)
			domain = "twitter";
		else if(url.indexOf("discord.gg") != -1 || url.indexOf("discord.com") != -1)
			domain = "discord";
		else if(url.indexOf("github.com") != -1)
			domain = "github";
		else if(url.indexOf("gamebanana.com") != -1)
			domain = "gamebanana";

		return domain;
	}

	function toggleLinkSelection(entering:Bool)
	{
		inLinkSelection = entering;
		if(entering && activeLinkIndices.length > 0)
		{
			curLinkSelected = 0;
		}
		updateLinkVisuals();
	}

	function changeLinkSelection(change:Int)
	{
		if(activeLinkIndices.length == 0) return;

		curLinkSelected += change;
		if(curLinkSelected >= activeLinkIndices.length) curLinkSelected = 0;
		if(curLinkSelected < 0) curLinkSelected = activeLinkIndices.length - 1;
		
		FlxG.sound.play(Paths.sound('scrollMenu'));
		updateLinkVisuals();
	}

	function updateLinkVisuals()
	{
		if(linkContainers.length == 0) return;

		var selectedScale = 1.08;
		var normalScale = 1.0;
		var boxCenter = (SPLIT_X - 520) / 2;

		for(container in linkContainers)
		{
			container.container.visible = false;
			container.icon.visible = false;
			container.text.visible = false;
		}

		var yPos = 250;
		var spacing = 120;

		for(idx in 0...activeLinkIndices.length)
		{
			var containerIdx = activeLinkIndices[idx];
			var linkData = linkContainers[containerIdx];

			linkData.container.visible = true;
			linkData.icon.visible = true;
			linkData.text.visible = true;

			var currentY = yPos + (idx * spacing);
			linkData.container.setPosition(boxCenter, currentY);
			linkData.icon.setPosition(boxCenter + 15, currentY + 10);
			linkData.text.setPosition(boxCenter + 105, currentY + 35);

			FlxTween.cancelTweensOf(linkData.container.scale);
			FlxTween.cancelTweensOf(linkData.icon);
			
			if(inLinkSelection && idx == curLinkSelected)
			{
				FlxTween.tween(linkData.container, {alpha: 1.0}, 0.2);
				FlxTween.tween(linkData.container.scale, {x: selectedScale, y: selectedScale}, 0.3, {ease: FlxEase.quartOut});
				FlxTween.tween(linkData.icon, {alpha: 1.0}, 0.2);
			}
			else if(inLinkSelection)
			{
				FlxTween.tween(linkData.container, {alpha: 0.5}, 0.2);
				FlxTween.tween(linkData.container.scale, {x: normalScale, y: normalScale}, 0.3, {ease: FlxEase.quartOut});
				FlxTween.tween(linkData.icon, {alpha: 0.6}, 0.2);
			}
			else
			{
				FlxTween.tween(linkData.container, {alpha: 0.7}, 0.2);
				FlxTween.tween(linkData.container.scale, {x: normalScale, y: normalScale}, 0.3, {ease: FlxEase.quartOut});
				FlxTween.tween(linkData.icon, {alpha: 0.9}, 0.2);
			}

			linkData.text.text = extractHandle(linkData.url, linkData.name);
		}

		if(inLinkSelection)
		{
			helpText.text = "Linke gitmek için ENTER'a bas / Geri dönmek için SAĞ OK TUŞUNA BASIN\nCTRL: Credits Akışını İzle";
		}
		else
		{
			helpText.text = "değiştirmek için YUKARI veya AŞAĞI tuşlarını kullanın\nCTRL: Credits Akışını İzle";
		}
	}

	function getSelectedLinkUrl():String
	{
		if(activeLinkIndices.length == 0 || curLinkSelected >= activeLinkIndices.length)
			return "";
		
		var containerIdx = activeLinkIndices[curLinkSelected];
		return linkContainers[containerIdx].url;
	}

	function extractHandle(url:String, defaultName:String):String
	{
		if(url == null || url.length < 5) return "Link Yok";
		var parts = url.split('/');
		var handle = parts[parts.length-1];
		if(handle == "") handle = parts[parts.length-2];
		return (handle.startsWith('@') ? "" : "@") + handle;
	}

	function isHeader(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}
	
	function pushDefaultCredits()
	{
		creditsStuff.push(['SametGkTe', 'gkte', 'Psych Engine Türkiye Yapımcısı / Çevirmen / Kodlayıcı', 'https://tiktok.com/@gktegameplay', '24ED13']);
		creditsStuff.push(['Umutt', 'bf', 'Umut Edition.', 'https://tiktok.com/@lxzbs0', '24ED13']);
		// ... diğer creditler ...
		creditsStuff.push(['tumU', 'gf', '.noitidE tumU', 'https://tiktok.com/@lxzbs0', 'fe0725']);
	}

	#if MODS_ALLOWED
	function pushModCreditsToList(folder:String)
	{
		var creditsFile:String = Paths.mods(folder + '/data/credits.txt');
		#if TRANSLATIONS_ALLOWED
		var translatedCredits:String = Paths.mods(folder + '/data/credits-${ClientPrefs.data.language}.txt');
		#end

		if (#if TRANSLATIONS_ALLOWED (FileSystem.exists(translatedCredits) && (creditsFile = translatedCredits) == translatedCredits) || #end FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for(i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if(arr.length >= 5) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
	}
	#end
}