package;

import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxBasic;
import flixel.FlxCamera;
import WiggleEffect.WiggleEffect;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import flixel.mobile.AlertMessage;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.filters.ShaderFilter;

#if mobile
import flixel.ui.FlxButton;
import flixel.math.FlxRect;
#end
	
using StringTools;

class PlayState extends MusicBeatState
{
	public static var curLevel:String = 'Tutorial';
	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	var halloweenLevel:Bool = false;
	var shader:WiggleEffect;
	
	#if mobile
    var leftHitbox:FlxSprite;
    var downHitbox:FlxSprite;
var upHitbox:FlxSprite;
var rightHitbox:FlxSprite;

var leftButton:FlxButton;
var downButton:FlxButton;
var upButton:FlxButton;
var rightButton:FlxButton;

var leftPressed:Bool = false;
var downPressed:Bool = false;
var upPressed:Bool = false;
var rightPressed:Bool = false;
#end

	private var vocals:FlxSound;

	private var dad:Character;
	private var gf:Character;
	private var boyfriend:Boyfriend;

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	//botplay not work in this engine sorry
	//public var botPlay:Bool = false;

	private var camFollow:FlxObject;
	private var strumLineNotes:FlxTypedGroup<FlxSprite>;
	private var playerStrums:FlxTypedGroup<FlxSprite>;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;
	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;
	public var camOther:FlxCamera;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	var halloweenBG:FlxSprite;
	var isHalloween:Bool = false;

	var phillyCityLights:FlxTypedGroup<FlxSprite>;
	var phillyTrain:FlxSprite;
	var trainSound:FlxSound;

	var limo:FlxSprite;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:FlxSprite;

	var talking:Bool = true;
	var songScore:Int = 0;
	var scoreTxt:FlxText;

	//var floatTime:Float = 0;
    //var dadStartY:Float = 0;
	

	public static var campaignScore:Int = 0;

	var defaultCamZoom:Float = 1.05;

