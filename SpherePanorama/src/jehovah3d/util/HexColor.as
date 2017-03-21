package jehovah3d.util
{
	public class HexColor
	{
		private var _hexColor:uint;
		private var _hexRed:uint;
		private var _hexGreen:uint;
		private var _hexBlue:uint;
		private var _hexAlpha:uint;
		
		private var _fractionalRed:Number;
		private var _fractionalGreen:Number;
		private var _fractionalBlue:Number;
		private var _fractionalAlpha:Number;
		
		public function HexColor(color:uint = 0x0000FF, alpha:Number = 1.0)
		{
			_hexColor = color;
			_fractionalAlpha = alpha;
			updateFractionals();
		}
		
		public function get fractionalRed():Number
		{
			return _fractionalRed;
		}
		public function get fractionalGreen():Number
		{
			return _fractionalGreen;
		}
		public function get fractionalBlue():Number
		{
			return _fractionalBlue;
		}
		public function get fractionalAlpha():Number
		{
			return _fractionalAlpha;
		}
		
		public function get hexColor():uint
		{
			return _hexColor;
		}
		public function set hexColor(value:uint):void
		{
			_hexColor = value;
			updateFractionals();
		}
		private function updateFractionals():void
		{
			_fractionalRed = ((_hexColor >> 16) & 0xFF) / 0xFF;
			_fractionalGreen = ((_hexColor >> 8) & 0xFF) / 0xFF;
			_fractionalBlue = (_hexColor & 0xFF) / 0xFF;
		}
	}
}