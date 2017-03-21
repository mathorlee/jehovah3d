package
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import panorama.Panorama;
	
	import utils.bulkloader.AdvancedLoader;
	import utils.bulkloader.BulkLoader;
	import utils.easybutton.AdvancedButton;
	import utils.easybutton.ButtonBarEvent;
	
	public class PanoramaWander extends Sprite
	{
		/**
		 * 设计no
		 */		
		public var designNO:String;
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
		 * 相机位置列表
		 */		
		public var cameraInfos:Vector.<Object> = new Vector.<Object>();
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
		
		public static const DESIGN_DETAIL:String = "http://www.fuwo.com/ifuwo/design/detail/?no=";
		public static const ORIGIN:String = "http://www.fuwo.com/upload/ifuwo/render/client/render_photo/";
		
		public function PanoramaWander()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onResize);
			init();
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_OVER, onStageMouseOver);
			stage.addEventListener(MouseEvent.MOUSE_OUT, onStageMouseOut);
		}
		private function onStageMouseOver(evt:MouseEvent):void
		{
			if(pView)
				pView.autoRotate = false;
		}
		private function onStageMouseOut(evt:MouseEvent):void
		{
			if(pView)
				pView.autoRotate = true;
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
				minimap.eye.rotationZ = -(pView.scene.rotationY - Math.PI * 0.75) / Math.PI * 180;
			}
			if(doorVisibility && pView)
				doorVisibility.updateButton(selectedRenderTaskIndex, pView.camera, pView.scene);
			if(pView)
				pView.render();
		}
		
		public function init():void
		{
			designNO = "7848B36C2ED8C6E974237BB2DD89FF52";
			designData = "";
			panoramaNOs.push(
				"49b74dde737f11e3ba3c00163e000ee8", 
				"446080ee737f11e3a82800163e000ee8", 
				"3f6f93f4737f11e3ba3c00163e000ee8", 
				"39d74b80737f11e3ba3c00163e000ee8", 
				"c114830e744411e3ba8400163e000ee8"
			);
			bmds.length = panoramaNOs.length;
			cameraInfos.push(
				JSON.parse("{\"imageLength\":2048,\"x\":117.85,\"cameraType\":4,\"imageWidth\":1536,\"rotationX\":90,\"z\":140,\"serviceType\":2,\"fov\":6.283185307179586,\"y\":361.8,\"roomName\":\"0F49862AA8157F1FFF9C5784D0845401\",\"rotationZ\":45}"), 
				JSON.parse("{\"imageLength\":2048,\"x\":257.8,\"cameraType\":4,\"imageWidth\":1536,\"rotationX\":90,\"z\":140,\"serviceType\":2,\"fov\":6.283185307179586,\"y\":-27.15,\"roomName\":\"9FEEF69B25539DA547ED5785C84F91AC\",\"rotationZ\":45}"), 
				JSON.parse("{\"imageLength\":2048,\"x\":-43.3,\"cameraType\":4,\"imageWidth\":1536,\"rotationX\":90,\"z\":140,\"serviceType\":2,\"fov\":6.283185307179586,\"y\":-98.8,\"roomName\":\"D0606A94A7A05E48C6385786E62FA9FD\",\"rotationZ\":45}"), 
				JSON.parse("{\"imageLength\":2048,\"x\":-228.35,\"cameraType\":4,\"imageWidth\":1536,\"rotationX\":90,\"z\":140,\"serviceType\":2,\"fov\":6.283185307179586,\"y\":199.95,\"roomName\":\"12C4F023342E5D8F13D15780535E38D5\",\"rotationZ\":45}"), 
				JSON.parse("{\"roomName\":\"26CDF72C7AF445D18EC657873B39E7FE\",\"x\":-230.15,\"imageLength\":2048,\"y\":-317.6,\"rotationX\":90,\"serviceType\":2,\"z\":140,\"fov\":6.283185307179586,\"cameraType\":4,\"rotationZ\":45,\"imageWidth\":1536}")
			);
			
			var loader:AdvancedLoader = new AdvancedLoader();
			var recordRequest:URLRequest = new URLRequest(DESIGN_DETAIL + designNO);
			recordRequest.method = URLRequestMethod.GET;
			loader.addEventListener(Event.COMPLETE, onComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.load(recordRequest, 2);
		}
		
		private function onComplete(evt:Event):void
		{
			designData = evt.target.data;
			minimap = new Minimap(JSON.parse(JSON.parse(designData).data.data));
			addChild(minimap);
			onResize(null);
			minimap.bb.addEventListener(ButtonBarEvent.BUTTON_CLICK, updatePanorama);
			
			//doorVisibility = new DoorVisibility(JSON.parse(JSON.parse(designData).data.data), cameraInfos);
			var i:int;
			var j:int;
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
			
			var loader:BulkLoader = new BulkLoader();
			for(i = 0; i < panoramaNOs.length; i ++)
				loader.add(ORIGIN + panoramaNOs[i] + "/origin.jpg");
			loader.addEventListener(Event.COMPLETE, onOriginsComplete);
			loader.load();
		}
		
		private function onEnterButtonClick(evt:MouseEvent):void
		{
//			trace(AdvancedButton(evt.target).additionalData.behindDoorRoomName);
			
			var i:int;
			for(i = 0; i < cameraInfos.length;i ++)
				if(cameraInfos[i].roomName == AdvancedButton(evt.target).additionalData.behindDoorRoomName)
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
		private function onIOError(evt:IOErrorEvent):void
		{
			
		}
		private function updatePanorama(evt:ButtonBarEvent):void
		{
//			trace("选中的按钮编号: " + evt.buttonIndex);
//			trace("选中的房间: " + evt.target.buttons[evt.buttonIndex].additionalData.roomName);
//			trace("选中的渲染任务: " + getPanoramaNOByRoomName(evt.target.buttons[evt.buttonIndex].additionalData.roomName));
//			trace();
			var i:int;
			for(i = 0; i < cameraInfos.length; i ++)
				if(cameraInfos[i].roomName == evt.target.buttons[evt.buttonIndex].additionalData.roomName)
				{
					setRenderTaskIndex(i);
					break;
				}
		}
		
		private function getPanoramaNOByRoomName(roomName:String):String
		{
			var i:int;
			for(i = 0; i < panoramaNOs.length; i ++)
				if(cameraInfos[i].roomName == roomName)
					return panoramaNOs[i];
			return null;
		}
		
		private function setRenderTaskIndex(index:int):void
		{
			selectedRenderTaskIndex = index;
			pView.bmd = bmds[selectedRenderTaskIndex];
			minimap.setEyePosition({"x": cameraInfos[selectedRenderTaskIndex].x, "y": cameraInfos[selectedRenderTaskIndex].y});
		}
		private function onOriginsComplete(evt:Event):void
		{
			var loader:BulkLoader = evt.target as BulkLoader;
			var key:String;
			var i:int;
			for(key in loader.tasks)
			{
				if(loader.tasks[key].state == BulkLoader.STATE_SUCCESS)
				{
					for(i = 0; i < panoramaNOs.length; i ++)
						if(key.indexOf(panoramaNOs[i]) != -1)
						{
							bmds[i] = handleBoxPanoramaBitmapData(loader.tasks[key].data.bitmapData, 512, 2);
							break;
						}
				}
			}
			
			//添加pView
			pView = new Panorama();
			addChildAt(pView, 0);
			onResize(null);
//			setSelectedRoom(cameraInfos[0].roomName);
			setRenderTaskIndex(0);
			for(i = 0; i < minimap.bb.buttons.length; i ++)
				if(minimap.bb.buttons[i].additionalData.roomName == cameraInfos[0].roomName)
				{
					minimap.bb.state = i;
					break;
				}
		}
		
		private function handleBoxPanoramaBitmapData(source:BitmapData, size:int, expand:int):BitmapData
		{
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