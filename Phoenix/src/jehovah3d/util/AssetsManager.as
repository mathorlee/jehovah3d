package jehovah3d.util
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.material.DiffuseMtl;
	import jehovah3d.core.resource.CubeTextureResource;
	import jehovah3d.core.resource.GeometryResource;
	import jehovah3d.core.resource.TextureResource;

	public class AssetsManager
	{
		private static var textureDict:Dictionary = new Dictionary(); //TextureResource对象池
		private static var geometryDict:Dictionary = new Dictionary(); //GeometryResource对象池
		private static var mtlDict:Dictionary = new Dictionary(); //DiffuseMtl对象池
		
		/**
		 * add texture resource. 
		 * @param key
		 * @param bitmapData
		 * @param width
		 * @param height
		 * 
		 */		
		public static function addTextureResource(key:*, bitmapData:BitmapData, width:Number = 0, height:Number = 0):void
		{
			if(textureDict[key])
				return ;
			if (bitmapData.width > Jehovah.MAX_TEXTURE_SIZE || bitmapData.height > Jehovah.MAX_TEXTURE_SIZE)
			{
				var newBMD:BitmapData = new BitmapData(
					int(Jehovah.MAX_TEXTURE_SIZE * 1.0 / Math.max(bitmapData.width, bitmapData.height) * bitmapData.width), 
					int(Jehovah.MAX_TEXTURE_SIZE * 1.0 / Math.max(bitmapData.width, bitmapData.height) * bitmapData.height), 
					bitmapData.transparent
				);
				var matrix:Matrix = new Matrix();
				matrix.scale(1.0 * newBMD.width / bitmapData.width, 1.0 * newBMD.height / bitmapData.height);
				newBMD.draw(bitmapData, matrix, null, null, null, true);
				bitmapData.dispose();
				bitmapData = newBMD;
			}
			var resource:TextureResource = new TextureResource(bitmapData);
			resource.upload(Jehovah.context3D);
			resource.isInObjectPool = true;
			textureDict[key] = {"resource": resource, "width": width == 0 ? bitmapData.width : width, "height": height == 0 ? bitmapData.height : height};
		}
		
		public static function removeResoruce(key:*):void
		{
			if (textureDict[key])
			{
				textureDict[key].resource.dispose();
				textureDict[key].resource.isInObjectPool = false;
				textureDict[key].resource = null;
				delete textureDict[key];
			}
		}
		public static function addCubeTextureResource(key:*, bitmapData:BitmapData, width:Number = 0, height:Number = 0):void
		{
			if(textureDict[key])
				return ;
			var resource:CubeTextureResource = new CubeTextureResource(bitmapData);
			resource.upload(Jehovah.context3D);
			resource.isInObjectPool = true;
			textureDict[key] = {"resource": resource, "width": width == 0 ? bitmapData.width : width, "height": height == 0 ? bitmapData.height : height};
		}
		
		public static function addGeometryResource(key:*, resource:GeometryResource):void
		{
			if(geometryDict[key])
				return ;
			resource.upload(Jehovah.context3D);
			resource.isInObjectPool = true;
			geometryDict[key] = {"resource": resource};
		}
		
		/**
		 * get texture resource.
		 * @param key
		 * @return 
		 * 
		 */		
		public static function getTextureResourceByKey(key:*):Object
		{
			return textureDict[key];
		}
		
		public static function getGeometryResourceByKey(key:*):GeometryResource
		{
			if (!geometryDict[key])
				return null;
			return geometryDict[key].resource as GeometryResource;
		}
		
		/**
		 * add material. 
		 * @param key
		 * @param mtl
		 * 
		 */		
		public static function addDiffuseMtl(key:*, mtl:DiffuseMtl):void
		{
			if(mtlDict[key])
				return ;
			mtl.isInObjectPool = true;
			mtlDict[key] = mtl;
		}
		
		public static function removeDiffuseMtl(key:*):void
		{
			if (mtlDict[key])
			{
				mtlDict[key].dispose();
				delete mtlDict[key];
			}
		}
		
		/**
		 * get material. 
		 * @param key
		 * @return 
		 * 
		 */		
		public static function getDiffuseMtlByKey(key:*):DiffuseMtl
		{
			return mtlDict[key];
		}
		
		/**
		 * dispose. 
		 * 
		 */		
		public static function dispose():void
		{
			var key:*;
			for (key in textureDict)
			{
				textureDict[key].resource.dispose();
				textureDict[key].resource = null;
				delete textureDict[key];
			}
			
			for(key in mtlDict)
			{
				DiffuseMtl(mtlDict[key]).dispose();
				delete mtlDict[key];
			}
			
			for (key in geometryDict)
			{
				geometryDict[key].resource.dispose();
				geometryDict[key].resource = null;
				delete textureDict[key];
			}
		}
	}
}