	override public function create()
	{
		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
        camOther.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson(curLevel);

		Conductor.changeBPM(SONG.bpm);

		switch (SONG.song.toLowerCase())
		{
			case 'tutorial':
				dialogue = ["Hey you're pretty cute.", 'Use the arrow keys to keep up \nwith me singing.'];
			case 'bopeebo':
				dialogue = [
					'HEY!',
					"You think you can just sing\nwith my daughter like that?",
					"If you want to date her...",
					"You're going to have to go \nthrough ME first!"
				];
			case 'fresh':
				dialogue = ["Not too shabby boy.", ""];
			case 'dadbattle':
				dialogue = [
					"gah you think you're hot stuff?",
					"If you can beat me here...",
					"Only then I will even CONSIDER letting you\ndate my daughter!"
				];
		}

		if (SONG.song.toLowerCase() == 'spookeez' || SONG.song.toLowerCase() == 'monster' || SONG.song.toLowerCase() == 'south')
		{
			curStage = "spooky";
			halloweenLevel = true;

			var hallowTex = FlxAtlasFrames.fromSparrow(AssetPaths.halloween_bg__png, AssetPaths.halloween_bg__xml);

			halloweenBG = new FlxSprite(-200, -100);
			halloweenBG.frames = hallowTex;
			halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
			halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
			halloweenBG.animation.play('idle');
			halloweenBG.antialiasing = true;
			add(halloweenBG);

			isHalloween = true;
		}
		else if (SONG.song.toLowerCase() == 'pico' || SONG.song.toLowerCase() == 'blammed' || SONG.song.toLowerCase() == 'philly')
		{
			curStage = 'philly';

			var bg:FlxSprite = new FlxSprite(-100).loadGraphic(AssetPaths.sky__png);
			bg.scrollFactor.set(0.1, 0.1);
			add(bg);

			var city:FlxSprite = new FlxSprite(-10).loadGraphic(AssetPaths.city__png);
			city.scrollFactor.set(0.3, 0.3);
			city.setGraphicSize(Std.int(city.width * 0.85));
			city.updateHitbox();
			add(city);

			phillyCityLights = new FlxTypedGroup<FlxSprite>();
			add(phillyCityLights);

			for (i in 0...5)
			{
				var light:FlxSprite = new FlxSprite(city.x).loadGraphic('assets/images/philly/win' + i + '.png');
				light.scrollFactor.set(0.3, 0.3);
				light.visible = false;
				light.setGraphicSize(Std.int(light.width * 0.85));
				light.updateHitbox();
				phillyCityLights.add(light);
			}

			var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(AssetPaths.behindTrain__png);
			add(streetBehind);

			phillyTrain = new FlxSprite(2000, 360).loadGraphic(AssetPaths.train__png);
			add(phillyTrain);

			trainSound = new FlxSound().loadEmbedded('assets/sounds/train_passes' + TitleState.soundExt);
			FlxG.sound.list.add(trainSound);

			// var cityLights:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.win0__png);

			var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic(AssetPaths.street__png);
			add(street);
		}
		else if (SONG.song.toLowerCase() == 'milf' || SONG.song.toLowerCase() == 'satin-panties' || SONG.song.toLowerCase() == 'high')
		{
			curStage = 'limo';
			defaultCamZoom = 0.90;

			var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic(AssetPaths.limoSunset__png);
			skyBG.scrollFactor.set(0.1, 0.1);
			add(skyBG);

			var bgLimo:FlxSprite = new FlxSprite(-200, 480);
			bgLimo.frames = FlxAtlasFrames.fromSparrow(AssetPaths.bgLimo__png, AssetPaths.bgLimo__xml);
			bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
			bgLimo.animation.play('drive');
			bgLimo.scrollFactor.set(0.4, 0.4);
			add(bgLimo);

			grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
			add(grpLimoDancers);

			for (i in 0...5)
			{
				var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
				dancer.scrollFactor.set(0.4, 0.4);
				grpLimoDancers.add(dancer);
			}

			var overlayShit:FlxSprite = new FlxSprite(-500, -600).loadGraphic(AssetPaths.limoOverlay__png);
			overlayShit.alpha = 0.5;
			// add(overlayShit);

			// var shaderBullshit = new BlendModeEffect(new OverlayShader(), FlxColor.RED);

			// FlxG.camera.setFilters([new ShaderFilter(cast shaderBullshit.shader)]);

			// overlayShit.shader = shaderBullshit;

			var limoTex = FlxAtlasFrames.fromSparrow(AssetPaths.limoDrive__png, AssetPaths.limoDrive__xml);

			limo = new FlxSprite(-120, 550);
			limo.frames = limoTex;
			limo.animation.addByPrefix('drive', "Limo stage", 24);
			limo.animation.play('drive');
			limo.antialiasing = true;

			fastCar = new FlxSprite(-300, 160).loadGraphic(AssetPaths.fastCarLol__png);
			// add(limo);
		}
		else if (SONG.song.toLowerCase() == 'delirium')
		{
		curStage = 'deliriuned';
		defaultCamZoom = 0.6;
		shader = new WiggleEffect();
		var s = 2.0;
		var a = 0.1;
		var f = 5.0;
		shader.uWaveAmplitude.value = [a];
		shader.uFrequency.value = [f];
		shader.uSpeed.value = [s];
		shader.uTime.value = [0.0];
			
		var bgs:FlxSprite = new FlxSprite(-1500, -300).loadGraphic(AssetPaths.cone__png);
		bgs.scrollFactor.set(0, 0);
		bgs.screenCenter();
		bgs.shader = shader;
		add(bgs);
		}else if (SONG.song.toLowerCase() == 'photosynthesis')
		{
		curStage = 'purpleyay';
		shader = new WiggleEffect();
		var s = 4.2;
		var a = 0.1;
		var f = 5.0;
		shader.uWaveAmplitude.value = [a];
		shader.uFrequency.value = [f];
		shader.uSpeed.value = [s];
		shader.uTime.value = [0.0];
			
		var photo:FlxSprite = new FlxSprite(-1500, -300).loadGraphic(AssetPaths.purpling__png);
		photo.scrollFactor.set(0, 0);
		photo.screenCenter();
		photo.shader = shader;
		add(photo);
		}else if (SONG.song.toLowerCase() == 'pessimistic' || SONG.song.toLowerCase() == 'taimuresu')
		{
		shader = new WiggleEffect();
		curStage = 'hell';
		var s = 4.3;
		var a = 0.1;
		var f = 5.0;
		shader.uWaveAmplitude.value = [a];
		shader.uFrequency.value = [f];
		shader.uSpeed.value = [s];
		shader.uTime.value = [0.0];
			
		var bs:FlxSprite = new FlxSprite(-1500, -300).loadGraphic(AssetPaths.hellBG__png);
		bs.scrollFactor.set(0, 0);
		bs.screenCenter();
		bs.shader = shader;
		add(bs);
		}else{
			curStage = 'stage';
			var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(AssetPaths.stageback__png);
			// bg.setGraphicSize(Std.int(bg.width * 2.5));
			// bg.updateHitbox();
			bg.antialiasing = true;
			bg.scrollFactor.set(0.9, 0.9);
			bg.active = false;
			add(bg);

			var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(AssetPaths.stagefront__png);
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			stageFront.antialiasing = true;
			stageFront.scrollFactor.set(0.9, 0.9);
			stageFront.active = false;
			add(stageFront);

			var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(AssetPaths.stagecurtains__png);
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
			stageCurtains.updateHitbox();
			stageCurtains.antialiasing = true;
			stageCurtains.scrollFactor.set(1.3, 1.3);
			stageCurtains.active = false;

			add(stageCurtains);
		}

		gf = new Character(400, 130, 'gf');
		gf.scrollFactor.set(0.95, 0.95);
		gf.antialiasing = true;
		add(gf);

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);

