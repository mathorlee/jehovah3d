package galaxy
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	
	import utils.bulkloader.AdvancedLoader;
	import utils.loadingbar.LoadingBar;
	
	public class EmptySWF extends Sprite
	{
		private var subSWFURL:String;
		private var loadingBar:LoadingBar;
		public function EmptySWF()
		{
			if(loaderInfo.parameters)
			{
				if(loaderInfo.parameters.sub_swf)
				{
					subSWFURL = loaderInfo.parameters.sub_swf;
					init();
				}
			}
			
			subSWFURL = "http://media.tbcdn.cn/m/flash/20/test/test2.swf";
			subSWFURL = "galaxy/assets/EmbedResourceSpherePanorama3DShow.swf";
			init();
		}
		
		private function init():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onResize);
			
			loadingBar = new LoadingBar();
			addChild(loadingBar);
			loadingBar.x = stage.stageWidth * 0.5;
			loadingBar.y = stage.stageHeight * 0.5;
			
			var loader:AdvancedLoader = new AdvancedLoader();
			loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
			loader.addEventListener(Event.COMPLETE, onComplete);
			loader.load(new URLRequest(subSWFURL));
		}
		
		private function onProgress(evt:ProgressEvent):void
		{
			loadingBar.percent = evt.bytesTotal == 0 ? evt.bytesLoaded / 2000000 : evt.bytesLoaded / evt.bytesTotal;
		}
		private function onComplete(evt:Event):void
		{
			removeChild(loadingBar);
			loadingBar = null;
			
			trace(evt.target.data);
			addChild(evt.target.data.content);
		}
		
		private function onResize(evt:Event):void
		{
			if(stage.stageWidth > 0 && stage.stageHeight > 0)
			{
				if(loadingBar)
				{
					loadingBar.x = stage.stageWidth * 0.5;
					loadingBar.y = stage.stageHeight * 0.5;
				}
			}
		}
	}
}