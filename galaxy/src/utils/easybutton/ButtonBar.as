package utils.easybutton
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	public class ButtonBar extends Sprite
	{
		private var buttons:Vector.<AdvancedButton> = new Vector.<AdvancedButton>();
		private var _state:int = -1;
		public function ButtonBar()
		{
			super();
		}
		public function add(btn:AdvancedButton):void
		{
			buttons.push(btn);
			addChild(btn);
			btn.addEventListener(MouseEvent.CLICK, onClick);
		}
		
		private function onClick(evt:MouseEvent):void
		{
			var i:int;
			for(i = 0; i < buttons.length; i ++)
				if(evt.target == buttons[i])
				{
					state = i;
					break;
				}
			dispatchEvent(new ButtonBarEvent(ButtonBarEvent.BUTTON_CLICK, _state, false, false));
		}
		
		public function set state(value:int):void
		{
			if(_state != value)
			{
				_state = value;
				var i:int;
				for(i = 0; i < buttons.length; i ++)
				{
					if(_state == i)
					{
						buttons[i].state = EasyButtonState.DOWN_STATE;
						buttons[i].lockState = true;
					}
					else
					{
						buttons[i].lockState = false;
						buttons[i].state = EasyButtonState.UP_STATE;
					}
				}
			}
		}
	}
}