package gif_flash
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import utils.easybutton.AdvancedButton;
	import utils.easybutton.EasyButton;
	
	public class GIFFlash extends Sprite
	{
		private var gif:GIFAsset;
		private var bg:Sprite;
		
		public function GIFFlash()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onResize);
			
			bg = new Sprite();
			addChild(bg);
			
			gif = new GIFAsset();
			gif.speed = 1.5;
			gif.mouseEnabled = false;
			gif.mouseChildren = false;
			addChild(gif);
			
			initUI();
			onResize(null);
			
			initBehavior();
		}
		
		private function onResize(evt:Event):void
		{
			if (stage.stageWidth > 0 && stage.stageHeight > 0)
			{
				bg.graphics.beginFill(0xFFFFFF, 1);
				bg.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
				bg.graphics.endFill();
				gif.x = stage.stageWidth / 2;
				gif.y = stage.stageHeight / 2;
				
				if (toolbar)
				{
					toolbar.x = (stage.stageWidth - toolbar.width) / 2;
					toolbar.y = stage.stageHeight - toolbar.height;
				}
			}
		}
		
		private var oldPoint:Point;
		private var newPoint:Point;
		private function initBehavior():void
		{
			this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			this.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}
		private function onMouseDown(evt:MouseEvent):void
		{
			if (evt.target != bg)
				return ;
			this.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.addEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
			oldPoint = new Point(evt.stageX, evt.stageY);
			onPauseClick(null);
		}
		private function onMouseMove(evt:MouseEvent):void
		{
			newPoint = new Point(evt.stageX, evt.stageY);
			
			gif.percentage -= (newPoint.x - oldPoint.x) / stage.stageWidth * 2;
			
			oldPoint.x = newPoint.x;
			oldPoint.y = newPoint.y;
		}
		private function onMouseUp(evt:MouseEvent):void
		{
			this.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.removeEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
		}
		private function onMouseWheel(evt:MouseEvent):void
		{
			if (evt.delta > 0)
				gif.scale *= 1.1;
			else
				gif.scale /= 1.1;
		}
		
		//推
		[Embed(source="/gif_flash/assets/images/ui/zoom-in-normal.png", mimeType="image/png")]
		private var zoomin_default:Class;
		[Embed(source="/gif_flash/assets/images/ui/zoom-in-hover.png", mimeType="image/png")]
		private var zoomin_over:Class;
		private var zoominBTN:AdvancedButton;
		//拉
		[Embed(source="/gif_flash/assets/images/ui/zoom-out-normal.png", mimeType="image/png")]
		private var zoomout_default:Class;
		[Embed(source="/gif_flash/assets/images/ui/zoom-out-hover.png", mimeType="image/png")]
		private var zoomout_over:Class;
		private var zoomoutBTN:AdvancedButton;
		//播放
		[Embed(source="/gif_flash/assets/images/ui/play-normal.png", mimeType="image/png")]
		private var play_default:Class;
		[Embed(source="/gif_flash/assets/images/ui/play-hover.png", mimeType="image/png")]
		private var play_over:Class;
		private var playBTN:AdvancedButton;
		//暂停
		[Embed(source="/gif_flash/assets/images/ui/pause-normal.png", mimeType="image/png")]
		private var pause_default:Class;
		[Embed(source="/gif_flash/assets/images/ui/pause-hover.png", mimeType="image/png")]
		private var pause_over:Class;
		private var pauseBTN:AdvancedButton;
		
		private var toolbar:Sprite;
		
		private function initUI():void
		{
			toolbar = new Sprite();
			addChild(toolbar);
			
			zoominBTN = new AdvancedButton(new zoomin_default(), new zoomin_over(), new zoomin_default());
			zoomoutBTN = new AdvancedButton(new zoomout_default(), new zoomout_over(), new zoomout_default());
			playBTN = new AdvancedButton(new play_default(), new play_over(), new play_default());
			pauseBTN = new AdvancedButton(new pause_default(), new pause_over(), new pause_default());
			zoomoutBTN.x = zoominBTN.x + zoominBTN.width + 1;
			playBTN.x = pauseBTN.x = zoomoutBTN.x + zoomoutBTN.width + 1;
			onPlayClick(null);
			
			zoominBTN.addEventListener(MouseEvent.CLICK, onZoomInClick);
			zoomoutBTN.addEventListener(MouseEvent.CLICK, onZoomOutClick);
			playBTN.addEventListener(MouseEvent.CLICK, onPlayClick);
			pauseBTN.addEventListener(MouseEvent.CLICK, onPauseClick);
			
			toolbar.addChild(zoominBTN);
			toolbar.addChild(zoomoutBTN);
			toolbar.addChild(playBTN);
			toolbar.addChild(pauseBTN);
			
//			toolbar.addEventListener(MouseEvent.MOUSE_OUT, onToolbarMouseOut);
//			toolbar.addEventListener(MouseEvent.MOUSE_OVER, onToolbarMouseOver);
		}
		
		private function onZoomInClick(evt:MouseEvent):void
		{
			gif.scale *= 1.1;
			evt.stopPropagation();
		}
		private function onZoomOutClick(evt:MouseEvent):void
		{
			gif.scale /= 1.1;
			evt.stopPropagation();
		}
		private function onPlayClick(evt:MouseEvent):void
		{
			gif.autoPlay = true;
			playBTN.visible = false;
			pauseBTN.visible = true;
		}
		private function onPauseClick(evt:MouseEvent):void
		{
			gif.autoPlay = false;
			playBTN.visible = true;
			pauseBTN.visible = false;
		}
	}
}