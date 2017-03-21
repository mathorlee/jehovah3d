package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	
	import panorama.Panorama;
	
	import utils.easybutton.AdvancedButton;
	import utils.easybutton.ButtonBarEvent;
	
	public class PanoramaWanderLocalAsset extends Sprite
	{
		[Embed(source="assets/scene0/design_data.txt", mimeType="application/octet-stream")]
		private var DESIGN_DATA:Class;
		
		[Embed(source="assets/scene0/8959fb62fa73560a120e5bdb0bd1a329.jpg", mimeType="image/jpeg")]
		private var TEXTURE0:Class;
		
		[Embed(source="assets/scene0/441748e41fac2bbd0afb5bd8fb3389b9.jpg", mimeType="image/jpeg")]
		private var TEXTURE1:Class;
		
		[Embed(source="assets/scene0/956cf5b7cded5e1d68b05bd9d1365e25.jpg", mimeType="image/jpeg")]
		private var TEXTURE2:Class;
		
		[Embed(source="assets/scene0/c43952b8fc043af2c5ac5bd9d13b4d5a.jpg", mimeType="image/jpeg")]
		private var TEXTURE3:Class;
		
		[Embed(source="assets/scene0/d216ee2c6ceea05b17155bdd33982c32.jpg", mimeType="image/jpeg")]
		private var TEXTURE4:Class;
		
		public var data:Array = [
			{
				"roomName": "8959fb62fa73560a120e5bdb0bd1a329", 
				"texture": new TEXTURE0().bitmapData, 
				"cameraPosition": new Vector3D(380.342, 4.611, 120)
			}, 
			{
				"roomName": "441748e41fac2bbd0afb5bd8fb3389b9", 
				"texture": new TEXTURE1().bitmapData, 
				"cameraPosition": new Vector3D(-480.829, 313.517, 130.192)
			}, 
			{
				"roomName": "956cf5b7cded5e1d68b05bd9d1365e25", 
				"texture": new TEXTURE2().bitmapData, 
				"cameraPosition": new Vector3D(56.943, 124.716, 120)
			}, 
			{
				"roomName": "c43952b8fc043af2c5ac5bd9d13b4d5a", 
				"texture": new TEXTURE3().bitmapData, 
				"cameraPosition": new Vector3D(-163.96, 362.758, 120)
			}, 
			{
				"roomName": "d216ee2c6ceea05b17155bdd33982c32", 
				"texture": new TEXTURE4().bitmapData, 
				"cameraPosition": new Vector3D(-293.929, -55.095, 120)
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
		
		public function PanoramaWanderLocalAsset()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onResize);
			
			init();
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function onResize(evt:Event):void
		{
			if(stage.stageWidth > 0 && stage.stageHeight > 0)
			{
				if(minimap)
				{
					minimap.x = stage.stageWidth - minimap.width;
					minimap.y = 0;
				}
				if(pView)
				{
					pView.canvasWidth = stage.stageWidth;
					pView.canvasHeight = stage.stageHeight;
					pView.onResize(null);
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
			minimap = new Minimap(JSON.parse(designData));
			addChild(minimap);
			onResize(null);
			minimap.bb.addEventListener(ButtonBarEvent.BUTTON_CLICK, updatePanorama);
			
			//添加pView
			pView = new Panorama();
			addChildAt(pView, 0);
			onResize(null);
			setRenderTaskIndex(0);
			for(i = 0; i < minimap.bb.buttons.length; i ++)
				if(minimap.bb.buttons[i].additionalData.roomName == data[0].roomName)
				{
					minimap.bb.state = i;
					break;
				}
			pView.addEventListener(Panorama.FOV_CHANGE, onFovChange);
		}
		
		private function onEnterButtonClick(evt:MouseEvent):void
		{
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
					setRenderTaskIndex(i);
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
