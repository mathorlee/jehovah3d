package com.fuwo
{
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	
	public class CalculateSingle extends EventDispatcher
	{
		
		public static var alphaPixelNum:uint = 0;
		/**
		 * calculate shadow.
		 * @param src
		 * @param radius
		 * @return 
		 * 
		 */
		public static function calculateShadow(src:BitmapData):BitmapData
		{
			alphaPixelNum = 0;
			
			var maxIntensity:uint = 128;
			var maxAlpha:uint = uint(0.3 * 255);
			var circle:int = 6;
			
			var graph:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var sum:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
//			var intensityGraph:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			var i:int;
			var j:int;
			var width:int = src.width;
			var height:int = src.height;
			var pixel:uint;
			var alpha:uint;
			for(i = 0; i < width + circle * 2; i ++)
			{
				graph.push(new Vector.<Number>());
				sum.push(new Vector.<Number>());
//				intensityGraph.push(new Vector.<Number>());
				for(j = 0; j < height + circle * 2; j ++)
				{
					graph[i].push(0);
					sum[i].push(0);
//					intensityGraph[i].push(0);
				}
			}
			for(i = 0; i < width; i ++)
				for(j = 0; j < height; j ++)
				{
					pixel = src.getPixel32(i, j);
					alpha = (pixel >>> 24);
					if(alpha > 0)
						graph[i + circle][j + circle] = 1;
					else
						alphaPixelNum++;
				}
			for(i = 0 + circle; i < width + circle * 2; i ++)
				for(j = 0 + circle; j < height + circle * 2; j ++)
				{
					sum[i][j] = sum[i - 1][j] + sum[i][j - 1] - sum[i - 1][j - 1] + graph[i][j];
				}
			
			var ret:BitmapData = new BitmapData(width + circle * 2, height + circle * 2, true);
			
			for(i = 0; i < width + circle * 2; i ++)
				for(j = 0; j < height + circle * 2; j ++)
				{
					var val:Number = getIntensity(sum, width + circle * 2, height + circle * 2, circle, i, j);
					val /= (circle * 2 + 1) * (circle * 2 + 1);
					var newAlpha:uint = maxAlpha * val;
					var newIntensity:uint = maxIntensity * (1 - val);
					ret.setPixel32(i, j, (newAlpha << 24) | (newIntensity << 16) | (newIntensity << 8) | newIntensity);
//					var t:uint = (newAlpha << 24) | (newIntensity << 16) | (newIntensity << 8) | newIntensity;
//					intensityGraph[i][j] = val;
				}
			return ret;
		}
		
		private static function getIntensity(sum:Vector.<Vector.<Number>>, width:int, height:int, circle:int, i:int, j:int):Number
		{
			var ret:Number = 0;
			var maxX:int = i + circle > width - 1 ? width - 1 : i + circle;
			var maxY:int = j + circle > height - 1 ? height - 1 : j + circle;
			ret += sum[maxX][maxY];
			if(i - circle - 1 >= 0)
				ret -= sum[i - circle - 1][maxY];
			if(j - circle - 1 >= 0)
				ret -= sum[maxX][j - circle - 1];
			if(i - circle - 1 >= 0 && j - circle - 1 >= 0)
				ret += sum[i - circle - 1][j - circle - 1];
			return ret;
		}
		
		/**
		 * 将图片转为纯色。保留透明通道。 
		 * @param bitmapData
		 * @param pureColor
		 * @return 
		 * 
		 */		
		public static function convertColorFulToPureColor(bitmapData:BitmapData, pureColor:uint = 0xAA999999):BitmapData
		{
			var ret:BitmapData = bitmapData.clone();
			var i:int;
			var j:int;
			for(i = 0; i < ret.width; i ++)
			{
				for(j = 0; j < ret.height; j ++)
				{
					var color:uint = ret.getPixel32(i, j);
					var alpha:uint = (color >>> 24);
					//alpha = color / 16777216;
					if(alpha != 0)
						ret.setPixel32(i, j, pureColor);
					else
						ret.setPixel32(i, j, (1 << 32));
				}
			}
			return ret;
		}
		
		public static function horizonMirrorBitmapData(src:BitmapData):BitmapData
		{
			var ret:BitmapData = new BitmapData(src.width, src.height, true);
			var matrix:Matrix = new Matrix();
			matrix.scale(-1, 1);
			matrix.tx = src.width;
			ret.draw(src, matrix, null, null, null, false);
			return ret;
		}
		
		/**
		 * 拉伸图片至2^n*2^n. 
		 * @param bitmapData
		 * @param bound
		 * @return 
		 * 
		 */		
		public static function deleteMarginOfPNG(bitmapData:BitmapData, bound:Object = null):BitmapData
		{
			if(!bound)
			{
				bound = new Object();
				bound.x1 = 0;
				bound.y1 = 0;
				bound.x2 = bitmapData.width - 1;
				bound.y2 = bitmapData.height - 1;
			}
			var solidWidth:Number = bound.x2 - bound.x1 + 1;
			var solidHeight:Number = bound.y2 - bound.y1 + 1;
			var solid:BitmapData = new BitmapData(solidWidth, solidHeight, true, 0x00FFFFFF);
			solid.copyPixels(bitmapData, new Rectangle(bound.x1, bound.y1, solidWidth, solidHeight), new Point(0, 0));
			
			var retSize:Number = stretchBitmapData(solidWidth, solidHeight);
			var ret:BitmapData = new BitmapData(retSize, retSize, true, 0x00FFFFFF);
			var matrix:Matrix = new Matrix();
			matrix.scale(1.0 * retSize / solidWidth, 1.0 * retSize / solidHeight);
			ret.draw(solid, matrix, null, null, null, false);
			return ret;
		}
		
		/**
		 * 不拉伸，直接将非透明区域图片复复制到一张空的2^n*2*n的图片上。赋予材质时用uv坐标。 
		 * @param bitmapData
		 * @param bound
		 * @return 
		 * 
		 */		
		public static function deleteMarginOfPNG2(bitmapData:BitmapData, bound:Object = null):BitmapData
		{
			if(!bound)
			{
				bound = new Object();
				bound.x1 = 0;
				bound.y1 = 0;
				bound.x2 = bitmapData.width - 1;
				bound.y2 = bitmapData.height - 1;
			}
			var solidWidth:Number = bound.x2 - bound.x1 + 1;
			var solidHeight:Number = bound.y2 - bound.y1 + 1;
			
			var retSize:Number = stretchBitmapData(solidWidth, solidHeight);
			var ret:BitmapData = new BitmapData(retSize, retSize, true, 0x00FFFFFF);
			ret.copyPixels(bitmapData, new Rectangle(bound.x1, bound.y1, solidWidth, solidHeight), new Point(0, 0));
			return ret;
		}
		
		public static function handleTextureBMD(bmd:BitmapData):BitmapData
		{
			var w0:int = ceilingPower2(bmd.width);
			var h0:int = ceilingPower2(bmd.height);
			if(w0 == bmd.width && h0 == bmd.height)
				return bmd;
			if(w0 > 2048)
				w0 = 2048;
			if(h0 > 2048)
				h0 = 2048;
			var ret:BitmapData = new BitmapData(w0, h0, bmd.transparent);
			var matrix:Matrix = new Matrix();
			matrix.scale(1.0 * w0 / bmd.width, 1.0 * h0 / bmd.height);
			ret.draw(bmd, matrix, null, null, null, true);
			return ret;
		}
		public static function ceilingPower2(value:int):int
		{
			var mi:int = Math.ceil(Math.log(value) / Math.log(2));
			return Math.pow(2, mi);
		}
		public static function calculateBoundOfPNG(bitmapData:BitmapData):Object
		{
			var ret:Object = new Object();
			var width:int = bitmapData.width;
			var height:int = bitmapData.height;
			var column:Array = new Array();
			var row:Array = new Array();
			var i:int;
			var j:int;
			var color:uint;
			var alpha:uint;
			var transparent:Boolean;
			for(i = 0; i < width; i ++)
			{
				transparent = true;
				for(j = 0; j < height; j ++)
				{
					color = bitmapData.getPixel32(i, j);
					alpha = (color >>> 24);
					//alpha = color / 16777216;
					if(alpha != 0)
					{
						//trace(color);
						//trace(alpha);
						transparent = false;
						break;
					}
				}
				if(transparent)
					column.push(true);
				else
					column.push(false);
			}
			
			for(i = 0; i < height; i ++)
			{
				transparent = true;
				for(j = 0; j < width; j ++)
				{
					color = bitmapData.getPixel32(j, i);
					alpha = (color >>> 24);
					if(alpha != 0)
					{
						transparent = false;
						break;
					}
				}
				if(transparent)
					row.push(true);
				else
					row.push(false);
			}
			
			//outputArray(column);
			//outputArray(row);
			
			for(i = 0; i < width; i ++)
				if(column[i] == false)
				{
					ret.x1 = i;
					break;
				}
			for(i = width - 1; i >=0; i --)
				if(column[i] == false)
				{
					ret.x2 = i;
					break;
				}
			
			for(i = 0; i < height; i ++)
				if(row[i] == false)
				{
					ret.y1 = i;
					break;
				}
			for(i = height - 1; i >=0; i --)
				if(Boolean(row[i]) == false)
				{
					ret.y2 = i;
					break;
				}
			return ret;
		}
		
		/**
		 * 将任意尺寸的bitmapdata拉伸为2^n*2^n的btimapdata 
		 * @param solidWidth
		 * @param solidHeight
		 * @return 
		 * 
		 */		
		public static function stretchBitmapData(solidWidth:Number, solidHeight:Number):Number
		{
			var tmp:int = int(Math.max(solidWidth, solidHeight));
			var tmp2:int = Math.ceil(Math.log(tmp) / Math.log(2));
			return Math.pow(2, tmp2);
		}
		
		private static function outputArray(arr:Array):void
		{
			var str:String = "";
			for(var i:int = 0; i < arr.length; i ++)
				if(arr[i] == true)
					str += "1 ";
				else if(arr[i] == false)
					str += "0 ";
		}
		
		
		public static function calculateBBCoordinate2(matrix:Matrix3D, planeWidth:Number, planeHeight:Number):Vector3D
		{
			var v1:Vector3D;
			var viewAngle:Number = 30;
			if(viewAngle == 45)
				v1 = new Vector3D(0, 0, planeHeight / 2.0);
			else if(viewAngle == 30)
				v1 = new Vector3D(0, 0, planeHeight / 2.0 * Math.sqrt(3));
			v1 = matrix.transformVector(v1);
			return v1;
		}
	}
}