package utils.easybutton
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class EasyButton extends Sprite
	{
		private var _upState:DisplayObject;
		private var _overState:DisplayObject;
		private var _downState:DisplayObject;
		private var _state:uint = uint.MAX_VALUE;
		private var _lockState:Boolean = false;
		public function EasyButton(upState:DisplayObject, overState:DisplayObject, downState:DisplayObject)
		{
			_upState = upState;
			_overState = overState;
			_downState = downState;
			if(_upState is Bitmap)
				Bitmap(_upState).smoothing = true;
			if(_overState is Bitmap)
				Bitmap(_overState).smoothing = true;
			if(_downState is Bitmap)
				Bitmap(_downState).smoothing = true;
			
			super.addChild(_upState);
			super.addChild(_overState);
			super.addChild(_downState);
			state = EasyButtonState.UP_STATE;
			
			var area:Sprite = new Sprite();
			area.graphics.beginFill(0xFF7700, 1);
			area.graphics.drawRect(0, 0, this.width, this.height);
			area.graphics.endFill();
			super.hitArea = area;
			super.addChild(area);
			area.mouseEnabled = false;
			area.visible = false;
			
			super.buttonMode = true;
//			addEventListener(MouseEvent.CLICK, onClick);
			addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemove);
		}
		
		private function onClick(evt:MouseEvent):void
		{
			state = EasyButtonState.DOWN_STATE;
			lockState = true;
		}
		private function onMouseOver(evt:MouseEvent):void
		{
			if(_lockState)
				return ;
			state = EasyButtonState.OVER_STATE;
		}
		private function onMouseOut(evt:MouseEvent):void
		{
			if(_lockState)
				return ;
			state = EasyButtonState.UP_STATE;
		}
		private function onMouseDown(evt:MouseEvent):void
		{
			if(_lockState)
				return ;
			state = EasyButtonState.DOWN_STATE;
		}
		private function onMouseUp(evt:MouseEvent):void
		{
			if(_lockState)
				return ;
			state = EasyButtonState.OVER_STATE;
		}
		private function onRemove(evt:Event):void
		{
			if(hasEventListener(MouseEvent.MOUSE_DOWN))
				removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			if(hasEventListener(MouseEvent.MOUSE_UP))
				removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			if(hasEventListener(MouseEvent.MOUSE_OVER))
				removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			if(hasEventListener(MouseEvent.MOUSE_OUT))
				removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			
			dispose();
		}
		
		public function update():void
		{
			if(_state == EasyButtonState.UP_STATE)
			{
				_upState.visible = true;
				_overState.visible = false;
				_downState.visible = false;
			}
			else if(_state == EasyButtonState.OVER_STATE)
			{
				_upState.visible = false;
				_overState.visible = true;
				_downState.visible = false;
			}
			else if(_state == EasyButtonState.DOWN_STATE)
			{
				_upState.visible = false;
				_overState.visible = false;
				_downState.visible = true;
			}
		}
		
		public function dispose():void
		{
//			trace("easybutton.dispose");
			if(_upState)
				_upState = null;
			if(_overState)
				_overState = null;
			if(_downState)
				_downState = null;
		}
		
		
		public function get state():uint
		{
			return _state;
		}
		public function set state(val:uint):void
		{
			if(_state != val)
			{
				_state = val;
				if(!_lockState)
					update();
			}
		}
		public function get lockState():Boolean
		{
			return _lockState;
		}
		public function set lockState(val:Boolean):void
		{
			if(_lockState != val)
			{
				_lockState = val;
				if(_lockState)
					super.buttonMode = false;
				else
					super.buttonMode = true;
			}
		}
	}
}