package utils.file
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.ProgressEvent;
	
	public class TestAFRL extends Sprite
	{
		public var ttt:AdvancedFileFeferenceList;
		
		public function TestAFRL()
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private function onKeyDown(evt:KeyboardEvent):void
		{
			if(evt.charCode == 49)
			{
				if(!ttt)
				{
					ttt = new AdvancedFileFeferenceList();
					ttt.addEventListener(Event.COMPLETE, onFilesComplete);
					ttt.addEventListener(ProgressEvent.PROGRESS, onFilesProgress);
				}
				ttt.browse();
			}
		}
		private function onFilesComplete(evt:Event):void
		{
			trace("onFilesComplete");
		}
		private function onFilesProgress(evt:ProgressEvent):void
		{
//			trace("onFilesProgress");
			trace(evt.bytesLoaded / evt.bytesTotal);
		}
	}
}
