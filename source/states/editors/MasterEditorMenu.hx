package states.editors;

import backend.WeekData;
import objects.Character;
import states.MainMenuState;
import states.FreeplayState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxBackdrop;

// ===== TYPE DEFINITIONS =====
typedef EditorInfo = {
	var title:String;
	var editor:String;
	var icon:String;
	var desc:String;
}

typedef EditorCategory = {
	var name:String;
	var color:Int;
	var icon:String;
	var editors:Array<EditorInfo>;
}

typedef RecentEditorData = {
	var editorName:String;
	var timestamp:Float;
}

class MasterEditorMenu extends MusicBeatState
{
	// ===== EDITOR DEFINITIONS =====
	private var editorCategories:Array<EditorCategory> = [
		{
			name: "MÜZIK & GRAFIK",
			color: 0xFF00D4FF,
			icon: "🎵",
			editors: [
				{title: "Chart Düzenleyici", editor: 'Chart Düzenleyici', icon: "🎵", desc: "Notaları ve timing'i düzenleyin"},
				{title: "Nota Efekti Düzenleyici", editor: 'Nota Efekti Düzenleyici', icon: "✨", desc: "Nota splash efektlerini özelleştirin"}
			]
		},
		{
			name: "KARAKTER",
			color: 0xFFFF6B6B,
			icon: "👤",
			editors: [
				{title: "Karakter Düzenleyici", editor: 'Karakter Düzenleyici', icon: "👤", desc: "Karakter animasyonlarını düzenleyin"},
				{title: "Menü Karakter Düzenleyici", editor: 'Menü Karakter Düzenleyici', icon: "🎭", desc: "Menü karakterlerini özelleştirin"}
			]
		},
		{
			name: "SAHNE",
			color: 0xFF4ECDC4,
			icon: "🎬",
			editors: [
				{title: "Sahne Düzenleyici", editor: 'Sahne Düzenleyici', icon: "🎬", desc: "Sahne tasarımlarını oluşturun"},
				{title: "Hafta Düzenleyici", editor: 'Hafta Düzenleyici', icon: "📅", desc: "Hafta içeriğini ayarlayın"}
			]
		},
		{
			name: "DIYALOG",
			color: 0xFFFFBB33,
			icon: "💬",
			editors: [
				{title: "Diyalog Düzenleyici", editor: 'Diyalog Düzenleyici', icon: "💬", desc: "Diyalog senaryo yaz"},
				{title: "Portre Diyalog Düzenleyici", editor: 'Portre Diyalog Düzenleyici', icon: "🖼️", desc: "Portre şekillerini düzenleyin"}
			]
		},
		{
			name: "MENÜ DÜZENLEYICI",
			color: 0xFFFFBC90,
			icon: "💬",
			editors: [
				{title: "Diyalog Düzenleyici", editor: 'Diyalog Düzenleyici', icon: "💬", desc: "Diyalog senaryo yaz"},
				{title: "Portre Diyalog Düzenleyici", editor: 'Portre Diyalog Düzenleyici', icon: "🖼️", desc: "Portre şekillerini düzenleyin"}
			]
		}
	];

	// ===== UI ELEMENTS =====
	private var grpEditorCards:FlxTypedGroup<FlxSprite>;
	private var selectedCard:FlxSprite;
	private var selectedCategoryIndex:Int = 0;
	private var selectedEditorIndex:Int = 0;

	private var directoryTxt:FlxText;
	private var descriptionTxt:FlxText;
	private var categoryTitle:Alphabet;
	private var searchInput:FlxText;
	private var searchMode:Bool = false;

	// ===== STATE MANAGEMENT =====
	private var directories:Array<String> = [null];
	private var curDirectory:Int = 0;
	private var filteredEditors:Array<{cat:Int, ed:Int}> = [];
	private var recentEditors:Array<RecentEditorData> = [];

	// ===== ANIMATION & VISUAL =====
	private var transitionTimer:Float = 0;
	private var hoverScale:Float = 1.0;
	private var categoryScroll:Float = 0;
	private var maxCategoryScroll:Float = 0;

	// ===== KEYBOARD SHORTCUTS =====
	private var shortcutDisplay:FlxText;

	override function create()
	{
		FlxG.camera.bgColor = 0xFF0A0E27;
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Editor Merkezi (Master Editor)", null);
		#end

		initializeBackground();
		initializePanels();
		initializeCategorySystem();
		initializeEditorCards();
		initializeUIElements();
		loadRecentEditors();
		selectEditor(0, 0);

		FlxG.mouse.visible = true;
		super.create();
	}

	// ===== INITIALIZATION FUNCTIONS =====

