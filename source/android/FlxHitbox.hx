package android;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.ui.FlxButton;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import flixel.input.touch.FlxTouch;
import flixel.input.touch.FlxTouchManager;
import haxe.ds.IntMap;
import Reflect;

class FlxHitbox extends FlxGroup {
	// índices: 0 = left, 1 = down, 2 = up, 3 = right
	public var buttons:Array<FlxSprite>;
	public var orgAlpha:Float;
	public var orgAntialiasing:Bool;

	// touch assignment: map touchPointID -> buttonIndex
	var touchToButton:IntMap<Int>;
	// per-button assigned touches (set of touch IDs)
	var assigned: Array<Array<Int>>;

	// state arrays
	var pressed:Array<Bool>;
	var justPressed:Array<Bool>;
	var justReleased:Array<Bool>;
	var prevPressed:Array<Bool>;

	// rects (posição/tamanho lógica) caso queira overridar manualmente
	public var rects:Array<FlxRect>;

	public function new(?alphaAlt:Float = 0.75, ?antialiasingAlt:Bool = true) {
		super();

		orgAlpha = alphaAlt;
		orgAntialiasing = antialiasingAlt;

		buttons = [null, null, null, null];
		assigned = [[], [], [], []];
		touchToButton = new IntMap<Int>();

		pressed = [false, false, false, false];
		prevPressed = [false, false, false, false];
		justPressed = [false, false, false, false];
		justReleased = [false, false, false, false];

		rects = [];

		// cria sprites visuais (pads) — posições padrão: 4 colunas iguais cobrindo a tela
		var w = Std.int(FlxG.width / 4);
		for (i in 0...4) {
			var x = i * w;
			var s:FlxSprite = new FlxSprite(x, 0);
			// tenta carregar frame do atlas; fallback para makeGraphic
			var frames:FlxAtlasFrames = getFrames();
			var names = ["left","down","up","right"];
			if (frames != null && frames.getByName(names[i]) != null) {
				var g:FlxGraphic = FlxGraphic.fromFrame(frames.getByName(names[i]));
				s.loadGraphic(g);
			} else {
				s.makeGraphic(w, FlxG.height, 0x00444444); // invisível base
			}
			s.antialiasing = orgAntialiasing;
			s.alpha = 0;
			s.scrollFactor.set(0, 0);
			buttons[i] = s;
			add(s);

			// rects lógicas coincidem com sprite por default
			rects.push(new FlxRect(x, 0, w, FlxG.height));
		}
		// hint/overlay (opcional) - tenta carregar imagem completa do atlas como fundo
		var hintPath = Paths.image('androidcontrols/hitbox');
		if (hintPath != "") {
			var hint:FlxSprite = new FlxSprite(0, 0).loadGraphic(hintPath);
			hint.antialiasing = orgAntialiasing;
			hint.alpha = orgAlpha;
			hint.scrollFactor.set(0, 0);
			// colocamos o hint primeiro (atrás), então remove e re-add: move para trás
			remove(hint, false);
			add(hint); // se você quiser atrás, adicione antes dos buttons; aqui já adicionamos os buttons então fica em cima - ajuste conforme preferir
		}
	}

	// tenta obter atlas frames (ajuste conforme seu projeto)
	public function getFrames():FlxAtlasFrames {
		return Paths.getSparrowAtlas('androidcontrols/hitbox');
	}

	// define câmera para todos os elementos (ex.: [camOther] ou [camHUD])
	public function setCameras(cams:Array<Dynamic>):Void {
		for (b in buttons) if (b != null) b.cameras = cams;
	}

	// permite configurar retângulos lógicos (por ex. se você já tem leftHitbox sprites)
	public function setRects(newRects:Array<FlxRect>):Void {
		if (newRects == null || newRects.length < 4) return;
		rects = newRects;
		// opcional: reposicionar sprites visuais para coincidir com rects
		for (i in 0...4) {
			var r = rects[i];
			if (buttons[i] != null) {
				buttons[i].x = r.x;
				buttons[i].y = r.y;
				buttons[i].setGraphicSize(Std.int(r.width), Std.int(r.height));
			}
		}
	}

	// API: pressed/justPressed/justReleased (índice 0..3) ou métodos por nome
	public function pressedIndex(idx:Int):Bool { return pressed[idx]; }
	public function justPressedIndex(idx:Int):Bool { return justPressed[idx]; }
	public function justReleasedIndex(idx:Int):Bool { return justReleased[idx]; }

