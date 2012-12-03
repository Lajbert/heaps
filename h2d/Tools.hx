package h2d;

private class BitmapShader extends h3d.Shader {
	static var SRC = {
		var input : {
			pos : Float2,
		};
		var tuv : Float2;
		function vertex( size : Float3, mat1 : Float3, mat2 : Float3, uvScale : Float2, uvPos : Float2 ) {
			var tmp : Float4;
			var spos = pos.xyw * size;
			tmp.x = spos.dp3(mat1);
			tmp.y = spos.dp3(mat2);
			tmp.z = 0;
			tmp.w = 1;
			out = tmp;
			tuv = pos * uvScale + uvPos;
		}
		function fragment( tex : Texture, color : Float4 ) {
			out = tex.get(tuv, nearest) * color;
		}
	}
}

private class CachedBitmapShader extends h3d.Shader {
	static var SRC = {
		var input : {
			pos : Float2,
		};
		var tuv : Float2;
		function vertex( size : Float3, mat1 : Float3, mat2 : Float3, skew : Float, uvScale : Float2 ) {
			var tmp : Float4;
			var spos = pos.xyw * size;
			tmp.x = spos.dp3(mat1);
			tmp.y = spos.dp3(mat2);
			tmp.z = 0;
			tmp.w = 1 - skew * pos.y;
			out = tmp;
			tuv = pos * uvScale;
		}
		function fragment( tex : Texture, mcolor : M44, acolor : Float4 ) {
			out = tex.get(tuv, nearest) * mcolor + acolor;
		}
	}
}

private class TileShader extends h3d.Shader {
	static var SRC = {
		var input : {
			pos : Float2,
			uv : Float2,
		};
		var tuv : Float2;
		function vertex( mat1 : Float3, mat2 : Float3 ) {
			var tmp : Float4;
			tmp.x = pos.xyw.dp3(mat1);
			tmp.y = pos.xyw.dp3(mat2);
			tmp.z = 0;
			tmp.w = 1;
			out = tmp;
			tuv = uv;
		}
		function fragment( tex : Texture, color : Float4 ) {
			out = tex.get(tuv, nearest) * color;
		}
	}
}

private class TileColorShader extends h3d.Shader {
	static var SRC = {
		var input : {
			pos : Float2,
			uv : Float2,
			color : Float4,
		};
		var tuv : Float2;
		var tcolor : Float4;
		function vertex( mat1 : Float3, mat2 : Float3 ) {
			var tmp : Float4;
			tmp.x = pos.xyw.dp3(mat1);
			tmp.y = pos.xyw.dp3(mat2);
			tmp.z = 0;
			tmp.w = 1;
			out = tmp;
			tcolor = color;
			tuv = uv;
		}
		function fragment( tex : Texture ) {
			out = tex.get(tuv, nearest) * tcolor;
		}
	}
}

private class CoreObjects  {
	
	public var tmpVector : h3d.Vector;
	public var tmpMatrix : h3d.Matrix;
	public var bitmapObj : h3d.CoreObject<BitmapShader>;
	public var cachedBitmapObj : h3d.CoreObject<CachedBitmapShader>;
	public var tileObj : h3d.CoreObject<TileShader>;
	public var tileColorObj : h3d.CoreObject<TileColorShader>;
	var emptyTexture : h3d.mat.Texture;
	
	public function new() {
		tmpVector = new h3d.Vector();
		tmpMatrix = new h3d.Matrix();
		
		var plan = new h3d.prim.Quads([
			new h3d.Point(0, 0),
			new h3d.Point(1, 0),
			new h3d.Point(0, 1),
			new h3d.Point(1, 1),
		]);
		
		var b = new h3d.CoreObject(plan, new BitmapShader());
		b.material.culling = None;
		b.material.depth(false, Always);
		bitmapObj = b;
		
		var b = new h3d.CoreObject(plan, new CachedBitmapShader());
		b.material.culling = None;
		b.material.depth(false, Always);
		cachedBitmapObj = b;
		
		tileObj = new h3d.CoreObject(null, new TileShader());
		tileObj.material.depth(false, Always);
		tileObj.material.culling = None;
		
		tileColorObj = new h3d.CoreObject(null,new TileColorShader());
		tileColorObj.material.depth(false, Always);
		tileColorObj.material.culling = None;
	}
	
	public function getEmptyTexture() {
		if( emptyTexture == null || emptyTexture.isDisposed() ) {
			emptyTexture = h3d.Engine.getCurrent().mem.allocTexture(1, 1);
			var o = haxe.io.Bytes.alloc(4);
			o.set(0, 0xFF);
			o.set(2, 0xFF);
			o.set(3, 0xFF);
			emptyTexture.uploadBytes(o);
		}
		return emptyTexture;
	}
	
}

class Tools {
	
	static var CORE = null;
	
	@:allow(h2d)
	static function getCoreObjects() {
		var c = CORE;
		if( c == null ) {
			c = new CoreObjects();
			CORE = c;
		}
		return c;
	}
		
	@:allow(h2d)
	static function drawTile( engine : h3d.Engine, spr : Sprite, tile : Tile, color : h3d.Color, blendMode : BlendMode ) {
		var core = getCoreObjects();
		var b = core.bitmapObj;
		setBlendMode(b.material, blendMode);
		if( tile == null )
			tile = new Tile(core.getEmptyTexture(), 0, 0, 5, 5);
		var tmp = core.tmpVector;
		// adds 1/10 pixel size to prevent precision loss after scaling
		tmp.x = tile.width + 0.1;
		tmp.y = tile.height + 0.1;
		tmp.z = 1;
		b.shader.size = tmp;
		tmp.x = spr.matA;
		tmp.y = spr.matC;
		tmp.z = spr.absX + tile.dx * spr.matA + tile.dy * spr.matC;
		b.shader.mat1 = tmp;
		tmp.x = spr.matB;
		tmp.y = spr.matD;
		tmp.z = spr.absY + tile.dx * spr.matB + tile.dy * spr.matD;
		b.shader.mat2 = tmp;
		tmp.x = tile.u;
		tmp.y = tile.v;
		b.shader.uvPos = tmp;
		tmp.x = tile.u2 - tile.u;
		tmp.y = tile.v2 - tile.v;
		b.shader.uvScale = tmp;
		if( color == null ) {
			tmp.x = 1;
			tmp.y = 1;
			tmp.z = 1;
			tmp.w = 1;
			b.shader.color = tmp;
		} else
			b.shader.color = color.toVector();
		b.shader.tex = tile.getTexture();
		b.render(engine);
	}

	@:allow(h2d)
	static function setBlendMode( mat : h3d.mat.Material, b : BlendMode ) {
		switch( b ) {
		case Normal:
			mat.blend(SrcAlpha, OneMinusSrcAlpha);
		case None:
			mat.blend(One, Zero);
		case Add:
			mat.blend(SrcAlpha, One);
		case Multiply:
			mat.blend(DstColor, OneMinusSrcAlpha);
		case Erase:
			mat.blend(Zero, OneMinusSrcAlpha);
		}
	}
	
}