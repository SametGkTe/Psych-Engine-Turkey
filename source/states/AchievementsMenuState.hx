package states;

import flixel.FlxObject;
import flixel.util.FlxSort;
import objects.Bar;
import flixel.util.FlxSpriteUtil;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import objects.Alphabet;

#if ACHIEVEMENTS_ALLOWED
class AchievementsMenuState extends MusicBeatState
{
	public var curSelected:Int = 0;
	public var options:Array<Dynamic> = [];
	private var achievementItems:FlxTypedGroup<AchievementItem>; // Yeni liste grubu
	
	// MODERN UI ELEMENTLERİ
	var sideBarBG:FlxSprite;
	var sideBarWidth:Int = 450;
	var showcaseIcon:FlxSprite; // Sağ taraftaki dev ikon
	
	var nameText:FlxText;
	var descText:FlxText;
	var progressTxt:FlxText;
	var progressBar:Bar; // Orijinal Bar sınıfını koruduk ama görseli değiştik
	var statsText:FlxText; // Toplam tamamlanma oranı

	var camFollow:FlxObject;
	var cameraTween:FlxTween = null; // Camera tween için
	var showcaseIconTween:FlxTween = null; // Showcase icon pop tween için

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Achievements Menu - Modernized", null);
		#end

		// 1. VERİ HAZIRLIĞI
		var totalUnlocked:Int = 0;
		for (achievement => data in Achievements.achievements)
		{
			var unlocked:Bool = Achievements.isUnlocked(achievement);
			if(data.hidden != true || unlocked)
				options.push(makeAchievement(achievement, data, unlocked, data.mod));
			
			if(unlocked) totalUnlocked++;
		}
		options.sort(function(a, b) return sortByID(a, b));

		// 2. ARKA PLAN
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.scrollFactor.set();
		menuBG.color = 0xFF444444; // Biraz karartalım
		add(menuBG);

		// 3. SIDEBAR (SOL LİSTE ALANI)
		sideBarBG = new FlxSprite(0, 0).makeGraphic(sideBarWidth, FlxG.height, FlxColor.BLACK);
		sideBarBG.alpha = 0.6;
		sideBarBG.scrollFactor.set();
		add(sideBarBG);

		var separator = new FlxSprite(sideBarWidth, 0).makeGraphic(4, FlxG.height, FlxColor.WHITE);
		separator.alpha = 0.2;
		separator.scrollFactor.set();
		add(separator);

		// 4. LİSTE ÖĞELERİ (AchievementItem Class kullanacağız)
		achievementItems = new FlxTypedGroup<AchievementItem>();
		add(achievementItems);

		for (i in 0...options.length)
		{
			var option = options[i];
			var item = new AchievementItem(0, 0, option);
			item.targetY = i; // Sıralamasını ata
			item.ID = i;
			// Listeyi sidebar içine yerleştir
			item.x = 20;
			item.y = 100 + (i * 110);
			item.scale.set(0.8, 0.8);
			item.scrollFactor.set(0, 1); // Sol kısım sabit, dikey kaydırma var
			achievementItems.add(item);
		}

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.scrollFactor.set(0, 1); // Sadece Y ekseni kamerayı takip etsin
		add(camFollow);

		// 5. SAĞ TARAF - VITRIN (SHOWCASE)
		var rightCenter = sideBarWidth + (FlxG.width - sideBarWidth) / 2;

		// Ikon (Devasa)
		showcaseIcon = new FlxSprite();
		showcaseIcon.antialiasing = ClientPrefs.data.antialiasing;
		showcaseIcon.scrollFactor.set();
		add(showcaseIcon);

		// İsim
		nameText = new FlxText(sideBarWidth + 50, 50, FlxG.width - sideBarWidth - 100, "", 42);
		nameText.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		nameText.borderSize = 3;
		nameText.scrollFactor.set();
		add(nameText);

