package editor.view.commandpanel.modify
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.core.UIComponent;
	
	public class TopAngleOperator extends UIComponent
	{
		public static const TOP_ANGLE_CHANGE:String = "TopAngleChange";
		
		private var keyValues:Array = [0, Math.PI / 4, Math.PI / 2, Math.PI * 0.75, Math.PI, -Math.PI / 4, -Math.PI / 2, -Math.PI * 0.75];
		private var faultTolerant:Number = Math.PI / 18;
		
		private var _topAngle:Number = 0; //俯视图角度
		private var _ball:UIComponent;
		public var radius:Number;
		private var oldPoint:Point;
		private var newPoint:Point;
		
		public function TopAngleOperator()
		{
			if(stage)
				onAdded();
			else
				addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		private function onAdded(evt:Event = null):void
		{
			if(evt)
				removeEventListener(Event.ADDED, onAdded);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemove);
			
			graphics.clear();
			graphics.lineStyle(2, 0, 1);
			graphics.beginFill(0xFF0000, 1);
			graphics.drawCircle(0, 0, radius);
			graphics.endFill();
			
			_ball = new UIComponent();
			_ball.graphics.clear();
			_ball.graphics.beginFill(0xFFFFFF, 1);
			_ball.graphics.drawCircle(0, 0, 8);
			_ball.graphics.endFill();
			_ball.buttonMode = true;
			addChild(_ball);
			_ball.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			updateBallPosition();
		}
		
		private function onMouseDown(evt:MouseEvent):void
		{
			parentApplication.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			parentApplication.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			
		}
		private function onMouseMove(evt:MouseEvent):void
		{
			//a.addEventListener a == currentTarget
			var p0:Point = localToGlobal(new Point(0, 0));
			var angle:Number = Math.atan2(p0.y - evt.stageY, evt.stageX - p0.x);
			angle += Math.PI / 2;
			if(angle > Math.PI)
				angle -= Math.PI * 2;
			topAngle = angle;
			dispatchEvent(new Event(TOP_ANGLE_CHANGE, false, false));
		}
		private function onMouseUp(evt:MouseEvent):void
		{
			parentApplication.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			parentApplication.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		private function onRemove(evt:Event):void
		{
			if(_ball)
			{
				_ball.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				_ball = null;
			}
		}
		
		public function get topAngle():Number
		{
			return _topAngle;
		}
		public function set topAngle(value:Number):void
		{
			_topAngle = value;
			approachKeyValue();
			updateBallPosition();
		}
		private function approachKeyValue():void
		{
			var i:int;
			for(i = 0; i < keyValues.length; i ++)
				if(Math.abs(keyValues[i] - _topAngle) <= faultTolerant)
				{
					_topAngle = keyValues[i];
					break;
				}
		}
		public function updateBallPosition():void
		{
			if(_ball)
			{
				_ball.x = radius * Math.cos(_topAngle - Math.PI / 2);
				_ball.y = -radius * Math.sin(_topAngle - Math.PI / 2);
			}
		}
	}
}