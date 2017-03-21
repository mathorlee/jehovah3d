package utils.easybutton
{
	import flash.events.Event;
	
	public class ButtonBarEvent extends Event
	{
		public static const BUTTON_CLICK:String = "ButtonClick";
		
		private var _buttonIndex:int;
		
		public function ButtonBarEvent(type:String, buttonIndex:int, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			_buttonIndex = buttonIndex;
		}
		public function get buttonIndex():int
		{
			return _buttonIndex;
		}
		
		override public function clone():Event
		{
			return new ButtonBarEvent(type, buttonIndex, bubbles, cancelable);
		}
	}
}