		// Açıklama
		descText = new FlxText(sideBarWidth + 50, FlxG.height - 200, FlxG.width - sideBarWidth - 100, "", 24);
		descText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.borderSize = 2;
		descText.scrollFactor.set();
		add(descText);

		// Progress Bar
		progressBar = new Bar(0, descText.y + 80, 'healthBar', function() return options[curSelected].curProgress, 0, options[curSelected].maxProgress > 0 ? options[curSelected].maxProgress : 1);
		progressBar.screenCenter(X);
		progressBar.x = rightCenter - (progressBar.width / 2); // Manuel ortalama çünkü screenCenter tüm ekranı baz alır
		progressBar.scrollFactor.set();
		progressBar.enabled = false; // Bar sınıfının update'ini manuel çağıracağız tween için
		progressBar.leftBar.color = FlxColor.LIME; // Tamamlanan kısım yeşil
		progressBar.rightBar.color = FlxColor.BLACK; // Arka plan siyah
		add(progressBar);

		progressTxt = new FlxText(progressBar.x, progressBar.y - 30, progressBar.width, "", 24);
		progressTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		progressTxt.scrollFactor.set();
		add(progressTxt);

		// 6. YENİ ÖZELLİK: İSTATİSTİKLER (Sağ Üst Köşe)
		var percent = Math.floor((totalUnlocked / options.length) * 100);
		statsText = new FlxText(FlxG.width - 300, 20, 280, 'TAMAMLANAN: $totalUnlocked/${options.length} ($percent%)', 20);
		statsText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.YELLOW, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		statsText.scrollFactor.set();
		add(statsText);

		_changeSelection();
		
		// Başlangıç animasyonu
		FlxG.camera.follow(camFollow, null, 0.1);
		
