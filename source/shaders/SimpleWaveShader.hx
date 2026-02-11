package shaders;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class SimpleWaveEffect extends FlxBasic
{
	var sprite:FlxSprite;
	var time:Float = 0;
	var baseAlpha:Float = 0.3;

	public function new(sprite:FlxSprite)
	{
		super();
		this.sprite = sprite;
		
		// Renk animasyonunu başlat
		animateBackgroundColor();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		// Zaman geçişi
		time += elapsed;
		
		// Pulse efekti - alpha'yı animate et
		var pulseAlpha = baseAlpha + Math.sin(time * 2.0) * 0.15;
		sprite.alpha = Math.max(0.1, Math.min(1.0, pulseAlpha));
	}

	function animateBackgroundColor()
	{
		// Renk geçişlerini döngü yap
		var colors = [
			0xFF330055,  // Koyu mor
			0xFF550088,  // Mor
			0xFF880055,  // Kırmızımsı mor
			0xFF330055   // Geri başa
		];

		function cycleColors(index:Int = 0)
		{
			var nextIndex = (index + 1) % colors.length;
			FlxTween.color(sprite, 2, colors[index], colors[nextIndex], {
				onComplete: function(_)
				{
					cycleColors(nextIndex);
				}
			});
		}

		cycleColors(0);
	}
}

