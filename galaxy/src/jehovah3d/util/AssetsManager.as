package jehovah3d.util
{
	import flash.display.BitmapData;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.material.DiffuseMtl;
	import jehovah3d.core.resource.CubeTextureResource;
	import jehovah3d.core.resource.TextureResource;

	public class AssetsManager
	{
		public static var textureResourceDict:Dictionary = new Dictionary();
		public static var diffuseMtlDict:Dictionary = new Dictionary();
		
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
			if(textureResourceDict[key])
				return ;
			var textureResoruce:TextureResource = new TextureResource(bitmapData);
			textureResoruce.upload(Jehovah.context3D);
			textureResourceDict[key] = {"textureResource": textureResoruce, "width": width == 0 ? bitmapData.width : width, "height": height == 0 ? bitmapData.height : height};
		}
		public static function addCubeTextureResource(key:*, bitmapData:BitmapData, width:Number = 0, height:Number = 0):void
		{
			if(textureResourceDict[key])
				return ;
			var textureResoruce:CubeTextureResource = new CubeTextureResource(bitmapData);
			textureResoruce.upload(Jehovah.context3D);
			textureResourceDict[key] = {"textureResource": textureResoruce, "width": width == 0 ? bitmapData.width : width, "height": height == 0 ? bitmapData.height : height};
		}
		
		
		/**
		 * get texture resource.
		 * @param key
		 * @return 
		 * 
		 */		
		public static function getTextureResourceByKey(key:*):Object
		{
			return textureResourceDict[key];
		}
		
		/**
		 * add material. 
		 * @param key
		 * @param mtl
		 * 
		 */		
		public static function addDiffuseMtl(key:*, mtl:DiffuseMtl):void
		{
			if(diffuseMtlDict[key])
				return ;
			mtl.materialInAssetsManager = true;
			diffuseMtlDict[key] = mtl;
		}
		
		/**
		 * get material. 
		 * @param key
		 * @return 
		 * 
		 */		
		public static function getDiffuseMtlByKey(key:*):DiffuseMtl
		{
			return diffuseMtlDict[key];
		}
		
		/**
		 * dispose. 
		 * 
		 */		
		public static function dispose():void
		{
			var keys:Array = [];
			var key:*;
			for(key in textureResourceDict)
				keys.push(key);
			for each(key in keys)
			{
				textureResourceDict[key].textureResource.dispose();
				textureResourceDict[key].textureResource = null;
				delete textureResourceDict[key];
			}
			
			keys.length = 0;
			for(key in diffuseMtlDict)
				keys.push(key);
			for each(key in keys)
			{
				DiffuseMtl(diffuseMtlDict[key]).dispose();
				delete diffuseMtlDict[key];
			}
		}
	}
}