package utils.bulkloader
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	
	[Event(name="complete", type="flash.events.Event")]
	/**
	 * bulk loader 
	 * @author lisongsong
	 * 
	 */	
	public class BulkLoader extends EventDispatcher
	{
		public static const STATE_INIT:int = 0;
		public static const STATE_SUCCESS:int = 1;
		public static const STATE_FAILED:int = 2;
		
		/**
		 * tast dictionary. 
		 */		
		public var tasks:Dictionary = new Dictionary();
		public var debugMode:Boolean = false;
		public var loaders:Vector.<AdvancedLoader> = new Vector.<AdvancedLoader>();
		
		public function BulkLoader(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		/**
		 * add a task. url is the key. 
		 * @param url
		 * 
		 */		
		public function add(url:String):void
		{
			if(tasks[url])
				return ;
			tasks[url] = {"percent": 0, "state": STATE_INIT, "data": null}; //state[0, 1, 2], 0: init, 1: success, 2: failed.
		}
		
		/**
		 * start to load. 
		 * 
		 */		
		public function load():void
		{
			var keys:Array = [];
			var key:*;
			for(key in tasks)
				keys.push(key);
			if(keys.length == 0)
			{
				dispatchEvent(new Event(Event.COMPLETE, false, false));
				return ;
			}
			for each(key in keys)
			{
				var loader:AdvancedLoader = new AdvancedLoader();
				loader.addEventListener(Event.COMPLETE, onComplete);
				loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
				loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				loader.load(new URLRequest(key), 2);
				loaders.push(loader);
				if(debugMode)
					trace("load: " + key);
			}
		}
		
		private function onProgress(evt:ProgressEvent):void
		{
			var loader:AdvancedLoader = evt.target as AdvancedLoader;
			if(evt.bytesTotal == 0)
				tasks[loader.url].percent = 1;
			else
				tasks[loader.url].percent = evt.bytesLoaded / evt.bytesTotal;
			updateProgress();
		}
		
		private function onIOError(evt:IOErrorEvent):void
		{
			var loader:AdvancedLoader = evt.target as AdvancedLoader;
			loader.removeEventListener(Event.COMPLETE, onComplete);
			loader.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			
			tasks[loader.url].percent = 1;
			tasks[loader.url].state = STATE_FAILED; //failed.
			update();
		}
		
		private function onComplete(evt:Event):void
		{
			var loader:AdvancedLoader = evt.target as AdvancedLoader;
			loader.removeEventListener(Event.COMPLETE, onComplete);
			loader.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			
			tasks[loader.url].data = loader.data;
			tasks[loader.url].state = STATE_SUCCESS; //success
//			trace(loader.url, "successed");
			update();
		}
		
		public function updateProgress():void
		{
			var keys:Array = [];
			var key:*;
			for(key in tasks)
				keys.push(key);
			
			var lowestPrecent:Number = 1;
			var complete:Boolean = true;
			for each(key in keys)
			{
				if(tasks[key].percent < lowestPrecent)
					lowestPrecent = tasks[key].percent;
			}
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, lowestPrecent, 1));
		}
		
		/**
		 * update bulkloader status. dispatch progress event or complete event. 
		 * 
		 */		
		public function update():void
		{
			var keys:Array = [];
			var key:*;
			for(key in tasks)
				keys.push(key);
			
			var complete:Boolean = true;
			for each(key in keys)
				if(tasks[key].state == STATE_INIT)
				{
					complete = false;
					break;
				}
			if(complete)
				dispatchEvent(new Event(Event.COMPLETE, false, false));
		}
		
		/**
		 * check is tast list is empty. 
		 * @return 
		 * 
		 */		
		public function get isEmpty():Boolean
		{
			var keys:Array = [];
			var key:*;
			for(key in tasks)
				keys.push(key);
			return keys.length == 0;
		}
		
		/**
		 * dispose. 
		 * 
		 */		
		public function dispose():void
		{
			var keys:Array = [];
			var key:*;
			for(key in tasks)
				keys.push(key);
			for each(key in keys)
			{
				tasks[key] = null;
				delete tasks[key];
			}
			
			var i:int;
			for(i = 0; i < loaders.length; i ++)
			{
				loaders[i].removeEventListener(Event.COMPLETE, onComplete);
				loaders[i].removeEventListener(ProgressEvent.PROGRESS, onProgress);
				loaders[i].removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				loaders[i].dispose();
			}
			loaders.length = 0;
		}
	}
}