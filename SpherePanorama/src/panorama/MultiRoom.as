package panorama
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import utils.easybutton.AdvancedButton;
	import utils.easybutton.ButtonBar;
	import utils.easybutton.ButtonBarEvent;
	import utils.easybutton.EasyButton;

	public class MultiRoom extends Sprite
	{
//		door: (554, 1070)
//		anchor: [(2552, 840), (1208, 972)]		
//		
//		door: (1236, 978)
//		anchor: [(2008, 788)]
		
		//embed贴图
		[Embed(source="/panorama/assets/multiroom/001.jpg", mimeType="image/jpeg")]
		private var TEXTURE0:Class;
		[Embed(source="/panorama/assets/multiroom/002.jpg", mimeType="image/jpeg")]
		private var TEXTURE1:Class;
		//房间缩略图
		[Embed(source="/panorama/assets/multiroom/space0.jpg", mimeType="image/jpeg")]
		private var SPACE0:Class;
		[Embed(source="/panorama/assets/multiroom/space1.jpg", mimeType="image/jpeg")]
		private var SPACE1:Class;
		//UI图标-门的icon
		[Embed(source="/panorama/assets/multiroom/door.png", mimeType="image/png")]
		private var door_default:Class;
		//UI图标-墙纸的购买icon
		[Embed(source="/panorama/assets/multiroom/link.png", mimeType="image/png")]
		private var link_default:Class;
		//check图标
		[Embed(source="/panorama/assets/multiroom/check.png", mimeType="image/png")]
		private var check_default:Class;
		
		//场景中的按钮，有门的，有购买按钮的。
		private var spaceData:Array = [
			//第一张图
			{
				"bmd": new TEXTURE0().bitmapData, 
				"buttons": [
					{
						"button": new EasyButton(new door_default(), new door_default(), new door_default()), 
						"clickFunc": gotoSecondRoom, 
						"position": new Point(554.0 / 4000, 1070.0 / 2000)
					}, 
					{
						"button": new EasyButton(new link_default(), new link_default(), new link_default()), 
						"clickFunc": onLinkClick, 
						"position": new Point(1496.0 / 4000, 1132.0 / 2000), 
						"linkURL": "http://detail.tmall.com/item.htm?id=38035471968"
					}, 
					{
						"button": new EasyButton(new link_default(), new link_default(), new link_default()), 
						"clickFunc": onLinkClick, 
						"position": new Point(2748.0 / 4000, 1116.0 / 2000), 
						"linkURL": "http://detail.tmall.com/item.htm?id=19813350301"
					}
				]
			}, 
			
			//第二张图
			{
				"bmd": new TEXTURE1().bitmapData, 
				"buttons": [
					{
						"button": new EasyButton(new door_default(), new door_default(), new door_default()), 
						"clickFunc": gotoFirstRoom, 
						"position": new Point(1236.0 / 4000, 978.0 / 2000)
					}, 
					{
						"button": new EasyButton(new link_default(), new link_default(), new link_default()), 
						"clickFunc": onLinkClick, 
						"position": new Point(2304.0 / 4000, 992.0 / 2000), 
						"linkURL": "http://detail.tmall.com/item.htm?id=19222660612"
					}, 
					{
						"button": new EasyButton(new link_default(), new link_default(), new link_default()), 
						"clickFunc": onLinkClick, 
						"position": new Point(0.0 / 4000, 988.0 / 2000), 
						"linkURL": "http://detail.tmall.com/item.htm?id=17927810280"
					}
				]
			}
		];
		
		//房间按钮
		private var roomButtonBar:ButtonBar;
		
		/**
		 * 构造函数
		 * 
		 */		
		public function MultiRoom()
		{
			//计算button的球体坐标，3D坐标系
			var i:int;
			var j:int;
			for (i = 0; i < spaceData.length; i ++)
			{
				var buttons:Array = spaceData[i].buttons;
				for (j = 0; j < buttons.length; j ++)
				{
					//计算visible
					var btn:EasyButton = buttons[j].button;
					var p0:Point = buttons[j].position as Point;
					var alpha:Number = Math.PI / 2 - p0.x * Math.PI * 2;
					var beta:Number = Math.asin((0.5 - p0.y) * 2);
					buttons[j].position = new Vector3D(Math.cos(beta) * Math.cos(alpha), Math.cos(beta) * Math.sin(alpha), Math.sin(beta));
					btn.visible = false;
					
					addChild(btn);
					btn.addEventListener(MouseEvent.CLICK, buttons[j].clickFunc as Function);
				}
			}
			
			//初始化房间按钮
			roomButtonBar = new ButtonBar();
			
			var dft:Bitmap;
			var over:Sprite;
			var down:Sprite;
			
			dft = new SPACE0() as Bitmap;
			over = new Sprite();
			over.graphics.lineStyle(10, 0xFFFFFF, 1);
			over.graphics.drawRoundRectComplex(0, 0, dft.width, dft.height, 2, 2, 2, 2);
			over.addChild(new SPACE0());
			down = new Sprite();
			down.graphics.lineStyle(10, 0xFFFFFF, 1);
			down.graphics.drawRoundRectComplex(0, 0, dft.width, dft.height, 2, 2, 2, 2);
			down.addChild(new SPACE0());
			var check0:Bitmap = new check_default() as Bitmap;
			down.addChild(check0);
			check0.x = (dft.width - check0.width) / 2;
			check0.y = (dft.height - check0.height) / 2;
			var b0:AdvancedButton = new AdvancedButton(dft, over, down);
			
			dft = new SPACE1() as Bitmap;
			over = new Sprite();
			over.graphics.lineStyle(10, 0xFFFFFF, 1);
			over.graphics.drawRoundRectComplex(0, 0, dft.width, dft.height, 2, 2, 2, 2);
			over.addChild(new SPACE1());
			down = new Sprite();
			down.graphics.lineStyle(10, 0xFFFFFF, 1);
			down.graphics.drawRoundRectComplex(0, 0, dft.width, dft.height, 2, 2, 2, 2);
			down.addChild(new SPACE1());
			var check1:Bitmap = new check_default() as Bitmap;
			down.addChild(check1);
			check1.x = (dft.width - check1.width) / 2;
			check1.y = (dft.height - check1.height) / 2;
			var b1:AdvancedButton = new AdvancedButton(dft, over, down);
			
			roomButtonBar.add(b0);
			roomButtonBar.add(b1);
			var padding:Number = 10;
			b0.x = padding;
			b0.y = padding;
			b1.x = padding;
			b1.y = padding * 2 + dft.height;
			roomButtonBar.graphics.beginFill(0x333333, 0.8);
			roomButtonBar.graphics.drawRect(0, 0, dft.width + padding * 2, dft.height * 2 + padding * 3);
			roomButtonBar.graphics.endFill();
			
			roomButtonBar.addEventListener(ButtonBarEvent.BUTTON_CLICK, onRoomButtonBarClick);
			addChild(roomButtonBar);
			roomButtonBar.state = 0;
		}
		
		/**
		 * 更新buttons的坐标、可视状态。外度调用，每帧执行一次
		 * @param sceneMatrix
		 * @param viewWidth
		 * @param viewHeight
		 * @param fov
		 * 
		 */		
		public function updateButtons(sceneMatrix:Matrix3D, viewWidth:Number, viewHeight:Number, fov:Number, bmd:BitmapData):void
		{
			var i:int;
			var j:int;
			//计算buttons的visible
			for (i = 0; i < spaceData.length; i ++)
			{
				var buttons:Array = spaceData[i].buttons;
				for (j = 0; j < buttons.length; j ++)
				{
					var btn:EasyButton = buttons[j].button;
					if (spaceData[i].bmd != bmd)
					{
						btn.visible = false;
						continue;
					}
					var p0:Point = calculateProjection(buttons[j].position, sceneMatrix, viewWidth, viewHeight, fov);
					btn.visible = (p0 != null);
					if (btn.visible)
					{
						btn.x = p0.x - btn.width / 2;
						btn.y = p0.y - btn.height / 2;
					}
				}
			}
		}
		
		/**
		 * 更新房间按钮的坐标，onResize触发执行。
		 * @param stageWidth
		 * @param stageHeight
		 * 
		 */		
		public function updateRoomButtonBar(stageWidth:int, stageHeight:int):void
		{
			if (stageWidth > 0 && stageHeight > 0)
			{
				roomButtonBar.x = stageWidth - roomButtonBar.width;
				roomButtonBar.y = 0;
			}
		}
		
		/**
		 * get bmd0
		 * @return 
		 * 
		 */		
		public function getFirstBMD():BitmapData
		{
			return spaceData[0].bmd as BitmapData;
		}
		
		/**
		 * 房间按钮点击事件
		 * @param evt
		 * 
		 */		
		private function onRoomButtonBarClick(evt:ButtonBarEvent):void
		{
			if (evt.buttonIndex == 0)
				gotoFirstRoom(null);
			else if (evt.buttonIndex == 1)
				gotoSecondRoom(null);
		}
		
		/**
		 * 使用第一张贴图
		 * @param evt
		 * 
		 */		
		private function gotoFirstRoom(evt:MouseEvent):void
		{
			var p:EmbedResourceSpherePanorama3DShowPlayLoadingMultiRoom = this.parent as EmbedResourceSpherePanorama3DShowPlayLoadingMultiRoom;
			p.setBMD(spaceData[0].bmd as BitmapData);
			roomButtonBar.state = 0;
		}
		
		/**
		 * 使用第二张贴图
		 * @param evt
		 * 
		 */		
		private function gotoSecondRoom(evt:MouseEvent):void
		{
			var p:EmbedResourceSpherePanorama3DShowPlayLoadingMultiRoom = this.parent as EmbedResourceSpherePanorama3DShowPlayLoadingMultiRoom;
			p.setBMD(spaceData[1].bmd as BitmapData);
			roomButtonBar.state = 1;
		}
		
		/**
		 * 链接跳转
		 * @param evt
		 * 
		 */		
		private function onLinkClick(evt:MouseEvent):void
		{
			var i:int;
			var j:int;
			//计算buttons的visible
			for (i = 0; i < spaceData.length; i ++)
			{
				var buttons:Array = spaceData[i].buttons;
				for (j = 0; j < buttons.length; j ++)
				{
					var btn:EasyButton = buttons[j].button;
					if (btn == evt.target)
					{
						if (buttons[j].hasOwnProperty("linkURL"))
						{
							navigateToURL(new URLRequest(buttons[j].linkURL), "_blank");
							break;
						}
					}
				}
			}
//			trace(evt.target);
//			navigateToURL(new URLRequest("http://item.taobao.com/item.htm?spm=686.1000925.1000774.60.2yCZlS&id=37926295771&qq-pf-to=pcqq.c2c"), "_blank");
		}
		
		/**
		 * 计算锚点坐标
		 * @param position
		 * @param sceneMatrix
		 * @param viewWidth
		 * @param viewHeight
		 * @param fov
		 * @return 
		 * 
		 */		
		public function calculateProjection(position:Vector3D, sceneMatrix:Matrix3D, viewWidth:Number, viewHeight:Number, fov:Number):Point
		{
			var ret:Point = new Point();
			var v0:Vector3D = sceneMatrix.transformVector(position);
//			trace(boxPosition.x, boxPosition.y, boxPosition.z);
//			trace(v0.x, v0.y, v0.z);
			if(v0.y <= 0)
				return null;
			ret.x = v0.x / v0.y;
			ret.y = v0.z / v0.y;
			ret.x /= Math.tan(fov / 2);
			ret.y /= (Math.tan(fov / 2) / viewWidth * viewHeight);
			if(Math.abs(ret.x) > 1 || Math.abs(ret.y) > 1)
				return null;
//			trace(ret.x, ret.y);
			
			ret.x = ret.x * 0.5 + 0.5;
			ret.y = 0.5 - ret.y * 0.5;
			ret.x *= viewWidth;
			ret.y *= viewHeight;
			return ret;
		}
	}
}