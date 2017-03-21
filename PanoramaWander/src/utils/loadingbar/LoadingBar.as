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
			this.percentLabel.x = 14;//104
			this.percentLabel.y = -9;
//			this.addChild(this.percentLabel);
		}
		
		private function onRemove(evt:Event):void
		{
			removeEventListener(Event.REMOVED_FROM_STAGE, onRemove);
			this.spreLoader = null;
			this.percentLabel = null;
		}
		
		
		public function percent(val:Number,type:uint):void
		{
			var percent:int = Math.min(Math.round(val * 100), 100);
			var str:String = "";
			if(type==1)
				str = "软件已加载" +String(percent)+ '%';
			else
				str = "资源已加载" +String(percent)+ '%';
			this.percentLabel.text = str;
			this.percentLabel.setTextFormat(format);
			
			var frame:int = Math.round(percent/100*60);
			if(val==1)
				frame=60;
			else
			{
				if(frame>57)
					frame=57;
			}
			this.spreLoader.gotoAndStop(frame);
		}		
	}
}