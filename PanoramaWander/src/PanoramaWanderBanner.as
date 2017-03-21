package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import panorama.Panorama;
	
	import utils.bulkloader.AdvancedLoader;
	import utils.bulkloader.BulkLoader;
	import utils.easybutton.AdvancedButton;
	import utils.easybutton.ButtonBarEvent;
	import utils.loadingbar.LoadingBar;
	
	/**
	 * 引用flashas3.preloader.Preloader
	 */	
	[Frame(factoryClass="flashas3.preloader.Preloader")]  
	
	public class PanoramaWanderBanner extends Sprite
	{
		[Embed(source="assets/scene0/design_data.txt", mimeType="application/octet-stream")]
		private var DESIGN_DATA:Class;
		
		[Embed(source="assets/scene0/bg.jpg", mimeType="image/jpeg")]
		private var TEXTURE_BG:Class;
		
		public var data:Array = [
			{
				"roomName": "d216ee2c6ceea05b17155bdd33982c32", //8959fb62fa73560a120e5bdb0bd1a329
				"texture": null, 
				"cameraPosition": new Vector3D(-293.929, -55.095, 120)//new Vector3D(380.342, 4.611, 120)
			}, 
			{
				"roomName": "441748e41fac2bbd0afb5bd8fb3389b9", 
				"texture": null, 
				"cameraPosition": new Vector3D(-480.829, 313.517, 130.192)
			}, 
			{
				"roomName": "956cf5b7cded5e1d68b05bd9d1365e25", 
				"texture": null, 
				"cameraPosition": new Vector3D(56.943, 124.716, 120)
			}, 
			{
				"roomName": "c43952b8fc043af2c5ac5bd9d13b4d5a", 
				"texture": null, 
				"cameraPosition": new Vector3D(-163.96, 362.758, 120)
			}, 
			{
				"roomName": "8959fb62fa73560a120e5bdb0bd1a329", //d216ee2c6ceea05b17155bdd33982c32
				"texture": null, 
				"cameraPosition": new Vector3D(380.342, 4.611, 120)//new Vector3D(-293.929, -55.095, 120)
			}
		];
		
		/**
		 * 设计数据
		 */		
		public var designData:String;
		
		/**
		 * 全景图no列表
		 */		
		public var panoramaNOs:Vector.<String> = new Vector.<String>();
		/**
		 * 全景图片列表
		 */		
		public var bmds:Vector.<BitmapData> = new Vector.<BitmapData>();
		/**
		 * 当前选中的全景图的索引
		 */		
		public var selectedRenderTaskIndex:int;
		/**
		 * 右上角的小地图
		 */		
		public var minimap:Minimap;
		/**
		 * 计算门上的按钮。计算起来超级烦人！
		 */		
		public var doorVisibility:DoorVisibility;
		/**
		 * 全景view
		 */		
		public var pView:Panorama; 
		
		public var loadingBar:LoadingBar;
		public var backgroundImage:Bitmap = new TEXTURE_BG();
		public var firstDisplayIndex:int = 0; //加载的第一张图片的索引
		public var two2NLoader:BulkLoader; //加载第2-n张图片的loader
		public var toGoIndex:int = -1; //加载完第2-n张图片后要跳转的房间索引
//		public var assetPathPrefix:String = "assets/scene0/";
//		public var assetPathPrefix:String = "http://3dmodel.fuwo.com/media/ifuwo/model/show/panoramawander/";
		public var assetPathPrefix:String = "";
		
		public function PanoramaWanderBanner()
		{
			this.addEventListener(Event.ADDED_TO_STAGE, onadded);  	
		}
		
		protected function onadded(event:Event):void
		{          	
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onResize);
			
			if(loaderInfo.parameters)
			{
				if(loaderInfo.parameters.resourcePath)
					assetPathPrefix = loaderInfo.parameters.resourcePath;
			}
			
			this.addChild(backgroundImage);
			this.loadingBar = new LoadingBar();
			this.addChild(loadingBar);
			onResize(null);
			
			var al:AdvancedLoader = new AdvancedLoader();
			al.addEventListener(Event.COMPLETE, onFirstComplete);
			al.addEventListener(ProgressEvent.PROGRESS, onFirstProgress);
			al.load(new URLRequest(assetPathPrefix + data[firstDisplayIndex].roomName + ".jpg"), 2);
		}   
		
		private function onResize(evt:Event):void
		{
			if(stage.stageWidth > 0 && stage.stageHeight > 0)
			{
				if(minimap)
				{
					minimap.x = stage.stageWidth - minimap.width - 10;
					minimap.y = 10;
				}
				if(pView)
				{
					pView.canvasWidth = stage.stageWidth;
					pView.canvasHeight = stage.stageHeight;
					pView.onResize(null);
				}
				if(loadingBar)
				{
					loadingBar.x = stage.stageWidth / 2;
					loadingBar.y = stage.stageHeight / 2;
				}
			}
		}
		
		private function onEnterFrame(evt:Event):void
		{
			if(pView && minimap)
			{
				minimap.eye.rotationZ = -(pView.scene.rotationY) / Math.PI * 180;
			}
			if(doorVisibility && pView)
				doorVisibility.updateButton(selectedRenderTaskIndex, pView.camera, pView.scene);
			if(pView)
				pView.render();
		}
		
		private function onFirstComplete(evt:Event):void
		{
			var al:AdvancedLoader = evt.target as AdvancedLoader;
			al.removeEventListener(Event.COMPLETE, onFirstComplete);
			al.removeEventListener(ProgressEvent.PROGRESS, onFirstProgress);
			data[firstDisplayIndex].texture = al.data.bitmapData;
			
			//删除进度条和背景图
			loadingBar.percent(1,2);
			this.removeChild(loadingBar);
			loadingBar = null;
			this.removeChild(backgroundImage);
			backgroundImage = null;
			
			init();
			
			this.two2NLoader = new BulkLoader();
			for (var i:int = 1; i < data.length; i ++)
			{
				two2NLoader.add(assetPathPrefix + data[i].roomName + ".jpg");
			}
			two2NLoader.addEventListener(Event.COMPLETE, onTwo2NComplete);
			two2NLoader.addEventListener(ProgressEvent.PROGRESS, onTwo2NProgress);
			two2NLoader.load();
		}
		private function onFirstProgress(evt:ProgressEvent):void
		{
			loadingBar.percent(evt.bytesLoaded / evt.bytesTotal,2);
		}
		private function onTwo2NComplete(evt:Event):void
		{
			two2NLoader.removeEventListener(Event.COMPLETE, onTwo2NComplete);
			two2NLoader.removeEventListener(ProgressEvent.PROGRESS, onTwo2NProgress);
			var tasks:Dictionary = two2NLoader.tasks;
			for(var key:String in tasks)
			{
				for (var i:int = 1; i < data.length; i ++)
				{
					if (key.indexOf(data[i].roomName) != -1)
					{
						data[i].texture = tasks[key].data.bitmapData;
						break;
					}
				}
			}
			for (i = 0; i < data.length; i ++)
			{
				if (data[i].texture != null)
					bmds[i] = handleBoxPanoramaBitmapData(data[i].texture as BitmapData, 1000, 2);
			}
			two2NLoader = null;
			if (loadingBar)
			{
				loadingBar.percent(1,2);
				this.removeChild(loadingBar);
				loadingBar = null;
			}
			
			if (toGoIndex != -1)
				setRenderTaskIndex(toGoIndex);
		}
		
		private function onTwo2NProgress(evt:ProgressEvent):void
		{
			if (loadingBar)
			{
				loadingBar.percent(evt.bytesLoaded / evt.bytesTotal,2);
			}		
		}
		
		public function init():void
		{
			var i:int;
			var j:int;
			
			//设计数据
			var bt:ByteArray = new DESIGN_DATA() as ByteArray;
			bt.position = 0;
			designData = bt.readUTFBytes(bt.length);
			
			//全景图片
			for (i = 0; i < data.length; i ++)
			{
				if (data[i].texture != null)
					bmds[i] = handleBoxPanoramaBitmapData(data[i].texture as BitmapData, 1000, 2);
			}
			
			//check door visibility
			
			doorVisibility = new DoorVisibility(JSON.parse(designData), data);
			for(i = 0; i < doorVisibility.visibleDoors.length; i ++)
				for(j = 0; j < doorVisibility.visibleDoors[i].length; j ++)
				{
					if(doorVisibility.visibleDoors[i][j].behindDoorRoomName)
					{
						addChild(doorVisibility.visibleDoors[i][j].button);
						doorVisibility.visibleDoors[i][j].button.visible = false;
						AdvancedButton(doorVisibility.visibleDoors[i][j].button).addEventListener(MouseEvent.CLICK, onEnterButtonClick);
					}
				}
			
			
			
			//添加minimap		
			minimap = new Minimap(JSON.parse(designData), 170, 170);
			addChild(minimap);
			onResize(null);
			minimap.bb.addEventListener(ButtonBarEvent.BUTTON_CLICK, updatePanorama);
			
			//添加pView 
			pView = new Panorama(false);
			addChildAt(pView, 0);
			onResize(null);
			setRenderTaskIndex(firstDisplayIndex);
			for(i = 0; i < minimap.bb.buttons.length; i ++)
				if(minimap.bb.buttons[i].additionalData.roomName == data[0].roomName)
				{
					minimap.bb.state = i;
					break;
				}
			pView.addEventListener(Panorama.FOV_CHANGE, onFovChange);
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			onEnterFrame(null);
		}
		
		private function onEnterButtonClick(evt:MouseEvent):void
		{
			if (two2NLoader)
				return ;
			var i:int;
			for(i = 0; i < data.length;i ++)
				if(data[i].roomName == AdvancedButton(evt.target).additionalData.behindDoorRoomName)
				{
					setRenderTaskIndex(i);
					break;
				}
			for(i = 0; i < minimap.bb.buttons.length; i ++)
				if(minimap.bb.buttons[i].additionalData.roomName == AdvancedButton(evt.target).additionalData.behindDoorRoomName)
				{
					minimap.bb.state = i;
					break;
				}
		}
		
		private function updatePanorama(evt:ButtonBarEvent):void
		{
			var i:int;
			for(i = 0; i < data.length; i ++)
				
				if(data[i].roomName == evt.target.buttons[evt.buttonIndex].additionalData.roomName)
				{
					if (data[i].texture == null)
					{
						toGoIndex = i;
						if (loadingBar == null)
						{
							loadingBar = new LoadingBar();
							addChild(loadingBar);
							loadingBar.mouseEnabled = false;
							onResize(null);
						}
					}
					else
					{
						setRenderTaskIndex(i);
					}
					break;
				}
		}
		
		private function getPanoramaNOByRoomName(roomName:String):String
		{
			var i:int;
			for(i = 0; i < panoramaNOs.length; i ++)
				if(data[i].roomName == roomName)
					return panoramaNOs[i];
			return null;
		}
		
		private function setRenderTaskIndex(index:int):void
		{
			selectedRenderTaskIndex = index;
			pView.bmd = bmds[selectedRenderTaskIndex];
			minimap.setEyePosition({"x": data[selectedRenderTaskIndex].cameraPosition.x, "y": data[selectedRenderTaskIndex].cameraPosition.y});
			pView.flvDisplay(index);
		}
		
		private function onFovChange(evt:Event):void
		{
			if(minimap)
				minimap.updateFov(pView.camera.fov);
		}
		
		private function handleBoxPanoramaBitmapData(source:BitmapData, size:int, expand:int):BitmapData
		{
			size = source.width / 3;
			var ret:BitmapData = new BitmapData(source.width + expand * 2, source.height, source.transparent);
			ret.copyPixels(source, new Rectangle(0, 0, source.width, source.height), new Point(expand, 0)); //第1次拷贝，大区域。
			
			var t0:BitmapData = new BitmapData(expand, size + expand, false);
			t0.copyPixels(source, new Rectangle(size - expand, size * 3 - expand, t0.width, t0.height), new Point());
			var t1:BitmapData = rotateBitmapDataByPI(t0);
			ret.copyPixels(t1, new Rectangle(0, 0, t1.width, t1.height), new Point(0, size)); //第2次拷贝，左侧的细长条。
			
			var t2:BitmapData = new BitmapData(expand, size + expand, false);
			t2.copyPixels(source, new Rectangle(size * 2, size * 3 - expand, t2.width, t2.height), new Point());
			var t3:BitmapData = rotateBitmapDataByPI(t2);
			ret.copyPixels(t3, new Rectangle(0, 0, t3.width, t3.height), new Point(size * 3 + expand, size)); //第3次拷贝，右侧的细长条。
			
			return ret;
		}
		private function rotateBitmapDataByPI(source:BitmapData):BitmapData
		{
			var ret:BitmapData = new BitmapData(source.width, source.height, source.transparent);
			var matrix:Matrix = new Matrix();
			matrix.scale(-1, -1);
			matrix.translate(source.width, source.height);
			ret.draw(source, matrix);
			return ret;
		}
	}
}
