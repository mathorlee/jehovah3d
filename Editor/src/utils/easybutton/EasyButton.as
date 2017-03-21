package utils.easybutton
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	public class EasyButton extends Sprite
	{
		private var _upState:DisplayObject;
		private var _label:String = "测试";
		private var _state:uint = uint.MAX_VALUE;
		private var _lockState:Boolean = false;
		
		private const WIDTH:uint = 49;
		private const HEIGHT:uint = 56;
		
		private var glow:GlowFilter;
		private var circle:Shape;
		
		public function EasyButton(upState:DisplayObject, label:String)
		{
			this.addCircle();
			_upState = upState;
			this.addChild(_upState);
			_label = label;
			this.addLabel();
			state = EasyButtonState.UP_STATE;
			
			var area:Sprite = new Sprite();
			area.graphics.beginFill(0xFF7700, 1);
			area.graphics.drawRect(0, 0, this.width, this.height);
			area.graphics.endFill();
			area.mouseEnabled = false;
			area.visible = false;
			this.addChild(area);
			this.hitArea = area;
			this.buttonMode = true;
			
			addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemove);
			
			glow = new GlowFilter(0xFFFFFF, 0.5, 4, 4);
		}
		
		private function addLabel():void
		{
			var l:TextField = new TextField();
			l.width = WIDTH;
			l.text = _label;
			l.selectable = false;
			l.autoSize = TextFieldAutoSize.CENTER;
			l.antiAliasType = AntiAliasType.ADVANCED;
			l.setTextFormat(new TextFormat("宋体", 12, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER));
			l.y = 38;
			this.addChild(l);
		}
		
		private function addCircle():void
		{
			circle = new Shape();
			circle.graphics.lineStyle(1, 0xFFFFFF);
			circle.graphics.beginFill(0xFFFFFF, 0);
			circle.graphics.drawCircle(17, 17, 17);
			circle.graphics.endFill();
			circle.x = 7;
			circle.y = 2;
			circle.visible = false;
			this.addChild(circle);
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
			removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			
			dispose();
		}
		
		public function update():void
		{
			if(_state == EasyButtonState.UP_STATE)
			{
				_upState.filters = [];
				circle.visible = false;
			}
			else if(_state == EasyButtonState.OVER_STATE)
			{
				_upState.filters = [glow];
				circle.visible = false;
			}
			else if(_state == EasyButtonState.DOWN_STATE)
			{
				_upState.filters = [];
				circle.visible = true;
			}
		}
		
		public function dispose():void
		{
			if(_upState)
				_upState = null;
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