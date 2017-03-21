package
{
	import com.adobe.images.JPGEncoder;
	import com.adobe.images.PNGEncoder;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.net.FileReference;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	public class SphereTextureToBoxTexture extends Sprite
	{
		[Embed(source="assets/sphere/1.jpg", mimeType="image/jpeg")]
		private var SPHERE:Class;
		
		private var sphereTexture:BitmapData;
		private var boxTexture:BitmapData;
		private var boxSize:int;
		private var lock:int;
		
		public function SphereTextureToBoxTexture()
		{
			this.addEventListener(Event.ADDED_TO_STAGE, addToStage);
		}
		
		private function addToStage(evt:Event):void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			trace("stage");
		}
		
		private function onKeyDown(evt:KeyboardEvent):void
		{
			trace("keydown");
			switch(evt.keyCode)
			{
				case Keyboard.A:
					test();
					break;
				
				case Keyboard.B:
					var fr:FileReference = new FileReference();
					if(boxTexture.transparent)
					{
						trace("png");
						fr.save(PNGEncoder.encode(boxTexture), "box.png");
					}	
					else
					{
						trace("jpg");
						var jpg:JPGEncoder = new JPGEncoder();
						fr.save(jpg.encode(boxTexture), "box.jpg");

					}
					break;
				
				default:
					break;
			}
		}
		
		private function test():void
		{
			sphereTexture = new SPHERE().bitmapData as BitmapData;
			//2*pi*r, pi*r, a / 2 * sqrt(3) = r =>a = bmd_width / pi / sqrt(3)
			boxSize = int(1.5 * sphereTexture.width / Math.PI / Math.sqrt(3));
			boxTexture = convertSphereTextureToBoxTexture34(sphereTexture, boxSize);
			trace("convert complete");
		}
		public function convertSphereTextureToBoxTexture43(sphere:BitmapData, boxSize:int):BitmapData
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
		public function convertSphereTextureToBoxTexture34(sphere:BitmapData, boxSize:int):BitmapData
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
							v0.x = -(boxSize * 0.5 - i);
							v0.y = -boxSize * 0.5;
							v0.z = -(boxSize * 0.5 - j);
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
			ret = new BitmapData(boxSize * 3, boxSize * 4, sphere.transparent);
			ret.copyPixels(bmds[0], new Rectangle(0, 0, boxSize, boxSize), new Point(2 * boxSize, 1 * boxSize), null, null, false); //copy xPositive
			ret.copyPixels(bmds[1], new Rectangle(0, 0, boxSize, boxSize), new Point(0 * boxSize, 1 * boxSize), null, null, false); //copy xNegative
			ret.copyPixels(bmds[2], new Rectangle(0, 0, boxSize, boxSize), new Point(1 * boxSize, 1 * boxSize), null, null, false); //copy yPositive
			ret.copyPixels(bmds[3], new Rectangle(0, 0, boxSize, boxSize), new Point(1 * boxSize, 3 * boxSize), null, null, false); //copy yNegative
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