		super.create();
	}

	function makeAchievement(achievement:String, data:Achievement, unlocked:Bool, mod:String = null)
	{
		return {
			name: achievement,
			displayName: unlocked ? Language.getPhrase('achievement_$achievement', data.name) : '???',
			description: Language.getPhrase('description_$achievement', data.description),
			curProgress: data.maxScore > 0 ? Achievements.getScore(achievement) : 0,
			maxProgress: data.maxScore > 0 ? data.maxScore : 0,
			decProgress: data.maxScore > 0 ? data.maxDecimals : 0,
			unlocked: unlocked,
			ID: data.ID,
			mod: mod
		};
	}

	public static function sortByID(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.ID, Obj2.ID);

	override function update(elapsed:Float) {
		if(options.length > 0)
		{
			// Basit Yukarı/Aşağı navigasyon (Izgara mantığı kalktı)
			if (controls.UI_UP_P) changeSelection(-1);
			if (controls.UI_DOWN_P) changeSelection(1);
			
			// Mouse Wheel desteği
			if(FlxG.mouse.wheel != 0) changeSelection(-FlxG.mouse.wheel);

			if(controls.RESET && (options[curSelected].unlocked || options[curSelected].curProgress > 0))
			{
				openSubState(new ResetAchievementSubstate());
			}
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
		
		// Kamera takibi (Dikey liste için) - Seçili öğeyi ekran ortasında tut
		if(achievementItems.members.length > 0)
		{
			var selectedItem = achievementItems.members[curSelected];
			var targetY = selectedItem.y + selectedItem.height/2;
			
			// Camera Y'sini tween ile ayarla (ekran ortasında seçili item)
			var maxScroll = Math.max(0, (achievementItems.members[achievementItems.members.length - 1].y + 110) - FlxG.height);
			var targetScroll = Math.min(Math.max(targetY - (FlxG.height / 2), 0), maxScroll);
			
			// Önceki tweeni iptal et
			if(cameraTween != null) cameraTween.cancel();
			
			// Yeni tween oluştur
			cameraTween = FlxTween.num(FlxG.camera.scroll.y, targetScroll, 0.4, {ease: FlxEase.quartOut}, function(v:Float){
				FlxG.camera.scroll.y = v;
			});
		}
		

		super.update(elapsed);
	}

	public var barTween:FlxTween = null;

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0) curSelected = options.length - 1;
		if (curSelected >= options.length) curSelected = 0;

		_changeSelection();
	}

	function _changeSelection()
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		var option = options[curSelected];
		var hasProgress = option.maxProgress > 0;

		// 1. Text Güncelle
		nameText.text = option.displayName;
		descText.text = option.description;
		progressTxt.visible = progressBar.visible = hasProgress;

		// 2. Vitrin Ikonunu Güncelle (Animasyonlu)
		var graphic = null;
		var hasAntialias = ClientPrefs.data.antialiasing;
		if(option.unlocked)
		{
			#if MODS_ALLOWED Mods.currentModDirectory = option.mod; #end
			var image:String = 'achievements/' + option.name;
			if(Paths.fileExists('images/$image-pixel.png', IMAGE))
			{
				graphic = Paths.image('$image-pixel');
				hasAntialias = false;
			}
			else graphic = Paths.image(image);
			if(graphic == null) graphic = Paths.image('unknownMod');
		}
		else graphic = Paths.image('achievements/lockedachievement');

		showcaseIcon.loadGraphic(graphic);
		showcaseIcon.antialiasing = hasAntialias;
		
		// Vitrin ikonu boyutlandırma ve ortalama
		showcaseIcon.setGraphicSize(Std.int(showcaseIcon.width * 1.7)); // 2 kat büyük
		showcaseIcon.updateHitbox();
		var rightCenter = sideBarWidth + (FlxG.width - sideBarWidth) / 2;
		showcaseIcon.setPosition(rightCenter - showcaseIcon.width / 2, (FlxG.height / 2) - showcaseIcon.height / 2 - 50);

		// POP Efekti (Tween)
		if(showcaseIconTween != null) showcaseIconTween.cancel(); // Önceki tweeni iptal et
		showcaseIcon.scale.set(0, 0);
		showcaseIconTween = FlxTween.tween(showcaseIcon.scale, {x: 2, y: 2}, 0.4, {ease: FlxEase.elasticOut});

		// 3. Progress Bar Tween
		if(barTween != null) barTween.cancel();
		if(hasProgress)
		{
			var val1:Float = option.curProgress;
			var val2:Float = option.maxProgress;
			progressTxt.text = CoolUtil.floorDecimal(val1, option.decProgress) + ' / ' + CoolUtil.floorDecimal(val2, option.decProgress);
			
			var startPercent = progressBar.percent;
			var endPercent = (val1 / val2) * 100;
			progressBar.percent = 0; // Görsel efekt için sıfırdan başlat
			
			barTween = FlxTween.num(0, endPercent, 0.5, {ease: FlxEase.quartOut}, function(v:Float)
			{
				progressBar.percent = v;
				progressBar.updateBar();
			});
		}
		else 
		{
			progressBar.percent = 0;
			progressBar.updateBar();
		}

		// 4. Liste Elemanlarını Güncelle (Highlight)
		for (i in 0...achievementItems.members.length)
		{
			var item = achievementItems.members[i];
			if(i == curSelected)
			{
				item.alpha = 1;
				item.bg.color = 0xFFFFFFFF; // Seçiliyse Parlak
				item.bg.alpha = 0.2;
				item.scale.set(1.05, 1.05); // Hafif büyüt
			}
			else
			{
				item.alpha = 0.6;
				item.bg.color = 0xFF000000;
				item.bg.alpha = 0.4;
				item.scale.set(1, 1);
			}
		}
		#if MODS_ALLOWED Mods.loadTopMod(); #end
	}
}