		dad = new Character(100, 100, SONG.player2);
		add(dad);
		
		if (SONG.song.toLowerCase() == 'pico' || SONG.song.toLowerCase() == 'blammed' || SONG.song.toLowerCase() == 'philly')
		{
			
		dad.flipX = true;
		}else{
		dad.flipX = false;
		}

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		switch (SONG.player2)
		{
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode)
				{
					camPos.x += 600;
					tweenCamIn();
				}

			case "spooky":
				dad.y += 200;
			case "monster":
				dad.y += 100;
			case 'dad':
				camPos.x += 400;
			case 'pico':
				camPos.x += 600;
				dad.y += 300;
		}

		boyfriend = new Boyfriend(770, 450);
		add(boyfriend);

		// REPOSITIONING PER STAGE
		switch (curStage)
		{
			case 'limo':
				
			boyfriend.y -= 220;
			boyfriend.x += 260;

			resetFastCar();
			add(fastCar);

			case 'hell':
				dad.y -= 200;
				dad.x -= 100;
				
			case 'deliriuned':
			dad.x -= 300;
	    }

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<FlxSprite>();

		startingSong = true;

		// startCountdown();

		generateSong(SONG.song);

		// add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);
		add(camFollow);

		camGame.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		camGame.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.se.zoom = defaultCamZoom;
		camGame.zoom = defaultCamZoom;

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(AssetPaths.healthBar__png);
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, dad.color);
		/*
	0xFFFF0000,
	FlxColor.fromRGB(
		dad.healthColorArray[0],
		dad.healthColorArray[1],
		dad.healthColorArray[2]
	)*/

		// healthBar
		add(healthBar);

		scoreTxt = new FlxText(healthBarBG.x + healthBarBG.width - 190, healthBarBG.y + 30, 0, "", 20);
		scoreTxt.setFormat("assets/fonts/vcr.ttf", 16, FlxColor.WHITE, RIGHT);
		scoreTxt.scrollFactor.set();
		add(scoreTxt);

		iconP1 = new HealthIcon(SONG.player1, true);
        iconP1.y = healthBar.y - (iconP1.height / 2);
        add(iconP1);

        iconP2 = new HealthIcon(SONG.player2, false);
        iconP2.y = healthBar.y - (iconP2.height / 2);
        add(iconP2);

		if (isStoryMode)
		{
			// TEMP for now, later get rid of startCountdown()
			// add(doof);
			startCountdown();
		}
		else
			startCountdown();

		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		doof.cameras = [camHUD];
	#if mobile
// cria botões invisíveis exatamente sobre as sprites de hitbox para capturar toques
leftButton = new FlxButton(leftHitbox.x, leftHitbox.y, null, function(?b:FlxButton) {});
leftButton.width = leftHitbox.width;
leftButton.height = leftHitbox.height;
if (leftButton.label != null) leftButton.label.set_text("");
leftButton.alpha = 0.0;
leftButton.cameras = [camOther];
leftButton.scrollFactor.set(0, 0);
leftButton.onDown = function(?b:FlxButton) { leftPressed = true; };
leftButton.onUp = function(?b:FlxButton) { leftPressed = false; };
add(leftButton);

downButton = new FlxButton(downHitbox.x, downHitbox.y, null, function(?b:FlxButton) {});
downButton.width = downHitbox.width;
downButton.height = downHitbox.height;
if (downButton.label != null) downButton.label.set_text("");
downButton.alpha = 0.0;
downButton.cameras = [camOther];
downButton.scrollFactor.set(0, 0);
downButton.onDown = function(?b:FlxButton) { downPressed = true; };
downButton.onUp = function(?b:FlxButton) { downPressed = false; };
add(downButton);