	public function pressedByName(name:String):Bool {
		return pressed[nameToIndex(name)];
	}
	private function nameToIndex(name:String):Int {
		switch(name.toLowerCase()) {
			case "left": return 0;
			case "down": return 1;
			case "up": return 2;
			case "right": return 3;
		}
		return 0;
	}

	// update: checa FlxG.touches e mapeia touches para botões
	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		// reset states temporários
		for (i in 0...4) {
			prevPressed[i] = pressed[i];
			pressed[i] = false;
			justPressed[i] = false;
			justReleased[i] = false;
		}

		// limpa assigned arrays temporariamente (vamos reconstruir)
		for (i in 0...4) assigned[i] = [];

		// percorre toques atuais (compatível com várias versões)
		if (FlxG.touches != null && FlxG.touches.list != null) {
			for (j in 0...FlxG.touches.list.length) {
				var t = FlxG.touches.list[j];
				if (t == null) continue;
				// some FlxTouch implementations use 'pressed', outras 'isDown' etc. vamos checar
				var isPressed:Bool = false;
				if (Reflect.hasField(t, "pressed")) isPressed = t.pressed;
				else if (Reflect.hasField(t, "isDown")) isPressed = t.isDown;
				else isPressed = true; // se não souber, assume true

				if (!isPressed) continue;

				// coord para comparação: prefira screenX/viewX; fallback em x
				var tx:Float = getTouchX(t);
				var ty:Float = getTouchY(t);

				// encontra qual botão (pode estar sobre mais de um; escolhe primeiro que encaixar)
				for (i in 0...4) {
					var r = rects != null && i < rects.length ? rects[i] : null;
					if (r == null) {
						// fallback: usa botão sprite bounds se existir
						var b = buttons[i];
						r = new FlxRect(b.x, b.y, b.width, b.height);
					}
					if (tx >= r.x && tx <= r.x + r.width && ty >= r.y && ty <= r.y + r.height) {
						// associa touch id ao botão
						var id = getTouchId(t);
						if (id != null) {
							assigned[i].push(id);
							touchToButton.set(id, i);
						}
						break;
					}
				}
			}
		}

		// agora atualiza estados por botão (pressed = assigned not empty)
		for (i in 0...4) {
			pressed[i] = assigned[i].length > 0;
			if (pressed[i] && !prevPressed[i]) justPressed[i] = true;
			if (!pressed[i] && prevPressed[i]) justReleased[i] = true;

			// atualiza visual
			animateButtonAlpha(buttons[i], pressed[i] ? orgAlpha : 0);
		}

		// limpa mapeamentos orfãos (touch ids que sumiram) para evitar vazamento
		// reconstrói touchToButton de acordo com assigned
		touchToButton = new IntMap<Int>();
		for (i in 0...4) {
			for (tid in assigned[i]) touchToButton.set(tid, i);
		}
	}

	// util: pega id do touch de forma compatível
	private function getTouchId(t:Dynamic):Int {
		if (Reflect.hasField(t, "touchPointID")) return Reflect.field(t, "touchPointID");
		if (Reflect.hasField(t, "id")) return Reflect.field(t, "id");
		// algumas impls não têm id; retorna -1 (não usaremos)
		return -1;
	}

	// util: pega X/Y usando screen/view/x com Reflect
	private function getTouchX(t:Dynamic):Float {
		if (Reflect.hasField(t, "screenX")) return Reflect.field(t, "screenX");
		if (Reflect.hasField(t, "viewX")) return Reflect.field(t, "viewX");
		if (Reflect.hasField(t, "x")) return Reflect.field(t, "x");
		return 0;
	}
	private function getTouchY(t:Dynamic):Float {
		if (Reflect.hasField(t, "screenY")) return Reflect.field(t, "screenY");
		if (Reflect.hasField(t, "viewY")) return Reflect.field(t, "viewY");
		if (Reflect.hasField(t, "y")) return Reflect.field(t, "y");
		return 0;
	}

	private function animateButtonAlpha(s:FlxSprite, target:Float):Void {
		if (s == null) return;
		if (Math.abs(s.alpha - target) < 0.01) { s.alpha = target; return; }
		FlxTween.num(s.alpha, target, 0.12, { ease: FlxEase.circInOut }, function(v:Float) { s.alpha = v; } );
	}

	override public function destroy():Void {
		super.destroy();
		buttons = null;
		assigned = null;
		touchToButton = null;
		rects = null;
	}
}
