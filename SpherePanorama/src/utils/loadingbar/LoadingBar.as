package utils.loadingbar
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	public class LoadingBar extends Sprite
	{
		/**
		 * prelader movieclip.
		 */
		protected var spreLoader:PPreloaderMC;
		
		/**
		 * load percent label
		 */
		protected var percentLabel:TextField;
		
		protected var format:TextFormat;
		
		public function LoadingBar()
		{
			this.createChildren();
			addEventListener(Event.REMOVED_FROM_STAGE, onRemove);
		}
		
		private function createChildren():void
		{
			this.spreLoader = new PPreloaderMC();
			this.spreLoader.x = int(-this.spreLoader.width * 0.5);
			this.addChild(this.spreLoader);
			
			format = new TextFormat();
			format.font = "Arial";
			format.color = 0x434343;
			format.size = 11;
			format.align = TextFormatAlign.CENTER;
			
			this.percentLabel = new TextField();
			this.percentLabel.text = '0%';
			this.percentLabel.selectable = false;
			this.percentLabel.autoSize = TextFieldAutoSize.LEFT;
			this.percentLabel.antiAliasType = AntiAliasType.ADVANCED;
			this.percentLabel.setTextFormat(format);
			this.percentLabel.x = 104;
			this.percentLabel.y = -9;
			this.addChild(this.percentLabel);
		}
		
		private function onRemove(evt:Event):void
		{
			removeEventListener(Event.REMOVED_FROM_STAGE, onRemove);
			this.spreLoader = null;
			this.percentLabel = null;
		}
		
		public function set percent(val:Number):void
		{
			var percent:int = Math.min(Math.round(val * 100), 100);
			this.spreLoader.setMainProgress(percent / 100);
			this.percentLabel.text = percent + '%';
			this.percentLabel.setTextFormat(format);
		}
		
	}
}