upButton = new FlxButton(upHitbox.x, upHitbox.y, null, function(?b:FlxButton) {});
upButton.width = upHitbox.width;
upButton.height = upHitbox.height;
if (upButton.label != null) upButton.label.set_text("");
upButton.alpha = 0.0;
upButton.cameras = [camOther];
upButton.scrollFactor.set(0, 0);
upButton.onDown = function(?b:FlxButton) { upPressed = true; };
upButton.onUp = function(?b:FlxButton) { upPressed = false; };
add(upButton);

rightButton = new FlxButton(rightHitbox.x, rightHitbox.y, null, function(?b:FlxButton) {});
rightButton.width = rightHitbox.width;
rightButton.height = rightHitbox.height;
if (rightButton.label != null) rightButton.label.set_text("");
rightButton.alpha = 0.0;
rightButton.cameras = [camOther];
rightButton.scrollFactor.set(0, 0);
rightButton.onDown = function(?b:FlxButton) { rightPressed = true; };
rightButton.onUp = function(?b:FlxButton) { rightPressed = false; };
add(rightButton);
#end
	
	if (SONG.song.toLowerCase() == 'taimuresu'){
		AlertMessage.show("i will kill you...", "the finale...");
		BlackFade.addBlackFade(this, camHUD, 10);
	}
	
		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];

		#if lime
		trace("IT'S LIME");
		#end

		super.create();
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	function startCountdown():Void
	{
		generateStaticArrows(0);
		generateStaticArrows(1);

		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			dad.dance();
			gf.dance();
			boyfriend.playAnim('idle');

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play('assets/sounds/intro3' + TitleState.soundExt, 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic('assets/images/ready.png');
					ready.scrollFactor.set();
					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play('assets/sounds/intro2' + TitleState.soundExt, 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic('assets/images/set.png');
					set.scrollFactor.set();
					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play('assets/sounds/intro1' + TitleState.soundExt, 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic('assets/images/go.png');
					go.scrollFactor.set();
					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play('assets/sounds/introGo' + TitleState.soundExt, 0.6);
				case 4:
					if (SONG.song.toLowerCase() == 'taimuresu'){
	                  BlackFade.addBlackFade(this, camHUD, 10);
	                }
	
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
			FlxG.sound.playMusic("assets/songs/" + SONG.song + "_Inst" + TitleState.soundExt, 1, false);
		FlxG.sound.music.onComplete = endSong;
		vocals.play();
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
{
	var songData = SONG;

	Conductor.changeBPM(songData.bpm);

	curSong = songData.song;

	if (SONG.needsVoices)
		vocals = new FlxSound().loadEmbedded(
			"assets/songs/" + curSong + "_Voices" + TitleState.soundExt
		);
	else
		vocals = new FlxSound();

	FlxG.sound.list.add(vocals);

	notes = new FlxTypedGroup<Note>();
	add(notes);

	var noteData:Array<SwagSection> = songData.notes;

	// Optimization
	unspawnNotes = [];

	for (section in noteData)
	{
		var gottaHitNote:Bool = section.mustHitSection;

		for (songNotes in section.sectionNotes)
		{
			var daStrumTime:Float = songNotes[0];
			var daNoteData:Int = Std.int(songNotes[1] % 4);

			gottaHitNote = section.mustHitSection;

			if (songNotes[1] > 3)
				gottaHitNote = !section.mustHitSection;

			var oldNote:Note = null;

			if (unspawnNotes.length > 0)
				oldNote = unspawnNotes[unspawnNotes.length - 1];

			// Main note
			var swagNote:Note = new Note(
				daStrumTime,
				daNoteData,
				oldNote
			);

			swagNote.mustPress = gottaHitNote;
			swagNote.sustainLength = songNotes[2];
			swagNote.scrollFactor.set(0, 0);

			if (swagNote.mustPress)
				swagNote.x += FlxG.width / 2;

			unspawnNotes.push(swagNote);

			// Sustain notes
			var susLength:Int = Math.floor(
				swagNote.sustainLength / Conductor.stepCrochet
			);

			if (susLength > 0)
			{
				for (susNote in 0...susLength)
				{
					oldNote = unspawnNotes[unspawnNotes.length - 1];

					var sustainNote:Note = new Note(
						daStrumTime + (Conductor.stepCrochet * (susNote + 1)),
						daNoteData,
						oldNote,
						true
					);

					sustainNote.mustPress = gottaHitNote;

					// Less expensive than set()
					sustainNote.scrollFactor.x = 0;
					sustainNote.scrollFactor.y = 0;

					if (sustainNote.mustPress)
						sustainNote.x += FlxG.width / 2;

					unspawnNotes.push(sustainNote);
				}
			}
		}
	}

	// Sort only once
	unspawnNotes.sort(sortByShit);

	generatedMusic = true;
}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			FlxG.log.add(i);
			var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);
			var arrTex = FlxAtlasFrames.fromSparrow(AssetPaths.NOTE_assets_3D__png, AssetPaths.NOTE_assets_3D__xml);
			babyArrow.frames = arrTex;
			babyArrow.animation.addByPrefix('green', 'arrowUP');
			babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
			babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
			babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

			babyArrow.scrollFactor.set();
			babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));
			babyArrow.updateHitbox();
			babyArrow.antialiasing = true;

			babyArrow.y -= 10;
			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

			babyArrow.ID = i;

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}

			switch (Math.abs(i))
			{
				case 2:
					babyArrow.x += Note.swagWidth * 2;
					babyArrow.animation.addByPrefix('static', 'arrowUP');
					babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					babyArrow.x += Note.swagWidth * 3;
					babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
					babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
				case 1:
					babyArrow.x += Note.swagWidth * 1;
					babyArrow.animation.addByPrefix('static', 'arrowDOWN');
					babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 0:
					babyArrow.x += Note.swagWidth * 0;
					babyArrow.animation.addByPrefix('static', 'arrowLEFT');
					babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
			}

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(camGame, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;
		}

		super.closeSubState();
	}

	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		//floatTime += elapsed;
		camOther.zoom = 1.05;
		#if !debug
		perfectMode = false;
		#end

		#if mobile
