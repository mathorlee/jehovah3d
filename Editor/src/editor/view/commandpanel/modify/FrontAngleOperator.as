package editor.view.commandpanel.modify
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.core.UIComponent;
	
	public class FrontAngleOperator extends UIComponent
	{
		public static const FRONT_ANGLE_CHANGE:String = "FrontAngleChange";
		
		private var keyValues:Array = [0, Math.PI / 4, Math.PI / 2, Math.PI * 0.75, Math.PI];
		private var faultTolerant:Number = Math.PI / 18;
		
		private var _frontAngle:Number = 0; //俯视图角度
		private var _ball:UIComponent;
		public var radius:Number;
		private var oldPoint:Point;
		private var newPoint:Point;
		
		public function FrontAngleOperator()
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
			frontAngle = Math.atan2(evt.stageX - p0.x, p0.y - evt.stageY);
			dispatchEvent(new Event(FRONT_ANGLE_CHANGE, false, false));
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
		
		public function get frontAngle():Number
		{
			return _frontAngle;
		}
		public function set frontAngle(value:Number):void
		{
			_frontAngle = value;
			if(_frontAngle < 0)
			{
				if(Math.abs(_frontAngle) <= Math.PI / 2)
					_frontAngle = 0;
				else
					_frontAngle = Math.PI;
			}
			approachKeyValue();
			updateBallPosition();
		}
		private function approachKeyValue():void
		{
			var i:int;
			for(i = 0; i < keyValues.length; i ++)
				if(Math.abs(keyValues[i] - _frontAngle) <= faultTolerant)
				{
					_frontAngle = keyValues[i];
					break;
				}
		}
		public function updateBallPosition():void
		{
			if(_ball)
			{
				_ball.x = radius * Math.sin(_frontAngle);
				_ball.y = -radius * Math.cos(_frontAngle);
			}
		}
	}
}