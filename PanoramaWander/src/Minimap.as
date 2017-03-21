package
{
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Sprite;
	
	import utils.easybutton.AdvancedButton;
	import utils.easybutton.ButtonBar;
	
	public class Minimap extends Sprite
	{
		[Embed(source="/assets/eye.png", mimeType="image/png")]
		private static var EYE:Class;
		
		//design data
		private var points:Array = [];
		private var walls:Array = [];
		private var rooms:Array = [];
		private var openings:Array = [];
		
		private var _mapWidth:Number; //minimap的宽度
		private var _mapHeight:Number; //minimap的高度
		
		private var minX:Number = Number.MAX_VALUE;
		private var maxX:Number = -Number.MAX_VALUE;
		private var minY:Number = Number.MAX_VALUE;
		private var maxY:Number = -Number.MAX_VALUE;
		private var w0:Number; //场景的宽度
		private var h0:Number; //场景的高度
		
		/**
		 * 小房间是一个组合button，只有一个button出于down状态。
		 */		
		public var bb:ButtonBar;
		
		public var eye:Sprite;
		
		public function Minimap(data:Object, mapWidth:Number = 160, mapHeight:Number = 160)
		{
			_mapWidth = mapWidth;
			_mapHeight = mapHeight;
			graphics.beginFill(0x333333, 0.7);
			graphics.drawRect(0, 0, _mapWidth, _mapHeight);
			graphics.endFill();
			
			points = data.points;
			walls = data.walls;
			rooms = data.rooms;
			openings = data.openings;
			
			draw();
			addEye();
		}
		
		private function draw():void
		{
			var i:int;
			var j:int;
			if(points.length == 0 || walls.length == 0 || rooms.length == 0)
				return ;
			
			for(i = 0; i < walls.length; i ++)
			{
				minX = Math.min(points[walls[i].startPointIndex].x, points[walls[i].stopPointIndex].x, minX);
				maxX = Math.max(points[walls[i].startPointIndex].x, points[walls[i].stopPointIndex].x, maxX);
				minY = Math.min(points[walls[i].startPointIndex].y, points[walls[i].stopPointIndex].y, minY);
				maxY = Math.max(points[walls[i].startPointIndex].y, points[walls[i].stopPointIndex].y, maxY);
			}
			minX -= 50;
			minY -= 50;
			maxX += 50;
			maxY += 50;
			w0 = maxX - minX;
			h0 = maxY - minY;
			var tmp:Number;
			if(w0 / _mapWidth > h0 / _mapHeight)
			{
				tmp = w0 / _mapWidth * _mapHeight - h0;
				minY -= tmp / 2;
				maxY += tmp / 2;
				h0 += tmp;
			}
			else
			{
				tmp = h0 / _mapHeight * _mapWidth - w0;
				minX -= tmp / 2;
				maxX += tmp / 2;
				w0 += tmp;
			}
			
			//draw room wall
			bb = new ButtonBar();
			for(i = 0; i < rooms.length; i ++)
			{
				var ab:AdvancedButton = drawRoom(rooms[i]);
				ab.additionalData = {"roomName": rooms[i].name};
				bb.add(ab);
			}
			addChild(bb);
			
			//draw divide wall
			
			//draw opening
			
		}
		
		private function addEye():void
		{
			eye = new Sprite();
			var bm:Bitmap = new EYE() as Bitmap;
			bm.x = -11;
			bm.y = -8;
			eye.addChild(bm);
			
			eye.graphics.lineStyle(0.5, 0);
			eye.graphics.moveTo(12, -12);
			eye.graphics.lineTo(0, 0);
			eye.graphics.lineTo(-12, -12);
			
			addChild(eye);
			eye.x = this.width / 2;
			eye.y = this.height / 2;
			eye.visible = false;
			eye.mouseEnabled = false;
		}
		public function updateFov(fov:Number):void
		{
			if(eye)
			{
				eye.graphics.clear();
				eye.graphics.lineStyle(0.5, 0);
				var sin:Number = 12 * Math.SQRT2 * Math.sin(fov / 2);
				var cos:Number = 12 * Math.SQRT2 * Math.cos(fov / 2);
				eye.graphics.moveTo(sin, -cos);
				eye.graphics.lineTo(0, 0);
				eye.graphics.lineTo(-sin, -cos);
			}
		}
		/**
		 * draw room as an AdvancedButton
		 * @param room
		 * @return 
		 * 
		 */		
		private function drawRoom(room:Object):AdvancedButton
		{
			var up:Shape = new Shape();
			var over:Shape = new Shape();
			var down:Shape = new Shape();
			var pointIndexs:Array = room.pointIndexs;
			var i:int;
			var p0:Object;
			var p1:Object;
			
			up.graphics.lineStyle(2, 0xC4C4C4, 1);
			over.graphics.lineStyle(2, 0xC4C4C4, 1);
			down.graphics.lineStyle(2, 0xEEEEEE, 1);
			up.graphics.beginFill(0xFFFFFF, 0.3);
			over.graphics.beginFill(0xCCCCCC, 0.3);
			down.graphics.beginFill(0x999999, 0.3);
			
			p0 = mappingPoint(points[pointIndexs[0]]);
			up.graphics.moveTo(p0.x, p0.y);
			over.graphics.moveTo(p0.x, p0.y);
			down.graphics.moveTo(p0.x, p0.y);
			
			for(i = 1; i < pointIndexs.length;i ++)
			{
				p1 = mappingPoint(points[pointIndexs[i]]);
				up.graphics.lineTo(p1.x, p1.y);
				over.graphics.lineTo(p1.x, p1.y);
				down.graphics.lineTo(p1.x, p1.y);
			}
			up.graphics.lineTo(p0.x, p0.y);
			over.graphics.lineTo(p0.x, p0.y);
			down.graphics.lineTo(p0.x, p0.y);
			up.graphics.endFill();
			over.graphics.endFill();
			down.graphics.endFill();
			
//			over.filters = [new GlowFilter(0xFFFFFF, 1, 2, 2, 2)];
//			down.filters = [new GlowFilter(0xFFFF00, 0.5, 4, 4, 4)];
			
			return new AdvancedButton(up, over, down);
		}
		
		/**
		 * 设置眼睛的位置
		 * @param position: {"x": Number, "y": Number}
		 * 
		 */		
		public function setEyePosition(position:Object):void
		{
			var p0:Object = mappingPoint(position);
			eye.x = p0.x;
			eye.y = p0.y;
			eye.visible = true;
		}
		
		/**
		 * 映射点
		 * @param source: {"x": Number, "y": Number}
		 * @return {"x": Number, "y": Number}
		 * 
		 */		
		private function mappingPoint(source:Object):Object
		{
			return {
				"x": (source.x - minX) / w0 * _mapWidth, 
				"y": (source.y - minY) / h0 * _mapHeight
			};
		}
	}
}