	function initializeBackground()
	{
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF0F1419;
		bg.scrollFactor.set();
		add(bg);

		// Animated grid backdrop
		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(100, 100, 200, 200, true, 0x11FFFFFF, 0x0));
		grid.velocity.set(-25, -25);
		grid.scrollFactor.set();
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 0.3}, 1.0, {ease: FlxEase.quadOut});
		add(grid);

		// Gradient overlay
		var gradientOverlay:FlxSprite = new FlxSprite(0, FlxG.height - 200).makeGraphic(FlxG.width, 200, FlxColor.BLACK);
		gradientOverlay.alpha = 0;
		gradientOverlay.scrollFactor.set();
		add(gradientOverlay);
	}

	function initializePanels()
	{
		// Top bar with title
		var topBar:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, 100, 0xFF1A1F33);
		topBar.alpha = 0.95;
		topBar.scrollFactor.set();
		add(topBar);

		var subtitleText:FlxText = new FlxText(40, 75, 0, 'OYUN DÜZENLEYİCİLER', 20);
		subtitleText.setFormat(Paths.font("vcr.ttf"), 20, 0xFF888888, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		subtitleText.borderSize = 1;
		subtitleText.scrollFactor.set();
		add(subtitleText);

		// Left sidebar - Categories
		var leftBar:FlxSprite = new FlxSprite(0, 100).makeGraphic(280, FlxG.height - 100, 0xFF1A1F33);
		leftBar.alpha = 0.85;
		leftBar.scrollFactor.set();
		add(leftBar);

		// Right panel - Info
		var rightPanel:FlxSprite = new FlxSprite(FlxG.width - 300, 100).makeGraphic(300, FlxG.height - 100, 0xFF1A1F33);
		rightPanel.alpha = 0.85;
		rightPanel.scrollFactor.set();
		add(rightPanel);

		// Bottom bar - Directory
		#if MODS_ALLOWED
		var bottomBar:FlxSprite = new FlxSprite(0, FlxG.height - 70).makeGraphic(FlxG.width, 70, 0xFF0F1419);
		bottomBar.alpha = 0.9;
		bottomBar.scrollFactor.set();
		add(bottomBar);

		directoryTxt = new FlxText(20, FlxG.height - 55, FlxG.width - 40, '', 18);
		directoryTxt.setFormat(Paths.font("vcr.ttf"), 18, 0xFF00D4FF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		directoryTxt.borderSize = 2;
		directoryTxt.scrollFactor.set();
		add(directoryTxt);
		#end
	}

	function initializeCategorySystem()
	{
		// Categories will be displayed as buttons on the left side
		var categoryY:Float = 120;
		for (i in 0...editorCategories.length)
		{
			var category = editorCategories[i];
			var categoryBtn:FlxSprite = new FlxSprite(10, categoryY).makeGraphic(260, 70, category.color);
			categoryBtn.alpha = 0.3;
			categoryBtn.ID = i;
			categoryBtn.scrollFactor.set();
			add(categoryBtn);

			var categoryLabel:Alphabet = new Alphabet(30, categoryY + 15, category.name, true);
			categoryLabel.setScale(0.5);
			categoryLabel.scrollFactor.set();
			add(categoryLabel);

			categoryY += 80;
		}

		#if MODS_ALLOWED
		for (folder in Mods.getModDirectories())
		{
			directories.push(folder);
		}

		var found:Int = directories.indexOf(Mods.currentModDirectory);
		if(found > -1) curDirectory = found;
		changeDirectory();
		#end
	}

	function initializeEditorCards()
	{
		grpEditorCards = new FlxTypedGroup<FlxSprite>();
		add(grpEditorCards);
	}

	function initializeUIElements()
	{
		// Description panel
		descriptionTxt = new FlxText(FlxG.width - 290, 120, 280, '', 16);
		descriptionTxt.setFormat(Paths.font("vcr.ttf"), 14, 0xFFCCCCCC, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		descriptionTxt.borderSize = 1;
		descriptionTxt.wordWrap = true;
		descriptionTxt.scrollFactor.set();
		add(descriptionTxt);

		// Keyboard shortcuts info
		var shortcutY = FlxG.height - 250;
		shortcutDisplay = new FlxText(FlxG.width - 290, shortcutY, 280, 
			'KIŞAYOLLAR:\n↑/↓: Seç\n←/→: Kategori\n[SPACE]: Arama\n[ESC]: Geri', 14);
		shortcutDisplay.setFormat(Paths.font("vcr.ttf"), 12, 0xFF888888, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		shortcutDisplay.borderSize = 1;
		shortcutDisplay.scrollFactor.set();
		add(shortcutDisplay);
	}

	function loadRecentEditors()
	{
		// Load from save data if available
		recentEditors = [];
	}

	

	// ===== SELECTION & NAVIGATION =====

	function selectEditor(catIdx:Int, edIdx:Int) {
		selectedCategoryIndex = catIdx;
		selectedEditorIndex = edIdx;
    
		// Eski kartları temizle
		grpEditorCards.forEachAlive(function(card:FlxSprite) {
			card.kill();
			card.destroy();
		});
		grpEditorCards.clear();
    
		// Yeni kartları oluştur
		var category = editorCategories[selectedCategoryIndex];
		var cardX:Float = 320;
		var cardY:Float = 140;
		
		for (i in 0...category.editors.length) {
			var editor = category.editors[i];
			var card:FlxSprite = new FlxSprite(cardX, cardY);
			card.makeGraphic(200, 120, category.color);
			card.ID = i;  // Index için
			grpEditorCards.add(card);
        
			if (i == selectedEditorIndex) {
				selectedCard = card;
				card.scale.set(1.05, 1.05);  // SELECT efekti
			}
        
			cardX += 220;
			if (cardX > FlxG.width - 400) {
				cardX = 320;
				cardY += 120;
			}
		}
		updateDescription();
	}


	function changeCategory(change:Int = 0)
	{
		selectedCategoryIndex = FlxMath.wrap(selectedCategoryIndex + change, 0, editorCategories.length - 1);
		selectedEditorIndex = 0;
		selectEditor(selectedCategoryIndex, 0);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function changeEditorSelection(change:Int = 0)
	{
		var currentCategory = editorCategories[selectedCategoryIndex];
		selectedEditorIndex = FlxMath.wrap(selectedEditorIndex + change, 0, currentCategory.editors.length - 1);
		selectEditor(selectedCategoryIndex, selectedEditorIndex);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	function updateDescription()
	{
		if(selectedCard != null)
		{
			descriptionTxt.text = "ANA MENÜYÜ İSTEDİĞİNİZ GİBİ KİŞİLEŞTİRİN, BUTONLARLA OYNAYIN VE DAHA FAZLASI! (BU AYAR BETADA) WTF?!";
		}
	}

	#if MODS_ALLOWED
	function changeDirectory(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curDirectory = FlxMath.wrap(curDirectory + change, 0, directories.length - 1);

		WeekData.setDirectoryFromWeek();
		if(directories[curDirectory] == null || directories[curDirectory].length < 1)
			directoryTxt.text = '📁 Mod Dizini: [ Varsayılan ]';
		else
		{
			Mods.currentModDirectory = directories[curDirectory];
			directoryTxt.text = '📁 Mod Dizini: [ ' + Mods.currentModDirectory.toUpperCase() + ' ]';
		}
	}
	#end

	// ===== LAUNCH EDITOR =====

	function launchSelectedEditor()
	{
		var currentCategory = editorCategories[selectedCategoryIndex];
		var editor = currentCategory.editors[selectedEditorIndex];
		var editorName = editor.editor;

		FlxG.sound.music.volume = 0;
		FreeplayState.destroyFreeplayVocals();

		switch(editorName) {
			case 'Chart Düzenleyici':
				LoadingState.loadAndSwitchState(new ChartingState(), false);
			case 'Karakter Düzenleyici':
				LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
			case 'Sahne Düzenleyici':
				LoadingState.loadAndSwitchState(new StageEditorState());
			case 'Hafta Düzenleyici':
				MusicBeatState.switchState(new WeekEditorState());
			case 'Menü Karakter Düzenleyici':
				MusicBeatState.switchState(new MenuCharacterEditorState());
			case 'Diyalog Düzenleyici':
				LoadingState.loadAndSwitchState(new DialogueEditorState(), false);
			case 'Portre Diyalog Düzenleyici':
				LoadingState.loadAndSwitchState(new DialogueCharacterEditorState(), false);
			case 'Nota Efekti Düzenleyici':
				MusicBeatState.switchState(new NoteSplashEditorState());
		}
	}

	// ===== MAIN UPDATE LOOP =====

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Navigation
		if(controls.UI_UP_P)
			changeEditorSelection(-1);
		
		if(controls.UI_DOWN_P)
			changeEditorSelection(1);

		#if MODS_ALLOWED
		if(controls.UI_LEFT_P)
			changeCategory(-1);
		
		if(controls.UI_RIGHT_P)
			changeCategory(1);
		#end

		// Launch editor
		if(controls.ACCEPT)
			launchSelectedEditor();

		// Back to main menu
		if(controls.BACK)
			MusicBeatState.switchState(new MainMenuState());
	}

	override function destroy()
	{
		super.destroy();
	}
}