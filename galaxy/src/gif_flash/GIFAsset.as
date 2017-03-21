package gif_flash
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.printing.PrintJob;
	
	public class GIFAsset extends Sprite
	{
		private var gif:GIF;
		
		public var speed:Number = 1;
		public var percentage:Number = 0;
		public var autoPlay:Boolean = false;
		
		public function GIFAsset()
		{
			gif = new GIF();
			addChild(gif);
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function updatePercentage(percent:Number):void
		{
			//0 = 0
			//1 = numChild - 1
			var index:int = int(Math.floor(percent * (gif.numChildren - 1) + 0.5));
			for (var i:int = 0; i < gif.numChildren; i ++)
				gif.getChildAt(i).visible  = (i == index);
		}
		
		private function onEnterFrame(evt:Event):void
		{
			if (autoPlay)
				percentage += (1.0 / (gif.numChildren - 1) / speed);
			if (percentage > 1)
				percentage -= 1;
			if (percentage < 0)
				percentage += 1;
			updatePercentage(percentage);
		}
		
		public function get scale():Number
		{
			return gif.scaleX;
		}
		public function set scale(value:Number):void
		{
			gif.scaleX = gif.scaleY = value;
		}
	}
}