// as flags agora são controladas pelos FlxButton onDown/onUp; atualiza a aparência das hitboxes
leftHitbox.alpha = leftPressed ? 0.35 : 0.2;
downHitbox.alpha = downPressed ? 0.35 : 0.2;
upHitbox.alpha = upPressed ? 0.35 : 0.2;
rightHitbox.alpha = rightPressed ? 0.35 : 0.2;
#end
	    if (SONG.song.toLowerCase() == 'photosynthesis')
       {
	    dad.y = 200 + Math.sin(Conductor.songPosition / 500) * 20;
	   }else if (SONG.song.toLowerCase() == 'delirium')
       {
	    dad.y = -200 + Math.sin(Conductor.songPosition / 500) * 20;
	   }else if (SONG.song.toLowerCase() == 'pessimistic' || SONG.song.toLowerCase() == 'taimuresu'){
		dad.y = -200 + Math.sin(Conductor.songPosition / 500) * 20;
       }

		if (SONG.song.toLowerCase() == 'taimuresu'){
		for (i in 0...strumLineNotes.length)
{
	strumLineNotes.members[i].angle += 4;

	//strumLineNotes.members[i].x += Math.sin((Conductor.songPosition / 120) + (i * 2)) * 4;

	strumLineNotes.members[i].y += Math.cos((Conductor.songPosition / 150) + (i * 2)) * 4;
}

notes.forEachAlive(function(daNote:Note)
{
	daNote.angle = strumLineNotes.members[daNote.noteData].angle;


	//daNote.y += Math.cos((Conductor.songPosition / 150) + (daNote.noteData * 2)) * 4;
});
		}
		
		switch (curStage)
		{
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
			case 'deliriuned':
				shader.uTime.value[0] += elapsed;
		   case 'purpleyay':
				shader.uTime.value[0] += elapsed;
			case 'hell':
				shader.uTime.value[0] += elapsed;
				// phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;
		}

		super.update(elapsed);

		scoreTxt.text = "Score:" + songScore;

		if (FlxG.android.justReleased.BACK && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}
		
		#if desktop
		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new ChartingState());
		}
				#end

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		/* if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new Charting()); */

		#if !mobile
		#if debug
		if (FlxG.keys.justPressed.EIGHT)
			FlxG.switchState(new AnimationDebug(SONG.player2));
		#end
	#end

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			if (curBeat % 4 == 0)
			{
				if (SONG.song.toLowerCase() == 'taimuresu'){
					if (curBeat == 148){
					FlxG.camera.flash(0xFFFFFFFF, 1);
					}
				}
				// trace(PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection);
			}

			if (camFollow.x != dad.getMidpoint().x + 150 && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{
				camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
				// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);
				if (dad.curCharacter == 'mom')
					camFollow.y = dad.getMidpoint().y;
				vocals.volume = 1;

				if (SONG.song.toLowerCase() == 'tutorial')
				{
					tweenCamIn();
				}
			}

			if (PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
			{
				camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

				if (curStage == 'limo')
				{
					camFollow.x = boyfriend.getMidpoint().x - 300;
				}

				if (SONG.song.toLowerCase() == 'tutorial')
				{
					FlxTween.tween(camGame, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
				}
			}
		}

		if (camZooming)
		{
			//FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camGame.zoom = FlxMath.lerp(defaultCamZoom, camGame.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", totalBeats);

		if (curSong == 'Fresh')
		{
			switch (totalBeats)
			{
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
				case 163:
					// FlxG.sound.music.stop();
					// curLevel = 'Bopeebo';
					// FlxG.switchState(new TitleState());
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (totalBeats)
			{
				case 128, 129, 130:
					vocals.volume = 0;
					// FlxG.sound.music.stop();
					// curLevel = 'Fresh';
					// FlxG.switchState(new PlayState());
			}
		}
		// better streaming of shit

		// RESET = Quick Game Over Screen
		if (controls.RESET)
		{
			health = 0;
			trace("RESET = True");
		}

		// CHEAT = brandon's a pussy
		if (controls.CHEAT)
		{
			health += 1;
			trace("User is cheating!");
		}

		if (health <= 0)
		{
			boyfriend.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			// FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		var songPoss:Float = Conductor.songPosition;

while (
	unspawnNotes.length > 0 &&
	unspawnNotes[0].strumTime - songPoss < 1500
)
{
	var dunceNote:Note = unspawnNotes[0];

	unspawnNotes.splice(0, 1);

	if (dunceNote != null)
	{
		notes.add(dunceNote);
	}
}

		if (generatedMusic)
{
	var songSpeed:Float = 0.45 * PlayState.SONG.speed;
	var songPos:Float = Conductor.songPosition;
	var strumY:Float = strumLine.y;

	for (daNote in notes.members)
	{
		if (daNote == null || !daNote.alive)
			continue;

		daNote.y = strumY - ((songPos - daNote.strumTime) * songSpeed);

		// Render optimization
		daNote.visible = daNote.y > -400 && daNote.y < FlxG.height + 400;

		// Opponent notes
		if (!daNote.mustPress && daNote.wasGoodHit)
		{
			if (SONG.song != 'Tutorial')
				camZooming = true;

			switch (daNote.noteData)
			{
				case 0:
					dad.playAnim('singLEFT', true);

				case 1:
					dad.playAnim('singDOWN', true);

				case 2:
					dad.playAnim('singUP', true);

				case 3:
					dad.playAnim('singRIGHT', true);
			}

			dad.holdTimer = 0;

			if (SONG.needsVoices)
				vocals.volume = 1;

			daNote.kill();
			continue;
		}

		// Missed notes
		if (daNote.y < -daNote.height)
		{
			if (daNote.tooLate || !daNote.wasGoodHit)
			{
				health -= 0.045;
				vocals.volume = 0;
			}

			daNote.kill();
		}
	}

	// Cleanup dead notes
	for (i in notes.members.length - 1...-1)
	{
		var note = notes.members[i];

		if (note != null && !note.alive)
		{
			notes.remove(note, true);
			note.destroy();
		}
	}
}

keyShit();
	}

	function endSong():Void
	{
		canPause = false;

		if (SONG.validScore)
		{
			#if !switch
			Highscore.saveScore(SONG.song, songScore, storyDifficulty);
			#end
		}

		if (isStoryMode)
		{
			campaignScore += songScore;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt);

				FlxG.switchState(new StoryMenuState());

				// if ()
				StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

				if (SONG.validScore)
				{
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
				}

				FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
				FlxG.save.flush();
			}
			else
			{
				var difficulty:String = "";

				if (storyDifficulty == 0)
					difficulty = '-easy';

				if (storyDifficulty == 2)
					difficulty = '-hard';

				trace('LOADING NEXT SONG');
				trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);

				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();
				FlxG.switchState(new PlayState());
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			FlxG.switchState(new FreeplayState());
		}
	}

	var endingSong:Bool = false;

	private function popUpScore(strumtime:Float):Void
	{
		var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var daRating:String = "sick";

		if (noteDiff > Conductor.safeZoneOffset * 0.9)
		{
			daRating = 'shit';
			score = 50;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			daRating = 'bad';
			score = 100;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.2)
		{
			daRating = 'good';
			score = 200;
		}

		songScore += score;

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */
		rating.loadGraphic('assets/images/' + daRating + ".png");
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();
		rating.antialiasing = true;
		rating.velocity.x -= FlxG.random.int(0, 10);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.combo__png);
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.antialiasing = true;
		comboSpr.velocity.y -= 150;
		comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		comboSpr.updateHitbox();
		comboSpr.velocity.x += FlxG.random.int(1, 10);
		// add(comboSpr);
		add(rating);

		var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 100));
		seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic('assets/images/num' + Std.int(i) + '.png');
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;
			numScore.antialiasing = true;
			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();
			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			if (combo >= 10 || combo == 0)
				add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	private function keyShit():Void
	{
		// HOLDING
		var left  = controls.LEFT  || leftPressed;
var down  = controls.DOWN  || downPressed;
var up    = controls.UP    || upPressed;
var right = controls.RIGHT || rightPressed;

var leftP  = controls.LEFT_P  || (leftPressed && !controls.LEFT);
var downP  = controls.DOWN_P  || (downPressed && !controls.DOWN);
var upP    = controls.UP_P    || (upPressed && !controls.UP);
var rightP = controls.RIGHT_P || (rightPressed && !controls.RIGHT);

var leftR  = controls.LEFT_R  || (!leftPressed && controls.LEFT);
var downR  = controls.DOWN_R  || (!downPressed && controls.DOWN);
var upR    = controls.UP_R    || (!upPressed && controls.UP);
var rightR = controls.RIGHT_R || (!rightPressed && controls.RIGHT);

		// FlxG.watch.addQuick('asdfa', upP);
		if ((upP || rightP || downP || leftP) && !boyfriend.stunned && generatedMusic)
		{
			boyfriend.holdTimer = 0;

			var possibleNotes:Array<Note> = [];

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate)
				{
					possibleNotes.push(daNote);
				}
			});

			if (possibleNotes.length > 0)
			{
				for (daNote in possibleNotes)
				{
					if (perfectMode)
						noteCheck(true, daNote);

					switch (daNote.noteData)
					{
						case 2: // NOTES YOU JUST PRESSED
							if (upP || rightP || downP || leftP)
								noteCheck(upP, daNote);
						case 3:
							if (upP || rightP || downP || leftP)
								noteCheck(rightP, daNote);
						case 1:
							if (upP || rightP || downP || leftP)
								noteCheck(downP, daNote);
						case 0:
							if (upP || rightP || downP || leftP)
								noteCheck(leftP, daNote);
					}

					if (daNote.wasGoodHit)
					{
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}
			}
			else
			{
				badNoteCheck();
			}
		}

		if ((up || right || down || left) && !boyfriend.stunned && generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && daNote.isSustainNote)
				{
					switch (daNote.noteData)
					{
						// NOTES YOU ARE HOLDING
						case 2:
							if (up && daNote.prevNote.wasGoodHit)
								goodNoteHit(daNote);
						case 3:
							if (right && daNote.prevNote.wasGoodHit)
								goodNoteHit(daNote);
						case 1:
							if (down && daNote.prevNote.wasGoodHit)
								goodNoteHit(daNote);
						case 0:
							if (left && daNote.prevNote.wasGoodHit)
								goodNoteHit(daNote);
					}
				}
			});
		}

		if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !up && !down && !right && !left)
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.playAnim('idle');
			}
		}
		playerStrums.forEach(function(spr:FlxSprite)
{
	switch (spr.ID)
	{
		case 0: // LEFT
			if (leftP && spr.animation.curAnim.name != 'confirm')
			{
				spr.animation.play('pressed');
			
			}
			else if (!leftP && spr.animation.curAnim.name == 'pressed')
			{
				spr.animation.play('static');
			}

		case 1: // DOWN
			if (downP && spr.animation.curAnim.name != 'confirm')
			{
				spr.animation.play('pressed');
			}
			else if (!downP && spr.animation.curAnim.name == 'pressed')
			{
				spr.animation.play('static');
			}

		case 2: // UP
			if (upP && spr.animation.curAnim.name != 'confirm')
			{
				spr.animation.play('pressed');
			
			}
			else if (!upP && spr.animation.curAnim.name == 'pressed')
			{
				spr.animation.play('static');
			}

		case 3: // RIGHT
			if (rightP && spr.animation.curAnim.name != 'confirm')
			{
				spr.animation.play('pressed');
			
			}
			else if (!rightP && spr.animation.curAnim.name == 'pressed')
			{
				spr.animation.play('static');
			}
	}

	if (spr.animation.curAnim.name == 'confirm')
	{
		spr.centerOffsets();
		spr.offset.x -= 13;
		spr.offset.y -= 13;
	}
	else
	{
		spr.centerOffsets();
	}
});

		}

	function noteMiss(direction:Int = 1):Void
	{
		if (!boyfriend.stunned)
		{
			health -= 0.035;
			if (combo > 5)
			{
				gf.playAnim('sad');
			}
			combo = 0;

			songScore -= 10;

			FlxG.sound.play('assets/sounds/missnote' + FlxG.random.int(1, 3) + TitleState.soundExt, FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play('assets/sounds/missnote1' + TitleState.soundExt, 1, false);
			// FlxG.log.add('played imss note');

			boyfriend.stunned = true;

			// get stunned for 5 seconds
			new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});

			switch (direction)
			{
				case 2:
					boyfriend.playAnim('singUPmiss', true);
				case 3:
					boyfriend.playAnim('singRIGHTmiss', true);
				case 1:
					boyfriend.playAnim('singDOWNmiss', true);
				case 0:
					boyfriend.playAnim('singLEFTmiss', true);
			}
		}
	}

	function badNoteCheck()
	{
	}

	function noteCheck(keyP:Bool, note:Note):Void
	{
		if (keyP)
			goodNoteHit(note);
		else
			badNoteCheck();
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				popUpScore(note.strumTime);
				combo += 1;
			}

			if (note.noteData >= 0)
				health += 0.023;
			else
				health += 0.004;

			switch (note.noteData)
			{
				case 2:
					boyfriend.playAnim('singUP');
				case 3:
					boyfriend.playAnim('singRIGHT');
				case 1:
					boyfriend.playAnim('singDOWN');
				case 0:
					boyfriend.playAnim('singLEFT');
			}
				playerStrums.forEach(function(spr:FlxSprite)
{
	if (Math.abs(note.noteData) == spr.ID)
	{
		if (spr.animation.curAnim.name != 'confirm')
		{
			spr.animation.play('confirm', true);
		}
	}

	if (spr.animation.curAnim.name == 'confirm'
		&& spr.animation.curAnim.finished)
	{
		spr.animation.play('static');
	}
});

			note.wasGoodHit = true;
			vocals.volume = 1;

			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive()
	{
		FlxG.sound.play('assets/sounds/carPass' + FlxG.random.int(0, 1) + TitleState.soundExt, 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		gf.playAnim('hairFall');
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play('assets/sounds/thunder_' + FlxG.random.int(1, 2) + TitleState.soundExt);
		halloweenBG.animation.play('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		boyfriend.playAnim('scared', true);
		gf.playAnim('scared', true);
	}

	override function stepHit()
	{
		if (SONG.needsVoices)
		{
			if (vocals.time > Conductor.songPosition + 20 || vocals.time < Conductor.songPosition - 20)
			{
				resyncVocals();
			}
		}

		if (dad.curCharacter == 'spooky' && totalSteps % 4 == 2)
		{
			// dad.dance();
		}

		super.stepHit();
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			else
				Conductor.changeBPM(SONG.bpm);

			// Dad doesnt interupt his own notes
			if (SONG.notes[Math.floor(curStep / 16)].mustHitSection)
				dad.dance();
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		// HARDCODING FOR MILF ZOOMS!
		if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat <= 200 && camZooming && FlxG.camera.zoom < 1.35)
		{
			camGame.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && totalBeats % 4 == 0)
		{
			camGame.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (totalBeats % gfSpeed == 0)
		{
			gf.dance();
		}

		if (!boyfriend.animation.curAnim.name.startsWith("sing"))
			boyfriend.playAnim('idle');

		if (totalBeats % 8 == 7 && curSong == 'Bopeebo')
		{
			boyfriend.playAnim('hey', true);

			if (SONG.song == 'Tutorial' && dad.curCharacter == 'gf')
			{
				dad.playAnim('cheer', true);
			}
		}

		switch (curStage)
		{
			case 'limo':
				grpLimoDancers.forEach(function(dancer:BackgroundDancer)
				{
					dancer.dance();
				});

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (totalBeats % 4 == 0)
				{
					phillyCityLights.forEach(function(light:FlxSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1);

					phillyCityLights.members[curLight].visible = true;
					// phillyCityLights.members[curLight].alpha = 1;
				}

				if (totalBeats % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (isHalloween && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
	}

	var curLight:Int = 0;
}
