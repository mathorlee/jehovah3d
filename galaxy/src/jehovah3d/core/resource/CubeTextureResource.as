package jehovah3d.core.resource
{
	import com.fuwo.CalculateSingle;
	
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.CubeTexture;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;

	public class CubeTextureResource extends TextureResourceBase
	{
		private var size:int;
		private var bmds:Vector.<BitmapData>;
		
		public function CubeTextureResource(bitmapData:BitmapData, mip:Boolean=false)
		{
			super(bitmapData, mip);
			handleCubeTextureBitmapData(bitmapData);
		}
		
		override public function upload(context3D:Context3D):void
		{
			if(isUploaded && cachedContext3D == context3D) //if texture is uploaded and cached context3d equals current context3d, no need to continue.
				return ;
			else //else, update cached context3d and upload. the can handle context3d loss.
				cachedContext3D = context3D;
			
//			trace("texture upload");
			if(_texture)
				_texture.dispose();
			_texture = context3D.createCubeTexture(size, Context3DTextureFormat.BGRA, false);
			
//			CubeTexture(_texture).uploadFromBitmapData(xPositive, 0, 0);
//			CubeTexture(_texture).uploadFromBitmapData(xNegtive, 1, 0);
//			CubeTexture(_texture).uploadFromBitmapData(yPositive, 2, 0);
//			CubeTexture(_texture).uploadFromBitmapData(yNegtive, 3, 0);
//			CubeTexture(_texture).uploadFromBitmapData(zPositive, 4, 0);
//			CubeTexture(_texture).uploadFromBitmapData(zNegtive, 5, 0);
			
			var i:int;
			var dimension:uint;
			var bmd:BitmapData;
			var matrix:Matrix;
			var mipLevel:uint;
			for(i = 0; i < bmds.length; i ++)
			{
				dimension = size;
				matrix = new Matrix();
				mipLevel = 0;
				while(dimension > 0)
				{
					if(bmd)
						bmd.dispose();
					bmd = new BitmapData(dimension, dimension, bmds[i].transparent);
					bmd.draw(bmds[i], matrix, null, null, null, true);
					CubeTexture(_texture).uploadFromBitmapData(bmd, i, mipLevel);
					matrix.scale(0.5, 0.5);
					mipLevel ++;
					dimension >>= 1;
				}
			}
		}
		
		override public function dispose():void
		{
			super.dispose();
			if(bmds)
			{
				bmds.length = 0;
				bmds = null;
			}
		}
		
		private function handleCubeTextureBitmapData(bitmapData:BitmapData):void
		{
			var xPositive:BitmapData;
			var xNegtive:BitmapData;
			var yPositive:BitmapData;
			var yNegtive:BitmapData;
			var zPositive:BitmapData;
			var zNegtive:BitmapData;
			
			if(bitmapData.width * 4 == bitmapData.height * 3)
			{
				size = bitmapData.height / 4;
				
				xPositive = new BitmapData(size, size, bitmapData.transparent);
				xPositive.copyPixels(bitmapData, new Rectangle(size * 2, size, size, size), new Point(0, 0));
				xPositive = handleXPositive(xPositive);
				xPositive = CalculateSingle.handleTextureBMD(xPositive);
				
				xNegtive = new BitmapData(size, size, bitmapData.transparent);
				xNegtive.copyPixels(bitmapData, new Rectangle(0, size, size, size), new Point(0, 0));
				xNegtive = handleXNegative(xNegtive);
				xNegtive = CalculateSingle.handleTextureBMD(xNegtive);
				
				yPositive = new BitmapData(size, size, bitmapData.transparent);
				yPositive.copyPixels(bitmapData, new Rectangle(size, size, size, size), new Point(0, 0));
				yPositive = verticalMirror(yPositive);
				yPositive = CalculateSingle.handleTextureBMD(yPositive);
				
				yNegtive = new BitmapData(size, size, bitmapData.transparent);
				yNegtive.copyPixels(bitmapData, new Rectangle(size, size * 3, size, size), new Point(0, 0));
				yNegtive = verticalMirror(yNegtive);
				yNegtive = CalculateSingle.handleTextureBMD(yNegtive);
				
				zPositive = new BitmapData(size, size, bitmapData.transparent);
				zPositive.copyPixels(bitmapData, new Rectangle(size, 0, size, size), new Point(0, 0));
				zPositive = verticalMirror(zPositive);
				zPositive = CalculateSingle.handleTextureBMD(zPositive);
				
				zNegtive = new BitmapData(size, size, bitmapData.transparent);
				zNegtive.copyPixels(bitmapData, new Rectangle(size, size * 2, size, size), new Point(0, 0));
				zNegtive = horizonMirror(zNegtive);
				zNegtive = CalculateSingle.handleTextureBMD(zNegtive);
				
				bmds = new Vector.<BitmapData>();
				bmds.push(xPositive, xNegtive, yPositive, yNegtive, zPositive, zNegtive);
				size = xPositive.width;
			}
			else
			{
				if(bitmapData.width * 3 != bitmapData.height * 4)
					bitmapData = convertSphereTextureToBoxTexture(bitmapData, 256);
				
				size = bitmapData.width / 4;
				
				xPositive = new BitmapData(size, size, bitmapData.transparent);
				xPositive.copyPixels(bitmapData, new Rectangle(size * 2, size, size, size), new Point(0, 0));
				xPositive = handleXPositive(xPositive);
				xPositive = CalculateSingle.handleTextureBMD(xPositive);
				
				xNegtive = new BitmapData(size, size, bitmapData.transparent);
				xNegtive.copyPixels(bitmapData, new Rectangle(0, size, size, size), new Point(0, 0));
				xNegtive = handleXNegative(xNegtive);
				xNegtive = CalculateSingle.handleTextureBMD(xNegtive);
				
				yPositive = new BitmapData(size, size, bitmapData.transparent);
				yPositive.copyPixels(bitmapData, new Rectangle(size, size, size, size), new Point(0, 0));
				yPositive = verticalMirror(yPositive);
				yPositive = CalculateSingle.handleTextureBMD(yPositive);
				
				yNegtive = new BitmapData(size, size, bitmapData.transparent);
				yNegtive.copyPixels(bitmapData, new Rectangle(size * 3, size, size, size), new Point(0, 0));
				yNegtive = horizonMirror(yNegtive);
				yNegtive = CalculateSingle.handleTextureBMD(yNegtive);
				
				zPositive = new BitmapData(size, size, bitmapData.transparent);
				zPositive.copyPixels(bitmapData, new Rectangle(size, 0, size, size), new Point(0, 0));
				zPositive = verticalMirror(zPositive);
				zPositive = CalculateSingle.handleTextureBMD(zPositive);
				
				zNegtive = new BitmapData(size, size, bitmapData.transparent);
				zNegtive.copyPixels(bitmapData, new Rectangle(size, size * 2, size, size), new Point(0, 0));
				zNegtive = horizonMirror(zNegtive);
				zNegtive = CalculateSingle.handleTextureBMD(zNegtive);
				
				bmds = new Vector.<BitmapData>();
				bmds.push(xPositive, xNegtive, yPositive, yNegtive, zPositive, zNegtive);
				size = xPositive.width;
			}
		}
		
		/**
		 * 线顺时针转90度，再水平镜像。 
		 * @param src
		 * @return 
		 * 
		 */		
		private function handleXPositive(src:BitmapData):BitmapData
		{
			var ret:BitmapData = new BitmapData(src.width, src.height, true);
			var matrix:Matrix = new Matrix();
			matrix.rotate(Math.PI / 2);
			matrix.scale(-1, 1);
			ret.draw(src, matrix, null, null, null, false);
			return ret;
		}
		
		/**
		 * 线逆时针转90度，再水平镜像。 
		 * @param src
		 * @return 
		 * 
		 */		
		private function handleXNegative(src:BitmapData):BitmapData
		{
			var ret:BitmapData = new BitmapData(src.width, src.height, true);
			var matrix:Matrix = new Matrix();
			matrix.rotate(-Math.PI / 2);
			matrix.scale(-1, 1);
			matrix.translate(src.height, src.width);
			ret.draw(src, matrix, null, null, null, false);
			return ret;
		}
		
		/**
		 * 垂直镜像。 
		 * @param src
		 * @return 
		 * 
		 */		
		private function verticalMirror(src:BitmapData):BitmapData
		{
			var ret:BitmapData = new BitmapData(src.width, src.height, true);
			var matrix:Matrix = new Matrix();
			matrix.scale(1, -1);
			matrix.ty = src.height;
			ret.draw(src, matrix, null, null, null, false);
			return ret;
		}
		
		/**
		 * 水平镜像。 
		 * @param src
		 * @return 
		 * 
		 */		
		private function horizonMirror(src:BitmapData):BitmapData
		{
			var ret:BitmapData = new BitmapData(src.width, src.height, true);
			var matrix:Matrix = new Matrix();
			matrix.scale(-1, 1);
			matrix.translate(src.width, 0);
			ret.draw(src, matrix, null, null, null, false);
			return ret;
		}
		
		public function convertSphereTextureToBoxTexture(sphere:BitmapData, boxSize:int):BitmapData
		{
			var ret:BitmapData;
			
			var i:int;
			var j:int;
			var k:int;
			var v0:Vector3D = new Vector3D();
			var uv:Point = new Point();
			
			var t0:uint = getTimer();
			
			var bmds:Vector.<BitmapData> = new Vector.<BitmapData>(6);
			for(k = 0; k < 6; k ++)
			{
				bmds[k] = new BitmapData(boxSize, boxSize, false);
				for(i = 0 ; i < boxSize; i ++)
					for(j = 0; j < boxSize; j ++)
					{
						if(k == 0) //xPositive
						{
							v0.x = boxSize * 0.5;
							v0.y = boxSize * 0.5 - i;
							v0.z = boxSize * 0.5 - j;
						}
						else if(k == 1) //xNegative
						{
							v0.x = -boxSize * 0.5;
							v0.y = -(boxSize * 0.5 - i);
							v0.z = boxSize * 0.5 - j;
						}
						else if(k == 2) //yPositive
						{
							v0.x = -(boxSize * 0.5 - i);
							v0.y = boxSize * 0.5;
							v0.z = boxSize * 0.5 - j;
						}
						else if(k == 3) //yNegative
						{
							v0.x = boxSize * 0.5 - i;
							v0.y = -boxSize * 0.5;
							v0.z = boxSize * 0.5 - j;
						}
						else if(k == 4) //zPositive
						{
							v0.x = -(boxSize * 0.5 - i);
							v0.y = -(boxSize * 0.5 - j);
							v0.z = boxSize * 0.5;
						}
						else if(k == 5) //zNegative
						{
							v0.x = -(boxSize * 0.5 - i);
							v0.y = boxSize * 0.5 - j;
							v0.z = -boxSize * 0.5;
						}
						v0.normalize();
						
						uv.x = 0.5 - Math.atan2(v0.y, v0.x) / (2 * Math.PI);
						uv.y = 0.5 - Math.asin(v0.z) / Math.PI;
						if(sphere.transparent)
							bmds[k].setPixel32(i, j, getPixel32ByUV(uv, sphere));
						else
							bmds[k].setPixel(i, j, getPixelByUV(uv, sphere));
					}
			}
			
			trace("生产6张小图花费时间：" + (getTimer() - t0) / 1000 + "s");
			t0 = getTimer();
			
			//copyPiexls to generate a box texture.
			ret = new BitmapData(boxSize * 4, boxSize * 3, sphere.transparent);
			ret.copyPixels(bmds[0], new Rectangle(0, 0, boxSize, boxSize), new Point(2 * boxSize, 1 * boxSize), null, null, false); //copy xPositive
			ret.copyPixels(bmds[1], new Rectangle(0, 0, boxSize, boxSize), new Point(0 * boxSize, 1 * boxSize), null, null, false); //copy xNegative
			ret.copyPixels(bmds[2], new Rectangle(0, 0, boxSize, boxSize), new Point(1 * boxSize, 1 * boxSize), null, null, false); //copy yPositive
			ret.copyPixels(bmds[3], new Rectangle(0, 0, boxSize, boxSize), new Point(3 * boxSize, 1 * boxSize), null, null, false); //copy yNegative
			ret.copyPixels(bmds[4], new Rectangle(0, 0, boxSize, boxSize), new Point(1 * boxSize, 0 * boxSize), null, null, false); //copy zPositive
			ret.copyPixels(bmds[5], new Rectangle(0, 0, boxSize, boxSize), new Point(1 * boxSize, 2 * boxSize), null, null, false); //copy zNegative
			
			trace("生产4X3大图花费时间：" + (getTimer() - t0) / 1000 + "s");
			
			return ret;
		}
		
		public function getPixelByUV(uv:Point, source:BitmapData):uint
		{
			return source.getPixel(int(source.width * uv.x), int(source.height * uv.y));
		}
		
		public function getPixel32ByUV(uv:Point, source:BitmapData):uint
		{
			return source.getPixel32(int(source.width * uv.x), int(source.height * uv.y));
		}
	}
}