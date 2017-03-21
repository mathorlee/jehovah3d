package jehovah3d.core
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	public class View extends Sprite
	{
		private var _viewWidth:Number;
		private var _viewHeight:Number;
		public function View(viewWidth:Number, viewHeight:Number)
		{
			_viewWidth = viewWidth;
			_viewHeight = viewHeight;
			
			hitArea = new Sprite();
			hitArea.graphics.beginFill(0xFF7700, 1);
			hitArea.graphics.drawRect(0, 0, 100, 100);
			hitArea.graphics.endFill();
			addChild(hitArea);
			hitArea.mouseEnabled = false;
			hitArea.visible = false;
			hitArea.width = _viewWidth;
			hitArea.height = _viewHeight;
			
			addDiagram();
			if(stage)
				onAdded();
			else
				addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function onAdded(evt:Event = null):void
		{
			if(hasEventListener(Event.ADDED_TO_STAGE))
				removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemove);
		}
		private function onRemove(evt:Event):void
		{
			if(hasEventListener(Event.REMOVED_FROM_STAGE))
				removeEventListener(Event.REMOVED_FROM_STAGE, onRemove);
			if(stage.hasEventListener(KeyboardEvent.KEY_DOWN))
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			dispose();
		}
		private function onKeyDown(evt:KeyboardEvent):void
		{
			if(evt.ctrlKey && evt.altKey && evt.charCode == 49)
				diagram.visible = !diagram.visible;
		}
		public function set viewWidth(val:Number):void
		{
			if(_viewWidth != val)
			{
				_viewWidth = val;
				hitArea.width = _viewWidth;
				diagram.x = _viewWidth - diagram.width;
			}
		}
		public function set viewHeight(val:Number):void
		{
			if(_viewHeight != val)
			{
				_viewHeight = val;
				hitArea.height = _viewHeight;
				diagram.y = (_viewHeight - diagram.height) * 0.5;
			}
		}
		
		
		
		
		
		
		
		
		
		private var diagram:Sprite;
		private var fpsTF:TextField;
		private var objsTF:TextField;
		public var objs:uint = 0;
		private var trisTF:TextField;
		public var tris:uint = 0;
		private var vertsTF:TextField;
		public var verts:uint = 0;
		private var driverInfoTF:TextField;
		private var viewSizeTF:TextField;
		private function addDiagram():void
		{
			var format:TextFormat = new TextFormat();
			format.size = 10;
			format.color = 0x000000;
			format.bold = true;
			var tfWidth:Number = 160;
			var tfHeight:Number = 16;
			var diagramWidth:Number = tfWidth;
			var diagramHeight:Number = 100;
			
			diagram = new Sprite();
			diagram.mouseEnabled = false;
			diagram.graphics.clear();
			diagram.graphics.lineStyle(1, 0x000000, 1);
			diagram.graphics.beginFill(0xFF7700, 1);
			diagram.graphics.drawRect(0, 0, diagramWidth, diagramHeight);
			diagram.graphics.endFill();
			
			fpsTF = new TextField();
			fpsTF.defaultTextFormat = format;
			fpsTF.mouseEnabled = false;
			fpsTF.width = tfWidth;
			fpsTF.height = tfHeight;
			fpsTF.y = tfHeight * 0;
			diagram.addChild(fpsTF);
			
			objsTF = new TextField();
			objsTF.defaultTextFormat = format;
			objsTF.mouseEnabled = false;
			objsTF.width = tfWidth;
			objsTF.height = tfHeight;
			objsTF.y = tfHeight * 1;
			diagram.addChild(objsTF);
			
			trisTF = new TextField();
			trisTF.defaultTextFormat = format;
			trisTF.mouseEnabled = false;
			trisTF.width = tfWidth;
			trisTF.height = tfHeight;
			trisTF.y = tfHeight * 2;
			diagram.addChild(trisTF);
			
			vertsTF = new TextField();
			vertsTF.defaultTextFormat = format;
			vertsTF.mouseEnabled = false;
			vertsTF.width = tfWidth;
			vertsTF.height = tfHeight;
			vertsTF.y = tfHeight * 3;
			diagram.addChild(vertsTF);
			
			driverInfoTF = new TextField();
			driverInfoTF.defaultTextFormat = format;
			driverInfoTF.mouseEnabled = false;
			driverInfoTF.width = tfWidth;
			driverInfoTF.height = tfHeight;
			driverInfoTF.y = tfHeight * 4;
			driverInfoTF.multiline = true;
			diagram.addChild(driverInfoTF);
			
			viewSizeTF = new TextField();
			viewSizeTF.defaultTextFormat = format;
			viewSizeTF.mouseEnabled = false;
			viewSizeTF.width = tfWidth;
			viewSizeTF.height = tfHeight;
			viewSizeTF.y = tfHeight * 5;
			diagram.addChild(viewSizeTF);
			
			addChild(diagram);
			diagram.x = _viewWidth - diagram.width;
			diagram.y = (_viewHeight - diagram.height) * 0.5;
		}
		public function hideDiagram():void
		{
			diagram.visible = false;
		}
		public function updateDiagram(fps:uint, objs:uint, tris:uint, verts:uint, viewWidth:Number, viewHeight:Number):void
		{
			fpsTF.text = "fps: " + fps.toString();
			objsTF.text = "obj: " + objs.toString();
			trisTF.text = "tri: " + tris.toString();
			vertsTF.text = "vert: " + verts.toString();
			viewSizeTF.text = "view: " + viewWidth.toString() + "," + viewHeight.toString();
		}
		
		public function updateDriverInfo(driverInfo:String):void
		{
			driverInfoTF.text = "driverInfo: " + driverInfo;
		}
		
		public function dispose():void
		{
//			trace("view.dispose");
			if(diagram)
				diagram = null;
			if(fpsTF)
				fpsTF = null;
			if(objsTF)
				objsTF = null;
			if(trisTF)
				trisTF = null;
			if(vertsTF)
				vertsTF = null;
		}
	}
}