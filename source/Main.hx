package;

import flixel.FlxGame;
import openfl.display.FPS;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		ErrorHandler.init();	
		
		/*#if android
		addChild(new FlxGame(1280, 720, flixel.mobile.CopyState));
		#else*/
		addChild(new FlxGame(1280, 720, TitleState));
		//#end

		addChild(new FPS(10, 3, 0xFFFFFFFF));
		

	}
}
