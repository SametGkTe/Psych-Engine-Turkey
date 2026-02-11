package backend;

import flixel.util.FlxColor;

/**
 * Modern Menu Theme System - Özelleştirilebilir Neon Temalar
 * Allows customization of menu colors, effects, and animations
 */
class ModernMenuTheme
{
	// Default Theme - Neon Purple
	public static var primaryColor:Int = 0xFF00FF88;      // Neon Green
	public static var secondaryColor:Int = 0xFFFF00FF;    // Neon Purple
	public static var accentColor:Int = 0xFF00FFFF;       // Neon Cyan
	public static var panelColor:Int = 0xFF1A1A2E;        // Dark Blue-Black
	public static var backgroundColor:Int = 0xFF0F0F1E;   // Darker Blue-Black
	
	// Light colors for text
	public static var textColorPrimary:Int = 0xFFFFFFFF;  // White
	public static var textColorSecondary:Int = 0xFFAAAAAA; // Gray
	
	// Animation speeds
	public static var glowSpeed:Float = 2.0;              // Glow pulse speed
	public static var transitionSpeed:Float = 0.6;        // Menu transitions
	public static var selectionSpeed:Float = 0.2;         // Selection highlight speed
	
	// Panel transparency
	public static var panelAlpha:Float = 0.92;
	public static var overlayAlpha:Float = 0.85;
	
	// ==================== THEME PRESETS ====================
	public static function setTheme(themeName:String):Void
	{
		switch(themeName.toLowerCase())
		{
			case "neon_purple":
				setNeonPurple();
			case "neon_cyan":
				setNeonCyan();
			case "neon_pink":
				setNeonPink();
			case "dark_mode":
				setDarkMode();
			case "retro":
				setRetro();
			default:
				setNeonPurple();
		}
	}
	
	static function setNeonPurple():Void
	{
		primaryColor = 0xFF00FF88;      // Neon Green
		secondaryColor = 0xFFFF00FF;    // Neon Purple
		accentColor = 0xFF00FFFF;       // Neon Cyan
		panelColor = 0xFF1A1A2E;
		backgroundColor = 0xFF0F0F1E;
	}
	
	static function setNeonCyan():Void
	{
		primaryColor = 0xFF00FFFF;      // Neon Cyan
		secondaryColor = 0xFF0088FF;    // Neon Blue
		accentColor = 0xFF00FF88;       // Neon Green
		panelColor = 0xFF0F1A2E;
		backgroundColor = 0xFF060D1A;
	}
	
	static function setNeonPink():Void
	{
		primaryColor = 0xFFFF0088;      // Neon Pink
		secondaryColor = 0xFFFF5500;    // Neon Orange
		accentColor = 0xFFFF00FF;       // Neon Purple
		panelColor = 0xFF2E1A1A;
		backgroundColor = 0xFF1A0F0F;
	}
	
	static function setDarkMode():Void
	{
		primaryColor = 0xFFFFFFFF;      // White
		secondaryColor = 0xFF888888;    // Gray
		accentColor = 0xFF444444;       // Dark Gray
		panelColor = 0xFF111111;
		backgroundColor = 0xFF000000;
	}
	
	static function setRetro():Void
	{
		primaryColor = 0xFFFFFF00;      // Yellow
		secondaryColor = 0xFF00FFFF;    // Cyan
		accentColor = 0xFFFF00FF;       // Magenta
		panelColor = 0xFF1A0000;
		backgroundColor = 0xFF000033;
	}
	
	// ==================== UTILITY FUNCTIONS ====================
	/**
	 * Get a pulsing color value based on time
	 */
	public static function getPulsingColor(baseColor:Int, variation:Float, speed:Float):Int
	{
		var pulse:Float = Math.sin(FlxG.elapsed * speed) * variation;
		var alpha:Int = (baseColor >> 24) & 0xFF;
		var r:Int = Std.int(((baseColor >> 16) & 0xFF) + pulse);
		var g:Int = Std.int(((baseColor >> 8) & 0xFF) + pulse);
		var b:Int = Std.int((baseColor & 0xFF) + pulse);
		
		// Clamp values
		r = Std.int(FlxMath.bound(r, 0, 255));
		g = Std.int(FlxMath.bound(g, 0, 255));
		b = Std.int(FlxMath.bound(b, 0, 255));
		
		return FlxColor.fromRGB(r, g, b, alpha);
	}
	
	/**
	 * Darken a color by percentage
	 */
	public static function darkenColor(color:Int, percent:Float):Int
	{
		var r:Int = (color >> 16) & 0xFF;
		var g:Int = (color >> 8) & 0xFF;
		var b:Int = color & 0xFF;
		
		r = Std.int(r * (1 - percent));
		g = Std.int(g * (1 - percent));
		b = Std.int(b * (1 - percent));
		
		return FlxColor.fromRGB(r, g, b);
	}
	
	/**
	 * Lighten a color by percentage
	 */
	public static function lightenColor(color:Int, percent:Float):Int
	{
		var r:Int = (color >> 16) & 0xFF;
		var g:Int = (color >> 8) & 0xFF;
		var b:Int = color & 0xFF;
		
		r = Std.int(FlxMath.bound(r + (255 - r) * percent, 0, 255));
		g = Std.int(FlxMath.bound(g + (255 - g) * percent, 0, 255));
		b = Std.int(FlxMath.bound(b + (255 - b) * percent, 0, 255));
		
		return FlxColor.fromRGB(r, g, b);
	}
}
