package utils
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	public class TextHint extends Sprite
	{
		private var hintText:TextField;
		private var _fontSize:int;
		private var _fixWidth:Boolean;
		public var fixedWidth:int;
		private var _leading:int;
		public function TextHint(fontSize:int, fixWidth:Boolean, leading:int,language:String=null)
		{
			_fontSize = fontSize;
			_fixWidth = fixWidth;
			_leading = leading;
			hintText = new TextField();
			hintText.text = "";
			var format:TextFormat = new TextFormat("Arial", fontSize, 0xFFFFFF, false);
			format.leading = _leading;
			if(language=="ar_SA")
				format.align = "right";
			hintText.multiline = true;
			if(fixWidth)
				hintText.wordWrap = true;
			hintText.autoSize = TextFieldAutoSize.CENTER;
			hintText.defaultTextFormat = format;
			addChild(hintText);
			
			mouseEnabled = false;
			mouseChildren = false;
		}
		
		public function get text():String
		{
			return hintText.text;
		}
		public function set text(value:String):void
		{
			hintText.text = value;
			hintText.x = hintText.y = 5;
			hintText.width = fixedWidth-5;
			drawBG();
			
//			trace(hintText.text);
//			trace(hintText.width, hintText.height, hintText.x, hintText.y);
//			trace(this.width, this.height);
		}
		
		private function drawBG():void
		{
			graphics.clear();
			graphics.beginFill(0, 0.5);
			if(_fixWidth)
				graphics.drawRoundRect(0, 0, fixedWidth, hintText.height + hintText.y * 2, 5, 5);
			else
				graphics.drawRoundRect(0, 0, hintText.width + hintText.x * 2, hintText.height + hintText.y * 2, 5, 5);
			graphics.endFill();
		}
	}
}