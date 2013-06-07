package h2d;

class Interactive extends Sprite {

	public var width : Float;
	public var height : Float;
	public var useMouseHand(default,set) : Bool;
	public var isEllipse : Bool;
	public var blockEvents : Bool = true;
	public var propagateEvents : Bool = false;
	var scene : Scene;
	
	public function new(width, height, ?parent) {
		super(parent);
		this.width = width;
		this.height = height;
		useMouseHand = true;
	}

	override function onAlloc() {
		var p : Sprite = this;
		while( p.parent != null )
			p = p.parent;
		if( Std.is(p, Scene) ) {
			scene = cast p;
			scene.addEventTarget(this);
		}
		super.onAlloc();
	}
	
	override function onDelete() {
		if( scene != null )
			scene.removeEventTarget(this);
		super.onDelete();
	}

	@:allow(h2d.Scene)
	function handleEvent( e : Event ) {
		if( isEllipse && (e.kind != EOut && e.kind != ERelease) ) {
			var cx = width * 0.5, cy = height * 0.5;
			var dx = (e.relX - cx) / cx;
			var dy = (e.relY - cy) / cy;
			if( dx * dx + dy * dy > 1 ) {
				e.cancel = true;
				return;
			}
		}
		e.propagate = propagateEvents;
		if( !blockEvents ) e.cancel = true;
		switch( e.kind ) {
		case EMove:
			onMove(e);
		case EPush:
			onPush(e);
		case ERelease:
			onRelease(e);
		case EOver:
			if( useMouseHand ) flash.ui.Mouse.cursor = flash.ui.MouseCursor.BUTTON;
			onOver(e);
		case EOut:
			if( useMouseHand ) flash.ui.Mouse.cursor = flash.ui.MouseCursor.AUTO;
			onOut(e);
		}
	}
	
	function set_useMouseHand(v) {
		this.useMouseHand = v;
		if( scene != null && scene.currentOver == this )
			flash.ui.Mouse.cursor = v ? flash.ui.MouseCursor.BUTTON : flash.ui.MouseCursor.AUTO;
		return v;
	}
	
	public function startDrag(callb) {
		scene.startDrag(function(event) {
			// convert global event to our local space
			var x = event.relX, y = event.relY;
			var rx = x * scene.matA + y * scene.matB + scene.absX;
			var ry = x * scene.matC + y * scene.matD + scene.absY;
			var r = scene.height / scene.width;
			
			var i = this;
			
			var dx = rx - i.absX;
			var dy = ry - i.absY;
			
			var w1 = i.width * i.matA * r;
			var h1 = i.width * i.matC;
			var ky = h1 * dx - w1 * dy;
			
			var w2 = i.height * i.matB * r;
			var h2 = i.height * i.matD;
			var kx = w2 * dy - h2 * dx;
			
			var max = h1 * w2 - w1 * h2;
			
			event.relX = (kx * r / max) * i.width;
			event.relY = (ky / max) * i.height;
			
			callb(event);
			
			event.relX = x;
			event.relY = y;
		});
	}
	
	public function stopDrag() {
		scene.stopDrag();
	}
	
	public dynamic function onOver( e : Event ) {
	}

	public dynamic function onOut( e : Event ) {
	}
	
	public dynamic function onPush( e : Event ) {
	}

	public dynamic function onRelease( e : Event ) {
	}
	
	public dynamic function onMove( e : Event ) {
	}
	
}