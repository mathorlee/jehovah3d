package utils.bulkloader
{
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.Object3D;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.parser.ParserFUWO3D;
	import jehovah3d.util.AssetsManager;
	
	import utils.bulkloader.AdvancedLoader;
	import utils.bulkloader.BulkLoader;
	
	public class FUWO3Dloader extends EventDispatcher
	{
		public static const LOADING_COMPLETE:String = "LoadingComplete";
		public static const LOADING_FAILED:String = "LoadingFailed";
		
		/**
		 * 全局开关，若为true，只加载FUWO3D文件，不加在贴图
		 */		
		public static const LOAD_TEXTURE:Boolean = false;
		public var fuwo3dloader:AdvancedLoader;
		public var textureloader:BulkLoader;
		
		public var baseURL:String;
		public var sceneContent:Object3D;
		public var cubeTextureDict:Dictionary;
		public var meshes:Vector.<Mesh> = new Vector.<Mesh>();
		
		public function FUWO3Dloader()
		{
			
		}
		
		public function load():void
		{
			dispose();
			
			if(!fuwo3dloader)
				fuwo3dloader = new AdvancedLoader();
			fuwo3dloader.addEventListener(Event.COMPLETE, onFUWO3DComplete);
			fuwo3dloader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			fuwo3dloader.load(new URLRequest(baseURL + "/model.F3D"), 2);
		}
		
		public function dispose():void
		{
			sceneContent = null;
			cubeTextureDict = null;
			meshes.length = 0;
			
			if(fuwo3dloader)
			{
				fuwo3dloader.removeEventListener(Event.COMPLETE, onFUWO3DComplete);
				fuwo3dloader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				fuwo3dloader.dispose();
				fuwo3dloader = null;
			}
			if(textureloader)
			{
				textureloader.removeEventListener(Event.COMPLETE, onBulkLoaderComplete);
				textureloader.dispose();
				textureloader = null;
			}
		}
		
		private function onIOError(evt:IOErrorEvent):void
		{
			trace("IO Error!");
		}
		
		private function onFUWO3DComplete(evt:Event):void
		{
			//解析FUWO3D
			var data:ByteArray = evt.target.data as ByteArray;
			data.uncompress(CompressionAlgorithm.LZMA);
			var parser:ParserFUWO3D = new ParserFUWO3D();
			parser.data = data;
			parser.baseURL = baseURL + "/";
			parser.parse();
			
			var i:int;
			var j:int;
			var obj3ds:Vector.<Object3D> = parser.parseResult();
			for(i = 0; i < obj3ds.length; i ++)
			{
				if(obj3ds[i] is Mesh)
					meshes.push(obj3ds[i]);
				else
				{
					for(j = 0; j < obj3ds[i].numChildren; j ++)
						if(obj3ds[i].getChildAt(j) is Mesh)
							meshes.push(obj3ds[i].getChildAt(j));
				}
			}
			if(!sceneContent)
				sceneContent = new Object3D();
			for(i = 0; i < obj3ds.length; i ++)
				sceneContent.addChild(obj3ds[i]);
			sceneContent.useMip = true;
			sceneContent.uploadResource(Jehovah.context3D);
			
			if(!LOAD_TEXTURE)
			{
				dispatchEvent(new Event(LOADING_COMPLETE, false, false));
				return ;
			}
			
			//加载材质
			if(!textureloader)
				textureloader = new BulkLoader();
			if(!cubeTextureDict)
				cubeTextureDict = new Dictionary();
			for(i = 0; i < meshes.length; i ++)
			{
				if(meshes[i].mtl.diffuseMapURL)
					textureloader.add(meshes[i].mtl.diffuseMapURL);
				if(meshes[i].mtl.specularMapURL)
					textureloader.add(meshes[i].mtl.specularMapURL);
				if(meshes[i].mtl.bumpMapURL)
					textureloader.add(meshes[i].mtl.bumpMapURL);
				if(meshes[i].mtl.reflectionMapURL)
				{
					textureloader.add(meshes[i].mtl.reflectionMapURL);
					cubeTextureDict[meshes[i].mtl.reflectionMapURL] = true;
				}
				if(meshes[i].mtl.opacityMapURL)
					textureloader.add(meshes[i].mtl.opacityMapURL);
			}
			textureloader.addEventListener(Event.COMPLETE, onBulkLoaderComplete);
			textureloader.load();
		}
		
		private function onBulkLoaderComplete(evt:Event):void
		{
			textureloader.removeEventListener(Event.COMPLETE, onBulkLoaderComplete);
			
			//将贴图资源添加到AssetManager中。
			var keys:Array = [];
			var key:*;
			for(key in textureloader.tasks)
				keys.push(key);
			for each(key in keys)
			{
				if(textureloader.tasks[key].state == BulkLoader.STATE_SUCCESS)
				{
					if(cubeTextureDict[key])
						AssetsManager.addCubeTextureResource(key, Bitmap(textureloader.tasks[key].data).bitmapData.clone());
					else
						AssetsManager.addTextureResource(key, Bitmap(textureloader.tasks[key].data).bitmapData.clone());
				}
			}
			
			//set textureresource.
			var i:int;
			var j:int;
			for(i = 0; i < meshes.length; i ++)
			{
				if(meshes[i].mtl.diffuseMapURL != null)
				{
					if(AssetsManager.getTextureResourceByKey(meshes[i].mtl.diffuseMapURL))
						meshes[i].mtl.diffuseMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.diffuseMapURL).textureResource;
				}
				if(meshes[i].mtl.specularMapURL != null)
				{
					if(AssetsManager.getTextureResourceByKey(meshes[i].mtl.specularMapURL))
						meshes[i].mtl.specularMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.specularMapURL).textureResource;
				}
				if(meshes[i].mtl.bumpMapURL != null)
				{
					if(AssetsManager.getTextureResourceByKey(meshes[i].mtl.bumpMapURL))
						meshes[i].mtl.bumpMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.bumpMapURL).textureResource;
				}
				if(meshes[i].mtl.reflectionMapURL != null)
				{
					if(AssetsManager.getTextureResourceByKey(meshes[i].mtl.reflectionMapURL))
						meshes[i].mtl.reflectionMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.reflectionMapURL).textureResource;
				}
				if(meshes[i].mtl.opacityMapURL != null)
				{
					if(AssetsManager.getTextureResourceByKey(meshes[i].mtl.opacityMapURL))
						meshes[i].mtl.opacityMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.opacityMapURL).textureResource;
				}
			}
			
			dispatchEvent(new Event(LOADING_COMPLETE, false, false));
		}
	}
}