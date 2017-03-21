package utils.bulkloader
{
	import com.fuwo.math.MyMath;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="progress", type="flash.events.ProgressEvent")]
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	
	public class AdvancedLoader extends EventDispatcher
	{
		private var _loader:Object;
		private var _request:URLRequest;
		private var _retryTimes:int;
		private var _fileExtention:String;
		public var debugMode:Boolean = false;
		
		public function AdvancedLoader(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function load(request:URLRequest, retryTimes:int = 1):void
		{
			_request = request;
			_retryTimes = retryTimes;
			_fileExtention = MyMath.analysisFileExtentionFromURL(_request.url);
			if(debugMode)
			{
				trace("url: " + _request.url);
				trace("file extention: " + _fileExtention);
			}
			if(_fileExtention == "jpg" || _fileExtention == "JPG" || 
				_fileExtention == "png" || _fileExtention == "PNG" || 
				_fileExtention == "atf" || _fileExtention == "ATF" || 
				_fileExtention == "swf" || _fileExtention == "SWF" || 
				_fileExtention == "tga" || _fileExtention == "TGA" || 
				_fileExtention == "gif" || _fileExtention == "GIF")
			{
				if(debugMode)
					trace("loader type: Loader");
				_loader = new Loader();
				_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
				_loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onProgress);
				_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				_loader.load(_request, new LoaderContext(true)); //第一次下载。
			}
			else //其它后缀，使用URLLoader，包括空后缀。
			{
				if(debugMode)
					trace("loader type: URLLoader");
				_loader = new URLLoader;
				if(_fileExtention == "FUWO3D" || _fileExtention == "3DS" || _fileExtention == "F3D") //当文件扩展名为这些时dataFormat设置为二进制。有待拓展。
					_loader.dataFormat = URLLoaderDataFormat.BINARY;
				else if(_fileExtention == "txt" || _fileExtention == "xml")
					_loader.dataFormat = URLLoaderDataFormat.TEXT;
				_loader.addEventListener(Event.COMPLETE, onComplete);
				_loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
				_loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				_loader.load(_request); //第一次下载。
			}
		}
		
		private function onComplete(evt:Event):void
		{
			removeListeners(); //下载完成后释放。
			dispatchEvent(evt);
		}
		private function onProgress(evt:ProgressEvent):void
		{
			dispatchEvent(evt);
		}
		private function onIOError(evt:IOErrorEvent):void
		{
			_retryTimes --;
//			if(_loader is Loader && _loader.contentLoaderInfo.bytesLoaded > 0)
//			{
//				trace(_loader.contentLoaderInfo.bytesLoaded, _loader.contentLoaderInfo.bytesTotal);
//				Loader(_loader).unload();
//				_loader.close();
//			}
//			else if(_loader is URLLoader && _loader.bytesLoaded > 0)
//				_loader.close();
			if(_retryTimes > 0)
			{
				_loader.load(_request); //再次下载。
				if(debugMode)
					trace("retry");
			}
			else
			{
				removeListeners(); //失败后释放。
				dispatchEvent(evt); //若重试retryTimes仍然失败，则发送失败事件。
			}
		}
		
		public function get data():*
		{
			if(_loader is Loader)
				return _loader.content;
			else if(_loader is URLLoader)
				return _loader.data;
		}
		public function get url():String
		{
			return _request.url;
		}
		
		/**
		 * 加载成功/失败后调用dispose，移除侦听函数
		 * 
		 */		
		public function removeListeners():void
		{
			if(_loader is Loader)
			{
				_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onComplete);
				_loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, onProgress);
				_loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			}
			else if(_loader is URLLoader)
			{
				_loader.removeEventListener(Event.COMPLETE, onComplete);
				_loader.removeEventListener(ProgressEvent.PROGRESS, onProgress);
				_loader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			}
		}
		
		/**
		 * 任何时间都可以调用close()。close()将终止未完成的加载，并移侦听函数
		 * 
		 */		
		public function dispose():void
		{
			if(_loader is Loader)
			{
				if(Loader(_loader).contentLoaderInfo.hasEventListener(Event.COMPLETE))
					Loader(_loader).close();
			}
			else if(_loader is URLLoader)
			{
				if(URLLoader(_loader).hasEventListener(Event.COMPLETE))
					URLLoader(_loader).close();
			}
			removeListeners();
		}
	}
}