// YENİ CLASS: LİSTE ÖĞESİ TASARIMI
class AchievementItem extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var icon:FlxSprite;
	public var text:FlxText;
	public var targetY:Int = 0;
	
	public function new(x:Float, y:Float, data:Dynamic)
	{
		super(x, y);

		// Arka plan şeridi
		bg = new FlxSprite().makeGraphic(410, 100, FlxColor.WHITE);
		bg.alpha = 0.4;
		bg.color = FlxColor.BLACK;
		// Yuvarlak köşeler için drawRoundRect kullanılabilir ama performans için basit tutalım
		// veya flixel-addons varsa: FlxSpriteUtil.drawRoundRect(bg, ...);
		add(bg);

		// Küçük ikon
		icon = new FlxSprite(10, 10);
		var graphic = null;
		var hasAntialias = ClientPrefs.data.antialiasing;
		
		if(data.unlocked)
		{
			#if MODS_ALLOWED Mods.currentModDirectory = data.mod; #end
			var image:String = 'achievements/' + data.name;
			if(Paths.fileExists('images/$image-pixel.png', IMAGE))
			{
				graphic = Paths.image('$image-pixel');
				hasAntialias = false;
			}
			else graphic = Paths.image(image);
			if(graphic == null) graphic = Paths.image('unknownMod');
		}
		else graphic = Paths.image('achievements/lockedachievement');
		
		icon.loadGraphic(graphic);
		icon.antialiasing = hasAntialias;
		icon.setGraphicSize(40, 40); // Daha küçük ikon
		icon.updateHitbox();
		add(icon);

		// İsim
		text = new FlxText(55, 0, 345, data.displayName, 24);
		text.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.borderSize = 1.5;
		text.y = (bg.height - text.height) / 2; // Dikey ortala
		add(text);
	}
}

class ResetAchievementSubstate extends MusicBeatSubstate
{
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;

	public function new()
	{
		super();
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		
		var text:Alphabet = new Alphabet(0, 180, Language.getPhrase('reset_achievement', 'Reset Achievement:'), true);
		text.screenCenter(X);
		text.scrollFactor.set();
		add(text);
		
		var state:AchievementsMenuState = cast FlxG.state;
		var text:FlxText = new FlxText(50, text.y + 90, FlxG.width - 100, state.options[state.curSelected].displayName, 40);
		text.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.scrollFactor.set();
		text.borderSize = 2;
		add(text);
		
		yesText = new Alphabet(0, text.y + 120, Language.getPhrase('Yes'), true);
		yesText.screenCenter(X);
		yesText.x -= 200;
		yesText.scrollFactor.set();
		for(letter in yesText.letters) letter.color = FlxColor.RED;
		add(yesText);
		noText = new Alphabet(0, text.y + 120, Language.getPhrase('No'), true);
		noText.screenCenter(X);
		noText.x += 200;
		noText.scrollFactor.set();
		add(noText);
		updateOptions();
	}

	override function update(elapsed:Float)
	{
		if(controls.BACK)
		{
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}

		super.update(elapsed);

		if(controls.UI_LEFT_P || controls.UI_RIGHT_P) {
			onYes = !onYes;
			updateOptions();
		}

		if(controls.ACCEPT)
		{
			if(onYes)
			{
				var state:AchievementsMenuState = cast FlxG.state;
				var option:Dynamic = state.options[state.curSelected];

				Achievements.variables.remove(option.name);
				Achievements.achievementsUnlocked.remove(option.name);
				option.unlocked = false;
				option.curProgress = 0;
				option.displayName = '???'; // name'i değil displayname'i güncelle
				state.options[state.curSelected].displayName = '???';
				
				// State güncelleme işlemleri manuel yapılacak çünkü updateModDisplayData yok
				Achievements.save();
				FlxG.save.flush();
				
				// Seçimi yenile ki grafikler güncellensin
				@:privateAccess state._changeSelection();

				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			close();
			return;
		}
	}

	function updateOptions() {
		var scales:Array<Float> = [0.75, 1];
		var alphas:Array<Float> = [0.6, 1.25];
		var confirmInt:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}
#end