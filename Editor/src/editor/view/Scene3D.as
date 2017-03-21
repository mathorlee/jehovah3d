package editor.view
{
	import com.adobe.images.JPGEncoder;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.display3D.Context3DBlendFactor;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	import flash.utils.Dictionary;
	
	import editor.view.mediator.Scene3DMediator;
	
	import jehovah3d.Jehovah;
	import jehovah3d.controller.SelectManager;
	import jehovah3d.controller.SelectMove;
	import jehovah3d.core.Bounding;
	import jehovah3d.core.Camera3D;
	import jehovah3d.core.Object3D;
	import jehovah3d.core.background.BitmapTextureBG;
	import jehovah3d.core.event.MouseEvent3D;
	import jehovah3d.core.light.FreeLight3D;
	import jehovah3d.core.light.Light3D;
	import jehovah3d.core.material.StdMtl;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.pick.MousePickManager;
	import jehovah3d.core.pick.Plane;
	import jehovah3d.core.pick.Ray;
	import jehovah3d.core.resource.GeometryResource;
	import jehovah3d.core.resource.TextureResource;
	import jehovah3d.core.wireframe.WireFrame;
	import jehovah3d.parser.ParserFUWO3D;
	import jehovah3d.primitive.PrimitivePlane;
	import jehovah3d.util.AssetsManager;
	
	import utils.easybutton.EasyButton;
	import utils.easybutton.EasyButtonState;
	
	public class Scene3D extends Scene3DTemplateForFlexProject
	{
		private const BACKGROUN_COLOR:uint = 0x7F7F7F;
		private const RULER_COLOR:uint = 0x333333;
		public static const CAMERA_CHANGE:String = "CameraChange";
		
		public var useLight:int = 1;
		public var showButtom:int = 1;
		public var useMip:int = 1;
		
		private var sceneContent:Object3D; //存储场景
		private var ruler:Object3D; //存储尺寸向相关
		private var sceneBG:Object3D; //存储_bg_
		public var obj3ds:Vector.<Object3D>;
		public var bg3d:BitmapTextureBG;
		
		public var missingTextureDict:Dictionary = new Dictionary();
		
		public var selectMove:SelectMove;
		public var selectManager:SelectManager;
		
		public function Scene3D()
		{
			super();
		}
		
		override public function initCamera():void
		{
			camera = new Camera3D(stage.stageWidth, stage.stageHeight, 1, 1500.0,  Math.PI * 3 / 8, false, BACKGROUN_COLOR);
		}
		override public function initScene():void
		{
			initLight();
			
			sceneContent = new Object3D();
			sceneContent.mouseEnabled = false;
			scene.addChild(sceneContent);
			sceneBG = new Object3D();
			sceneBG.mouseEnabled = false;
			scene.addChild(sceneBG);
			ruler = new Object3D();
			ruler.visible = false;
			scene.addChild(ruler);
			selectMove = new SelectMove(60);
			selectMove.visible = false;
			scene.addChild(selectMove);
			selectManager = new SelectManager();
			
			initBehavior();
			initUI();
		}
		private function onEnterFrame(evt:Event):void
		{
			//add deafult rotate z each frame.
			if(resetMode)
				RZ += 0.015;
			
			//add inertia rotate.
			if(useInertia)
			{
				RX += initSpeedRX - initSpeedRX / totalInertiaCount * currentInertiaCount;
				RZ += initSpeedRZ - initSpeedRZ / totalInertiaCount * currentInertiaCount;
				currentInertiaCount ++;
				if(currentInertiaCount >= totalInertiaCount)
					useInertia = false;
			}
			//set limit to RX.
			if(RX > maxRX)
				RX = maxRX;
			if(RX < minRX)
				RX = minRX;
			
			//update scene matrix.
			updateTarget();
			
			camera.render();
		}
		
		override public function onResize(evt:Event = null):void
		{
			super.onResize(evt);
			if(bounding)
				resetTargetAndCamera();
			if(this.width > 0 && this.height > 0)
			{
				if(logo)
					logo.y = this.height - logo.height;
				if(toolbar)
				{
					toolbar.x = (this.width - toolbar.width) * 0.5;
					toolbar.y = this.height - toolbar.height;
				}
			}
		}
		
		private function initLight():void
		{
			var defaultLight:Light3D = new Light3D(0xFFFFFF, 10, 500);
			defaultLight.rotationX = Math.PI / 6;
			defaultLight.rotationZ = 0.75 * Math.PI;
			defaultLight.composeTransform();
			Jehovah.defaultLight = defaultLight;
		}
		public function createAFreeLight():void
		{
			var light:FreeLight3D = new FreeLight3D(0xFFFFFF, 10, bounding.radius * 3, FreeLight3D.TYPE_DIRECTIONAL_LIGHT, FreeLight3D.CONE_CIRCLE, bounding.radius * 2);
			light.z = bounding.radius * 1.5;
			light.composeTransform();
			light.calculateProjectionMatrix();
			light.useShadow = true;
			scene.addChild(light);
			Jehovah.lights.push(light);
		}
		private function retrieveMeshes():Vector.<Mesh>
		{
			var ret:Vector.<Mesh> = new Vector.<Mesh>();
			var i:int;
			var j:int;
			for(i = 0; i < obj3ds.length; i ++)
			{
				if(obj3ds[i] is Mesh)
					ret.push(obj3ds[i]);
				else
				{
					for(j = 0; j < obj3ds[i].numChildren; j ++)
						if(obj3ds[i].getChildAt(j) is Mesh)
							ret.push(obj3ds[i].getChildAt(j));
				}
			}
			return ret;
		}
		public function updateBackgroundImage(bitmapData:BitmapData):void
		{
			if(!bg3d)
			{
				bg3d = new BitmapTextureBG(bitmapData);
				scene.addChild(bg3d);
			}
			else
				bg3d.updateBackgoundImage(bitmapData);
		}
		public function addMissings(tasks:Dictionary):void
		{
			var i:int;
			var meshes:Vector.<Mesh> = retrieveMeshes();
			for(i = 0; i < meshes.length; i ++)
			{
				if(meshes[i].mtl.needDiffuse && !meshes[i].mtl.useDiffuseMapChannel)
				{
					if(tasks[meshes[i].mtl.diffuseMapURL])
					{
						AssetsManager.addTextureResource(meshes[i].mtl.diffuseMapURL, tasks[meshes[i].mtl.diffuseMapURL].data.bitmapData);
						meshes[i].mtl.diffuseMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.diffuseMapURL).textureResource;
					}
				}
				if(meshes[i].mtl.needSpecular && !meshes[i].mtl.useSpecularMapChannel)
				{
					if(tasks[meshes[i].mtl.specularMapURL])
					{
						AssetsManager.addTextureResource(meshes[i].mtl.specularMapURL, tasks[meshes[i].mtl.specularMapURL].data.bitmapData);
						meshes[i].mtl.specularMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.specularMapURL).textureResource;
					}
				}
				if(meshes[i].mtl.needBump && !meshes[i].mtl.useBumpMapChannel)
				{
					if(tasks[meshes[i].mtl.bumpMapURL])
					{
						AssetsManager.addTextureResource(meshes[i].mtl.bumpMapURL, tasks[meshes[i].mtl.bumpMapURL].data.bitmapData);
						meshes[i].mtl.bumpMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.bumpMapURL).textureResource;
					}
				}
				if(meshes[i].mtl.needReflection && !meshes[i].mtl.useReflectionMapChannel)
				{
					if(tasks[meshes[i].mtl.reflectionMapURL])
					{
						AssetsManager.addCubeTextureResource(meshes[i].mtl.reflectionMapURL, tasks[meshes[i].mtl.reflectionMapURL].data.bitmapData);
						meshes[i].mtl.reflectionMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.reflectionMapURL).textureResource;
					}
				}
				if(meshes[i].mtl.needOpacity && !meshes[i].mtl.useOpacityMapChannel)
				{
					if(tasks[meshes[i].mtl.opacityMapURL])
					{
						AssetsManager.addTextureResource(meshes[i].mtl.opacityMapURL, tasks[meshes[i].mtl.opacityMapURL].data.bitmapData);
						meshes[i].mtl.opacityMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.opacityMapURL).textureResource;
					}
				}
			}
			for(i = 0; i < meshes.length; i ++)
				meshes[i].disposeShader();
			
			var key:*;
			for(key in tasks)
				if(missingTextureDict[key])
					delete missingTextureDict[key];
			
			dispatchEvent(new Event(Scene3DMediator.MISSING_TEXTURE, false, false));
		}
		
		private function parseOBJ(objString:String):void
		{
			var arr:Array = objString.split("\n");
			var arr2:Array = [];
			
			var vertices:Vector.<Number> = new Vector.<Number>();
			var uvs:Vector.<Number> = new Vector.<Number>();
			var indices:Vector.<uint> = new Vector.<uint>();
			
			var i:int;
			var j:int;
			
			for each (var str:String in arr)
			{
				if (str.indexOf("v ") != -1)
				{
					arr2 = str.split(" ");
					vertices.push(Number(arr2[1]), Number(arr2[2]), Number(arr2[3]));
				}
				else if (str.indexOf("vt ") != -1)
				{
					arr2 = str.split(" ");
					uvs.push(Number(arr2[1]), Number(arr2[2]));
				}
				else if (str.indexOf("f ") != -1)
				{
					arr2 = str.split(" ");
					for (i = 1; i < arr2.length; i ++)
					{
						indices.push(int(arr2[i].split("/")[0]) - 1);
					}
				}
			}
			
			sceneContent.removeAllChild();
			sceneBG.removeAllChild();
			ruler.removeAllChild();
			AssetsManager.dispose();
			resetMode = true;
			
			var mesh:Mesh = new Mesh();
			mesh.geometry = new GeometryResource();
			mesh.geometry.coordinateData = vertices;
//			mesh.geometry.diffuseUVData = uvs;
			mesh.geometry.indexData = indices;
			mesh.geometry.calculateNormal();
			mesh.mtl = new StdMtl(0x7F7F7F, 0x7F7F7F, 0xFFFFFF, 10, 10);
			this.sceneContent.addChild(mesh);
			
			scene.useMip = (useMip == 1);
			scene.uploadResource(Jehovah.context3D);
			
			//初始化bounding。
			camera.updateHierarchyMatrix();
			bounding = sceneContent.bounding;
			sceneContent.x = sceneBG.x = -(bounding.minX + bounding.maxX) * 0.5;
			sceneContent.y = sceneBG.y = -(bounding.minY + bounding.maxY) * 0.5;
			sceneContent.z = sceneBG.z = -(bounding.minZ + bounding.maxZ) * 0.5;
			addRuler();
			resetTargetAndCamera();
		}
		public function refreshScene(tasks:Dictionary, fuwo3d:String):void
		{
			var data:ByteArray = tasks[fuwo3d].data as ByteArray;
			if (tasks[fuwo3d].extension == "OBJ")
			{
				this.parseOBJ(data.readMultiByte(data.length, "utf-8"));
				return ;
			}
			
			if(tasks[fuwo3d].extension == "F3D")
				data.uncompress(CompressionAlgorithm.LZMA);
			var parser:ParserFUWO3D = new ParserFUWO3D();
			
			parser.data = data;
			parser.baseURL = "";
			parser.parse();
			
			sceneContent.removeAllChild();
			sceneBG.removeAllChild();
			ruler.removeAllChild();
			AssetsManager.dispose();
			resetMode = true;
			
			obj3ds = parser.parseResult();
			var i:int;
			var j:int;
			
			var excludeDict:Dictionary = new Dictionary();
			for(i = 0; i < obj3ds.length; i ++)
			{
				if(obj3ds[i].name != null && obj3ds[i].name.indexOf("_bg_") != -1)
					sceneBG.addChild(obj3ds[i]);
				else
					sceneContent.addChild(obj3ds[i]);
			}
			scene.useMip = (useMip == 1);
			scene.uploadResource(Jehovah.context3D);
			
			//初始化bounding。
			camera.updateHierarchyMatrix();
			bounding = sceneContent.bounding;
			trace(bounding.width, bounding.length, bounding.height);
			sceneContent.x = sceneBG.x = -(bounding.minX + bounding.maxX) * 0.5;
			sceneContent.y = sceneBG.y = -(bounding.minY + bounding.maxY) * 0.5;
			sceneContent.z = sceneBG.z = -(bounding.minZ + bounding.maxZ) * 0.5;
			addRuler();
			resetTargetAndCamera();
			
			var meshes:Vector.<Mesh> = retrieveMeshes();
			var key:*;
			for(key in missingTextureDict)
				delete missingTextureDict[key];
			
			for(i = 0; i < meshes.length; i ++)
			{
				if(meshes[i].mtl.diffuseMapURL != null)
				{
					if(tasks[meshes[i].mtl.diffuseMapURL])
					{
						AssetsManager.addTextureResource(meshes[i].mtl.diffuseMapURL, tasks[meshes[i].mtl.diffuseMapURL].data.bitmapData);
						meshes[i].mtl.diffuseMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.diffuseMapURL).textureResource;
					}
					else
						missingTextureDict[meshes[i].mtl.diffuseMapURL] = true;
				}
				if(meshes[i].mtl.specularMapURL != null)
				{
					if(tasks[meshes[i].mtl.specularMapURL])
					{
						AssetsManager.addTextureResource(meshes[i].mtl.specularMapURL, tasks[meshes[i].mtl.specularMapURL].data.bitmapData);
						meshes[i].mtl.specularMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.specularMapURL).textureResource;
					}
					else
						missingTextureDict[meshes[i].mtl.specularMapURL] = true;
				}
				if(meshes[i].mtl.bumpMapURL != null)
				{
					if(tasks[meshes[i].mtl.bumpMapURL])
					{
						AssetsManager.addTextureResource(meshes[i].mtl.bumpMapURL, tasks[meshes[i].mtl.bumpMapURL].data.bitmapData);
						meshes[i].mtl.bumpMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.bumpMapURL).textureResource;
					}
					else
						missingTextureDict[meshes[i].mtl.bumpMapURL] = true;
				}
				if(meshes[i].mtl.reflectionMapURL != null)
				{
					if(tasks[meshes[i].mtl.reflectionMapURL])
					{
						AssetsManager.addCubeTextureResource(meshes[i].mtl.reflectionMapURL, tasks[meshes[i].mtl.reflectionMapURL].data.bitmapData);
						meshes[i].mtl.reflectionMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.reflectionMapURL).textureResource;
					}
					else
						missingTextureDict[meshes[i].mtl.reflectionMapURL] = true;
				}
				if(meshes[i].mtl.opacityMapURL != null)
				{
					if(tasks[meshes[i].mtl.opacityMapURL])
					{
						AssetsManager.addTextureResource(meshes[i].mtl.opacityMapURL, tasks[meshes[i].mtl.opacityMapURL].data.bitmapData);
						meshes[i].mtl.opacityMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.opacityMapURL).textureResource;
					}
					else
						missingTextureDict[meshes[i].mtl.opacityMapURL] = true;
				}
			}
			
			onHideRulerClick();
			dispatchEvent(new Event(Scene3DMediator.MISSING_TEXTURE, false, false));
		}
		
		private function addRuler():void
		{
			ruler.z = -bounding.height * 0.5;
			
			bounding.width = Math.floor(bounding.width + 0.5);
			bounding.length = Math.floor(bounding.length + 0.5);
			bounding.height = Math.floor(bounding.height + 0.5);
			
			var x0:Number = bounding.width * 0.5;
			var y0:Number = bounding.length * 0.5;
			var z0:Number = bounding.height * 0.5;
			var x1:Number = x0 * 0.15;
			var y1:Number = y0 * 0.15;
			var z1:Number = z0 * 0.15;
			var average:Number = (x0 + y0 + z0) / 3;
			
			var boundingWF:WireFrame = new WireFrame(Vector.<Vector3D>([
				new Vector3D(x0, y0, 0), 
				new Vector3D(-x0, y0, 0), 
				new Vector3D(-x0, y0, 0), 
				new Vector3D(-x0, -y0, 0), 
				new Vector3D(-x0, -y0, 0), 
				new Vector3D(x0, -y0, 0), 
				new Vector3D(x0, -y0, 0), 
				new Vector3D(x0, y0, 0), 
				
				new Vector3D(x0, y0, z0 * 2), 
				new Vector3D(-x0, y0, z0 * 2), 
				new Vector3D(-x0, y0, z0 * 2), 
				new Vector3D(-x0, -y0, z0 * 2), 
				new Vector3D(-x0, -y0, z0 * 2), 
				new Vector3D(x0, -y0, z0 * 2), 
				new Vector3D(x0, -y0, z0 * 2), 
				new Vector3D(x0, y0, z0 * 2), 
				
				new Vector3D(x0, y0, 0), 
				new Vector3D(x0, y0, z0 * 2), 
				new Vector3D(-x0, y0, 0), 
				new Vector3D(-x0, y0, z0 * 2), 
				new Vector3D(-x0, -y0, 0), 
				new Vector3D(-x0, -y0, z0 * 2), 
				new Vector3D(x0, -y0, 0), 
				new Vector3D(x0, -y0, z0 * 2)
			]), 0xFFFFFF, 1);
			ruler.addChild(boundingWF);
			
			var rulerWF:WireFrame = new WireFrame(Vector.<Vector3D>([
				//x axis
				new Vector3D(x0, -y0, 0), 
				new Vector3D(x0, -y0 - y1, 0), 
				new Vector3D(-x0, -y0, 0), 
				new Vector3D(-x0, -y0 - y1, 0), 
				new Vector3D(x0, -y0 - y1 * 0.5, 0), 
				new Vector3D(-x0, -y0 - y1 * 0.5, 0), 
				
				new Vector3D(x0, -y0 - y1 * 0.5, 0), 
				new Vector3D(x0 - y1 * 0.25 / Math.atan(15 / 180 * Math.PI), -y0 - y1 * 0.25, 0), 
				new Vector3D(x0, -y0 - y1 * 0.5, 0), 
				new Vector3D(x0 - y1 * 0.25 / Math.atan(15 / 180 * Math.PI), -y0 - y1 * 0.75, 0), 
				
				new Vector3D(-x0, -y0 - y1 * 0.5, 0), 
				new Vector3D(-x0 + y1 * 0.25 / Math.atan(15 / 180 * Math.PI), -y0 - y1 * 0.25, 0), 
				new Vector3D(-x0, -y0 - y1 * 0.5, 0), 
				new Vector3D(-x0 + y1 * 0.25 / Math.atan(15 / 180 * Math.PI), -y0 - y1 * 0.75, 0), 
				
				//y axis
				new Vector3D(-x0, y0, 0), 
				new Vector3D(-x0 - x1, y0, 0), 
				new Vector3D(-x0, -y0, 0), 
				new Vector3D(-x0 - x1, -y0, 0), 
				new Vector3D(-x0 - x1 * 0.5, y0, 0), 
				new Vector3D(-x0 - x1 * 0.5, -y0, 0), 
				
				new Vector3D(-x0 - x1 * 0.5, y0, 0), 
				new Vector3D(-x0 - x1 * 0.25, y0 - x1 * 0.25 / Math.atan(15 / 180 * Math.PI), 0), 
				new Vector3D(-x0 - x1 * 0.5, y0, 0), 
				new Vector3D(-x0 - x1 * 0.75, y0 - x1 * 0.25 / Math.atan(15 / 180 * Math.PI), 0), 
				
				new Vector3D(-x0 - x1 * 0.5, -y0, 0), 
				new Vector3D(-x0 - x1 * 0.25, -y0 + x1 * 0.25 / Math.atan(15 / 180 * Math.PI), 0), 
				new Vector3D(-x0 - x1 * 0.5, -y0, 0), 
				new Vector3D(-x0 - x1 * 0.75, -y0 + x1 * 0.25 / Math.atan(15 / 180 * Math.PI), 0), 
				
				//z axis
				new Vector3D(x0, -y0, 0), 
				new Vector3D(x0 + x1, -y0, 0), 
				new Vector3D(x0, -y0, z0 * 2), 
				new Vector3D(x0 + x1, -y0, z0 * 2), 
				new Vector3D(x0 + x1 * 0.5, -y0, 0), 
				new Vector3D(x0 + x1 * 0.5, -y0, z0 * 2), 
				
				new Vector3D(x0 + x1 * 0.5, -y0, 0), 
				new Vector3D(x0 + x1 * 0.25, -y0, 0 + x1 * 0.25 / Math.atan(15 / 180 * Math.PI)), 
				new Vector3D(x0 + x1 * 0.5, -y0, 0), 
				new Vector3D(x0 + x1 * 0.75, -y0, 0 + x1 * 0.25 / Math.atan(15 / 180 * Math.PI)), 
				
				new Vector3D(x0 + x1 * 0.5, -y0, z0 * 2), 
				new Vector3D(x0 + x1 * 0.25, -y0, z0 * 2 - x1 * 0.25 / Math.atan(15 / 180 * Math.PI)), 
				new Vector3D(x0 + x1 * 0.5, -y0, z0 * 2), 
				new Vector3D(x0 + x1 * 0.75, -y0, z0 * 2 - x1 * 0.25 / Math.atan(15 / 180 * Math.PI))
			]), RULER_COLOR, 1);
			ruler.addChild(rulerWF);
			
			var tf:TextField = new TextField();
			tf.width = 128;
			tf.height = 32;
			var format:TextFormat = new TextFormat("Arial", 16, RULER_COLOR, false);
			tf.defaultTextFormat = format;
			
			tf.text = String(int(Math.round(bounding.width))) + "cm";
			var rulerXTextBMD:BitmapData = new BitmapData(64, 32, true, 0x00000000);
			rulerXTextBMD.draw(tf);
			
			tf.text = String(int(Math.round(bounding.length))) + "cm";
			var rulerYTextBMD:BitmapData = new BitmapData(64, 32, true, 0x00000000);
			rulerYTextBMD.draw(tf, null, null, null, null, true);
			
			tf.text = String(int(Math.round(bounding.height))) + "cm";
			var rulerZTextBMD:BitmapData = new BitmapData(64, 32, true, 0x00000000);
			rulerZTextBMD.draw(tf);
			
			var xtr:TextureResource = new TextureResource(rulerXTextBMD);
			var ytr:TextureResource = new TextureResource(rulerYTextBMD);
			var ztr:TextureResource = new TextureResource(rulerZTextBMD);
			xtr.upload(Jehovah.context3D);
			ytr.upload(Jehovah.context3D);
			ztr.upload(Jehovah.context3D);
			
//			var xdm:DiffuseMtl = new DiffuseMtl();
			var xdm:StdMtl = new StdMtl(0, 0, 0, 0, 0);
			xdm.diffuseMapResource = xtr;
			xdm.diffuseUVMatrix = new Matrix();
			xdm.sourceFactor = Context3DBlendFactor.SOURCE_ALPHA;
			xdm.destinationFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
			xdm.culling = "none";
			
//			var ydm:DiffuseMtl = new DiffuseMtl();
			var ydm:StdMtl = new StdMtl(0, 0, 0, 0, 0);
			ydm.diffuseMapResource = ytr;
			ydm.diffuseUVMatrix = new Matrix();
			ydm.sourceFactor = Context3DBlendFactor.SOURCE_ALPHA;
			ydm.destinationFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
			ydm.culling = "none";
			
//			var zdm:DiffuseMtl = new DiffuseMtl();
			var zdm:StdMtl = new StdMtl(0, 0, 0, 0, 0);
			zdm.diffuseMapResource = ztr;
			zdm.diffuseUVMatrix = new Matrix();
			zdm.sourceFactor = Context3DBlendFactor.SOURCE_ALPHA;
			zdm.destinationFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
			zdm.culling = "none";
			
			var px:PrimitivePlane = new PrimitivePlane(average * 0.5, average * 0.25);
			px.geometry.upload(Jehovah.context3D);
			px.mtl = xdm;
			px.y = -y0 - average * 0.25;
			px.z = 1;
			ruler.addChild(px);
			
			var py:PrimitivePlane = new PrimitivePlane(average * 0.5, average * 0.25);
			py.geometry.upload(Jehovah.context3D);
			py.mtl = ydm;
			py.rotationZ = -Math.PI * 0.5;
			py.x = -x0 - average * 0.25;
			py.z = 1;
			ruler.addChild(py);
			
			var pz:PrimitivePlane = new PrimitivePlane(average * 0.5, average * 0.25);
			pz.geometry.upload(Jehovah.context3D);
			pz.mtl = zdm;
			pz.rotationZ = -Math.PI * 0.5;
			pz.rotationY = Math.PI * 0.5;
			pz.x = x0 + average * 0.25;
			pz.y = -y0;
			pz.z = z0;
			ruler.addChild(pz);
		}
		
		
		
		
		
		
		
		
		
		private var maxRX:Number;
		private var minRX:Number;
		private var maxScale:Number;
		private var minScale:Number;
		private var bounding:Bounding;
		private var RX:Number = 0; //R: rotation
		private var RZ:Number = 0;
		private var scale:Number = 1.0;
		
		//inertia.
		private var initSpeedRX:Number;
		private var initSpeedRZ:Number;
		private var currentInertiaCount:int = 0;
		private var totalInertiaCount:int = 40;
		private var useInertia:Boolean = false;
		
		private var firstMouseDownPoint:Point = new Point();
		private var oldPoint:Point = new Point();
		private var newPoint:Point = new Point();
		
		//inertia
		private var downPoint:Point = new Point();
		private var upPoint:Point = new Point();
		private var frameTicked:int = 0;
		
		private function initBehavior():void
		{
			//初始化bounding
			bounding = new Bounding();
			bounding.maxX = bounding.maxY = bounding.maxZ = 50;
			bounding.minX = bounding.minY = bounding.minZ = -50;
			bounding.calculateDimension();
			
			resetTargetAndCamera();
			maxRX = 0;
			if(showButtom)
				minRX = -Math.PI;
			else
				minRX = -Math.PI * 0.5;
			minScale = 0.4;
			maxScale = 2.0;
			
			camera.view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			camera.view.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}
		
		/**
		 * 鼠标摁下时先检测鼠标拾取到的物体是什么，然后再决定下一步做什么
		 * @param evt
		 * 
		 */		
		private function onMouseDown_Step1(evt:MouseEvent):void
		{
//			trace(MousePickManager.target.object, MousePickManager.target.rayDetectiveObject);
			if(MousePickManager.target.object is SelectMove && selectMove.movingTarget)
			{
				var ray:Ray = Jehovah.calculateRay(new Point(evt.localX, evt.localY));
				var xoyNormal:Vector3D = selectMove.parent.localToGlobalMatrix.deltaTransformVector(Vector3D.Z_AXIS);
				var xozNormal:Vector3D = selectMove.parent.localToGlobalMatrix.deltaTransformVector(Vector3D.Y_AXIS);
				var yozNormal:Vector3D = selectMove.parent.localToGlobalMatrix.deltaTransformVector(Vector3D.X_AXIS);
				var xoyDot:Number = Math.abs(ray.dir.dotProduct(xoyNormal));
				var xozDot:Number = Math.abs(ray.dir.dotProduct(xozNormal));
				var yozDot:Number = Math.abs(ray.dir.dotProduct(yozNormal));
				
				//计算selectMove.movingPlane
				if(MousePickManager.target.rayDetectiveObject.name == SelectMove.NAME_XAXIS)
				{
					selectMove.moveDir = SelectMove.DIR_X;
					//xoy or xoz
					if(xoyDot >= xozDot)
						selectMove.movingPlane = new Plane(selectMove.position, Vector3D.Z_AXIS);
					else
						selectMove.movingPlane = new Plane(selectMove.position, Vector3D.Y_AXIS);
				}
				else if(MousePickManager.target.rayDetectiveObject.name == SelectMove.NAME_YAXIS)
				{
					selectMove.moveDir = SelectMove.DIR_Y;
					//xoy or yoz
					if(xoyDot >= yozDot)
						selectMove.movingPlane = new Plane(selectMove.position, Vector3D.Z_AXIS);
					else
						selectMove.movingPlane = new Plane(selectMove.position, Vector3D.X_AXIS);
				}
				else if(MousePickManager.target.rayDetectiveObject.name == SelectMove.NAME_ZAXIS)
				{
					selectMove.moveDir = SelectMove.DIR_Z;
					//xoz or yoz
					if(xozDot >= yozDot)
						selectMove.movingPlane = new Plane(selectMove.position, Vector3D.Y_AXIS);
					else
						selectMove.movingPlane = new Plane(selectMove.position, Vector3D.X_AXIS);
				}
//				if(selectMove.movingPlane.dir == Vector3D.X_AXIS)
//					trace("yoz");
//				else if(selectMove.movingPlane.dir == Vector3D.Y_AXIS)
//					trace("xoz");
//				else if(selectMove.movingPlane.dir == Vector3D.Z_AXIS)
//					trace("xoy");
				
				selectMove.movingPlane = selectMove.movingPlane.transform(selectMove.parent.localToGlobalMatrix);
				
				camera.view.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove_MovingSelectMoveTarget);
				camera.view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp_MovingSelectMoveTarget);
				camera.view.addEventListener(MouseEvent.MOUSE_OUT, onMouseUp_MovingSelectMoveTarget);
			}
		}
		private function onMouseDown_HandleView(evt:MouseEvent):void
		{
			if(resetMode)
				resetMode = false;
			camera.view.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			camera.view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			camera.view.addEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
			
			//on mouse down, set init inertia speed to zero.s
			initSpeedRX = 0;
			initSpeedRZ = 0;
			//on mouse down, switch off inertia.
			useInertia = false;
		}
		private function onMouseMove_MovingSelectMoveTarget(evt:MouseEvent):void
		{
			newPoint.x = evt.localX;
			newPoint.y = evt.localY;
			
			var oldRay:Ray = Jehovah.calculateRay(oldPoint);
			var newRay:Ray = Jehovah.calculateRay(newPoint);
			var i0:Object = MousePickManager.rayPlaneIntersect(oldRay, selectMove.movingPlane);
			var i1:Object = MousePickManager.rayPlaneIntersect(newRay, selectMove.movingPlane);
			if(i0 && i1)
			{
				var movement:Vector3D = selectMove.parent.globalToLocalMatrix.deltaTransformVector(i1.point.subtract(i0.point));
				if(selectMove.moveDir == SelectMove.DIR_X)
					movement.y = movement.z = 0;
				else if(selectMove.moveDir == SelectMove.DIR_Y)
					movement.x = movement.z = 0;
				else if(selectMove.moveDir == SelectMove.DIR_Z)
					movement.x = movement.y = 0;
				//更新selectMove的坐标
				selectMove.position = selectMove.position.add(movement);
				//更新selectMove.movingTarget的坐标
				movement = selectMove.parent.convertMovementToAnotherObject3D(movement, selectMove.movingTarget.parent);
				selectMove.movingTarget.position = selectMove.movingTarget.position.add(movement);
			}
			
			oldPoint.x = newPoint.x;
			oldPoint.y = newPoint.y;
		}
		private function onMouseUp_MovingSelectMoveTarget(evt:MouseEvent):void
		{
			camera.view.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove_MovingSelectMoveTarget);
			camera.view.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp_MovingSelectMoveTarget);
			camera.view.removeEventListener(MouseEvent.MOUSE_OUT, onMouseUp_MovingSelectMoveTarget);
		}
		
		private function onMouseDown(evt:MouseEvent):void
		{
			oldPoint.x = evt.localX;
			oldPoint.y = evt.localY;
			firstMouseDownPoint.x = evt.localX;
			firstMouseDownPoint.y = evt.localY;
			Jehovah.mousePick(evt);
			
			if(MousePickManager.target)
			{
				onMouseDown_Step1(evt);
				if(MousePickManager.target.object is Light3D)
				{
					selectManager.target = MousePickManager.target.object;
					selectMove.movingTarget = MousePickManager.target.object;
					selectMove.position = selectMove.parent.globalToLocalMatrix.transformVector(selectMove.movingTarget.localToGlobalMatrix.transformVector(new Vector3D()));
					selectMove.visible = true;
					dispatchEvent(new MouseEvent3D(MouseEvent3D.MOUSE_CLICK, MousePickManager.target.object, false, false));
				}
				trace(MousePickManager.target.object);
			}
			else
				onMouseDown_HandleView(evt);
			
		}
		private function onMouseMove(evt:MouseEvent):void
		{
			newPoint.x = evt.localX;
			newPoint.y = evt.localY;
			
			if(state == 0) //rotate mode
			{
				RX += (newPoint.y - oldPoint.y) / 100;
				RZ += (newPoint.x - oldPoint.x) / 100;
				initSpeedRX = (newPoint.y - oldPoint.y) / 100;
				initSpeedRZ = (newPoint.x - oldPoint.x) / 100;
			}
			else if(state == 1) //move mode
			{
				var oldRay:Ray = Jehovah.calculateRay(oldPoint);
				var newRay:Ray = Jehovah.calculateRay(newPoint);
				var plane:Plane = new jehovah3d.core.pick.Plane(new Vector3D(), new Vector3D(0, 0, 1));
				var i0:Object = MousePickManager.rayPlaneIntersect(oldRay, plane);
				var i1:Object = MousePickManager.rayPlaneIntersect(newRay, plane);
				if(i0 && i1)
				{
					var v0:Vector3D = i0.point;
					var v1:Vector3D = i1.point;
					camera.x -= (v1.x - v0.x);
					camera.y -= (v1.y - v0.y);
				}
			}
			else if(state == 2)
			{
				if(newPoint.y - oldPoint.y > 0)
					scale *= 1.03;
				else if(newPoint.y - oldPoint.y < 0)
					scale /= 1.03;
				if(scale < minScale)
					scale = minScale;
				if(scale > maxScale)
					scale = maxScale;
				camera.z = camera.calculateInitDistByTargetBounding(bounding.radius * scale, 0);
			}
			
			oldPoint.x = newPoint.x;
			oldPoint.y = newPoint.y;
		}
		
		private function onMouseUp(evt:MouseEvent):void
		{
			if(camera.view.hasEventListener(MouseEvent.MOUSE_MOVE))
				camera.view.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			if(camera.view.hasEventListener(MouseEvent.MOUSE_UP))
				camera.view.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			if(camera.view.hasEventListener(MouseEvent.MOUSE_OUT))
				camera.view.removeEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
			
			//on mouse up, switch on inertia. restart by set current inertia count to zero.
			useInertia = true;
			currentInertiaCount = 0;
			
			if(firstMouseDownPoint.x == evt.localX && firstMouseDownPoint.y == evt.localY)
			{
				selectManager.target = null;
				selectMove.movingTarget = null;
				selectMove.visible = false;
				dispatchEvent(new MouseEvent3D(MouseEvent3D.MOUSE_CLICK, null, false, false));
			}
		}
		
		private function onMouseWheel(evt:MouseEvent):void
		{
			if(evt.delta > 0)
				scale /= 1.1;
			else
				scale *= 1.1;
			if(scale < minScale)
				scale = minScale;
			if(scale > maxScale)
				scale = maxScale;
			camera.z = camera.calculateInitDistByTargetBounding(bounding.radius * scale, 0);
		}
		
		private function onKeyDown(evt:KeyboardEvent):void
		{
			if(evt.charCode == Keyboard.ESCAPE)
				resetTargetAndCamera();
			else if(evt.ctrlKey && evt.altKey && evt.charCode == 50)
				flipMip();
			else if(evt.ctrlKey && evt.altKey && evt.charCode == 52)
				onFSClick(null);
			else if(evt.ctrlKey && evt.altKey && evt.charCode == 53)
			{
				resetTargetAndCamera();
				generatePreview();
			}
			else if(evt.ctrlKey && evt.altKey && evt.charCode == 54)
				generatePreview();
			else if(evt.ctrlKey && evt.altKey && evt.charCode == 55)
				flipUseShadow();
			else if(evt.ctrlKey && evt.altKey && evt.charCode == 56)
			{
				Jehovah.useDefaultLight = !Jehovah.useDefaultLight;
				if(Jehovah.useDefaultLight)
				{
					var i:int;
					for(i = 0; i < Jehovah.lights.length; i ++)
						Jehovah.lights[i].useShadow = false;
				}
			}
		}
		
		private function flipUseShadow():void
		{
			var i:int;
			for(i = 0; i < Jehovah.lights.length; i ++)
				Jehovah.lights[i].useShadow = !Jehovah.lights[i].useShadow;
			
			//用了阴影一定不能用fixLight
			for(i = 0; i < Jehovah.lights.length; i ++)
				if(Jehovah.lights[i].useShadow)
				{
					Jehovah.useDefaultLight = false;
					break;
				}
		}
		public function flipMip():void
		{
			scene.useMip = !scene.useMip;
		}
		public function generatePreview():void
		{
			camera.drawToBitmapData = true;
			camera.render();
			var bmd:BitmapData = camera.screenShot.clone();
			camera.drawToBitmapData = false;
			var fr:FileReference = new FileReference();
			var jpg:JPGEncoder = new JPGEncoder();
			fr.save(jpg.encode(bmd), "preview.jpg");
		}
		
		public function resetTargetAndCamera():void
		{
			scale = 1;
			camera.x = camera.y = 0;
			camera.z = camera.calculateInitDistByTargetBounding(bounding.radius * scale, 0);
			camera.zFar = camera.calculateInitDistByTargetBounding(bounding.radius * maxScale, 0) + bounding.radius * 2;
			dispatchEvent(new Event(CAMERA_CHANGE, false, false));
			RX = -Math.PI / 3;
			RZ = Math.PI / 4;
			updateTarget();
		}
		private function updateTarget():void
		{
			var matrix:Matrix3D = new Matrix3D();
			matrix.appendRotation(RZ * 180 / Math.PI, Vector3D.Z_AXIS);
			matrix.appendRotation(RX * 180 / Math.PI, Vector3D.X_AXIS);
			scene.matrix = matrix;
		}
		private function zoomIn():void
		{
			
		}
		private function zoomOut():void
		{
			
		}
		
		[Embed(source="editor/assets/ui/newtitle.png", mimeType="image/png")]
		private var title_default:Class;
		
		[Embed(source="editor/assets/ui/toolbar/toolbar_bg.png", mimeType="image/png")]
		private var toolbar_bg:Class;
		
		[Embed(source="editor/assets/ui/toolbar/rotate_default.png", mimeType="image/png")]
		private var rotate_default:Class;
		
		[Embed(source="editor/assets/ui/toolbar/move_default.png", mimeType="image/png")]
		private var move_default:Class;
		
		[Embed(source="editor/assets/ui/toolbar/zoom_default.png", mimeType="image/png")]
		private var zoom_default:Class;
		
		[Embed(source="editor/assets/ui/toolbar/reset_default.png", mimeType="image/png")]
		private var reset_default:Class;
		
		[Embed(source="editor/assets/ui/toolbar/showruler_default.png", mimeType="image/png")]
		private var showruler_default:Class;
		
		[Embed(source="editor/assets/ui/toolbar/hideruler_default.png", mimeType="image/png")]
		private var hideruler_default:Class;
		
		private var logo:Sprite;
		private var toolbar:Sprite;
		private var rotate:EasyButton;
		private var moveButton:EasyButton;
		private var zoom:EasyButton;
		private var reset:EasyButton;
		private var showruler:EasyButton;
		private var hideruler:EasyButton;
		
		private var _state:uint = uint.MAX_VALUE;
		private var resetMode:Boolean = true;
		private function initUI():void
		{
			//添加logo
			logo = new Sprite();
			logo.addChild(new title_default());
			logo.addEventListener(MouseEvent.CLICK, logo_onClick);
			logo.buttonMode = true;
			addChild(logo);
			if(stage.stageWidth > 0 && stage.stageHeight > 0)
				logo.y = stage.stageHeight - logo.height;
			
			toolbar = new Sprite();
			addChild(toolbar);
			toolbar.addChild(new toolbar_bg());
			rotate = new EasyButton(new rotate_default(), "旋转");
			toolbar.addChild(rotate);
			rotate.x = 2;
			rotate.y = 1;
			moveButton = new EasyButton(new move_default(), "移动");
			toolbar.addChild(moveButton);
			moveButton.x = 2 + 49;
			moveButton.y = 1;
			zoom = new EasyButton(new zoom_default(), "缩放");
			toolbar.addChild(zoom);
			zoom.x = 2 + 49 * 2;
			zoom.y = 1;
			reset = new EasyButton(new reset_default(), "重置");
			toolbar.addChild(reset);
			reset.x = 2 + 49 * 3;
			reset.y = 1;
			
			showruler = new EasyButton(new showruler_default(), "显示尺寸");
			toolbar.addChild(showruler);
			showruler.x = 2 + 49 * 4;
			showruler.y = 1;
			hideruler = new EasyButton(new hideruler_default(), "隐藏尺寸");
			toolbar.addChild(hideruler);
			hideruler.x = 2 + 49 * 4;
			hideruler.y = 1;
			hideruler.visible = false;
			
			toolbar.x = (stage.stageWidth - toolbar.width) * 0.5;
			toolbar.y = stage.stageHeight - toolbar.height - 2;
			
			state = 0; 
			
			rotate.addEventListener(MouseEvent.CLICK, onRotateClick);
			moveButton.addEventListener(MouseEvent.CLICK, onMoveClick);
			zoom.addEventListener(MouseEvent.CLICK, onZoomClick);
			reset.addEventListener(MouseEvent.CLICK, onResetClick);
			showruler.addEventListener(MouseEvent.CLICK, onShowRulerClick);
			hideruler.addEventListener(MouseEvent.CLICK, onHideRulerClick);
			
			this.addEventListener(MouseEvent.ROLL_OUT, onToolbarMouseOut);
			this.addEventListener(MouseEvent.ROLL_OVER, onToolbarMouseOver);
		}
		private function logo_onClick(evt:MouseEvent):void
		{
			navigateToURL(new URLRequest("http://fuwu.taobao.com/ser/detail.htm?spm=a1z13.1113643.1113643.15.wCDzlW&service_code=FW_GOODS-1868472&tracelog=search&scm=&ppath=&labels="), "_blank");
		}
		private function onRotateClick(evt:MouseEvent):void
		{
			state = 0;
		}
		private function onMoveClick(evt:MouseEvent):void
		{
			state = 1;
		}
		private function onZoomClick(evt:MouseEvent):void
		{
			state = 2;
		}
		private function onZoomInClick(evt:MouseEvent):void
		{
			zoomIn();
		}
		private function onZoomOutClick(evt:MouseEvent):void
		{
			zoomOut();
		}
		private function onResetClick(evt:MouseEvent):void
		{
			resetMode = true;
			resetTargetAndCamera();
		}
		private function onShowRulerClick(evt:MouseEvent):void
		{
			if(!ruler)
				return ;
			resetTargetAndCamera();
			
			ruler.visible = true
			showruler.visible = false;
			hideruler.visible = true;
		}
		private function onHideRulerClick(evt:MouseEvent = null):void
		{
			if(!ruler)
				return ;
			ruler.visible = false;
			showruler.visible = true;
			hideruler.visible = false;
		}
		private function onFSClick(evt:MouseEvent):void
		{
			if(stage.displayState == StageDisplayState.NORMAL)
				stage.displayState = StageDisplayState.FULL_SCREEN;
		}
		private function onEFSClick(evt:MouseEvent):void
		{
			if(stage.displayState == StageDisplayState.FULL_SCREEN)
				stage.displayState = StageDisplayState.NORMAL;
		}
		
		private function onToolbarMouseOut(evt:MouseEvent):void
		{
			toolbar.removeEventListener(Event.ENTER_FRAME, fadeIn);
			toolbar.addEventListener(Event.ENTER_FRAME, fadeOut);
		}
		private function onToolbarMouseOver(evt:MouseEvent):void
		{
			toolbar.removeEventListener(Event.ENTER_FRAME, fadeOut);
			toolbar.addEventListener(Event.ENTER_FRAME, fadeIn);
		}
		
		private function fadeIn(evt:Event):void
		{
			if (toolbar.alpha > 0.8)
			{
				toolbar.alpha = 1;
				toolbar.removeEventListener(Event.ENTER_FRAME, fadeIn);
				return;
			}
			toolbar.alpha += 0.2;
		}
		private function fadeOut(evt:Event):void
		{
			if (toolbar.alpha < 0.2)
			{
				toolbar.alpha = 0;
				toolbar.removeEventListener(Event.ENTER_FRAME, fadeOut);
				return;
			}
			toolbar.alpha -= 0.2;
		}
		
		
		
		/**
		 * state of toolbar. 0: rotate mode; 1: move mode; 2: zoom mode 
		 * @return 
		 * 
		 */		
		private function get state():uint
		{
			return _state;
		}
		private function set state(val:uint):void
		{
			if(_state != val)
			{
				_state = val;
				updateToolbarFacade();
			}
		}
		
		/**
		 * update toolbar facade. 
		 * 
		 */		
		private function updateToolbarFacade():void
		{
			switch (_state)
			{
				case 0:
					rotate.state = EasyButtonState.DOWN_STATE;
					rotate.lockState = true;
					moveButton.lockState = false;
					moveButton.state = EasyButtonState.UP_STATE;
					zoom.lockState = false;
					zoom.state = EasyButtonState.UP_STATE;
					break;
				case 1:
					rotate.lockState = false;
					rotate.state = EasyButtonState.UP_STATE;
					moveButton.state = EasyButtonState.DOWN_STATE;
					moveButton.lockState = true;
					zoom.lockState = false;
					zoom.state = EasyButtonState.UP_STATE;
					break;
				case 2:
					rotate.lockState = false;
					rotate.state = EasyButtonState.UP_STATE;
					moveButton.lockState = false;
					moveButton.state = EasyButtonState.UP_STATE;
					zoom.state = EasyButtonState.DOWN_STATE;
					zoom.lockState = true;
					break;
			}
		}
	}
}