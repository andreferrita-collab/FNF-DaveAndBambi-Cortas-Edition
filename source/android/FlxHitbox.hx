package android;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.ui.FlxButton;
import flixel.FlxSprite;
import flixel.FlxG;

class FlxHitbox extends FlxSpriteGroup {
	public var hitbox:FlxSpriteGroup;

	public var buttonLeft:FlxButton;
	public var buttonDown:FlxButton;
	public var buttonUp:FlxButton;
	public var buttonRight:FlxButton;

	public var orgAlpha:Float = 0.75;
	public var orgAntialiasing:Bool = true;
	
	public function new(?alphaAlt:Float = 0.75, ?antialiasingAlt:Bool = true) {
		super();

		orgAlpha = alphaAlt;
		orgAntialiasing = antialiasingAlt;

		buttonLeft = new FlxButton(0, 0);
		buttonDown = new FlxButton(0, 0);
		buttonUp = new FlxButton(0, 0);
		buttonRight = new FlxButton(0, 0);

		hitbox = new FlxSpriteGroup();
		// cria os botões (visuais). NÃO usa callbacks internos — a lógica de input fica no PlayState.
		buttonLeft = createhitbox(0, 0, "left");
		add(buttonLeft);
		hitbox.add(buttonLeft);

		buttonDown = createhitbox(320, 0, "down");
		add(buttonDown);
		hitbox.add(buttonDown);

		buttonUp = createhitbox(640, 0, "up");
		add(buttonUp);
		hitbox.add(buttonUp);

		buttonRight = createhitbox(960, 0, "right");
		add(buttonRight);
		hitbox.add(buttonRight);

		var hitbox_hint:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('androidcontrols/hitbox'));
		hitbox_hint.antialiasing = orgAntialiasing;
		hitbox_hint.alpha = orgAlpha;
		hitbox_hint.scrollFactor.set(0, 0);
		add(hitbox_hint);
		// garante ordem: hint atrás das hitboxes visuais
		hitbox_hint.moveBelow(buttonLeft);
	}

	public function createhitbox(x:Float = 0, y:Float = 0, frames:String) {
		var button = new FlxButton(x, y);
		// tenta carregar frame; se falhar, cria gráfico simples
		var frs:FlxAtlasFrames = getFrames();
		if (frs != null && frs.getByName(frames) != null) {
			var g:FlxGraphic = FlxGraphic.fromFrame(frs.getByName(frames));
			button.loadGraphic(g);
		} else {
			// largura padrão: 320 (baseado no seu exemplo); altura = tela
			button.makeGraphic(320, FlxG.height, 0x00444444); // invisível por default (alpha 0)
		}
		button.antialiasing = orgAntialiasing;
		button.alpha = 0; // começo invisível
		button.scrollFactor.set(0, 0);

		// NÃO define callbacks onDown/onUp aqui — a animação será controlada por setPressedStates()
		return button;
	}

	public function getFrames():FlxAtlasFrames {
		return Paths.getSparrowAtlas('androidcontrols/hitbox');
	}

	// =========================
	// NOVO: expõe setPressedStates para o PlayState chamar
	// =========================
	public function setPressedStates(leftP:Bool, downP:Bool, upP:Bool, rightP:Bool):Void {
		animateButtonAlpha(buttonLeft,  leftP  ? orgAlpha : 0);
		animateButtonAlpha(buttonDown,  downP  ? orgAlpha : 0);
		animateButtonAlpha(buttonUp,    upP    ? orgAlpha : 0);
		animateButtonAlpha(buttonRight, rightP ? orgAlpha : 0);
	}

	private function animateButtonAlpha(btn:FlxButton, target:Float):Void {
		if (btn == null) return;
		// evita tween se já está praticamente no target
		if (Math.abs(btn.alpha - target) < 0.01) {
			btn.alpha = target;
			return;
		}

		// tween suave — duração ajustável
		FlxTween.num(btn.alpha, target, 0.12, { ease: FlxEase.circInOut }, function(v:Float) {
			btn.alpha = v;
		});
	}
	// =========================

	override public function destroy():Void {
		super.destroy();

		buttonLeft = null;
		buttonDown = null;
		buttonUp = null;
		buttonRight = null;
	}
}
