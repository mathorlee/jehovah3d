package utils.file 
{
	import com.fuwo.math.MyMath;
	import com.magi.image.codec.TgaDecoder;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	public class AdvancedFileFeferenceList extends EventDispatcher 
	{
		public static const START_LOADING:String = "StartLoading"; //事件
		
		private var fileFL:FileReferenceList;
		public var tasks:Dictionary = new Dictionary();
		public var debugMode:Boolean = false;
		
		public function AdvancedFileFeferenceList() 
		{
			
		}
		
		/**
		 * browse 
		 * 
		 */		
		public function browse(typeFilter:Array=null):void
		{
			if(!fileFL)
			{
				fileFL = new FileReferenceList();
				fileFL.addEventListener(Event.SELECT, onSelect);
				fileFL.addEventListener(Event.CANCEL, onCancel);
			}
			clearTaskDict(); //清理taskDict
			fileFL.browse(typeFilter); //弹出“选择文件”对话框
		}
		
		private function clearTaskDict():void
		{
			var keys:Array = [];
			var key:*;
			for(key in tasks)
				keys.push(key);
			for each(key in keys)
			{
				if(tasks[key].hasOwnProperty("data"))
					tasks[key].data = null;
				tasks[key] = null;
				delete tasks[key];
			}
		}
		
		private function onSelect(evt:Event):void
		{
//			trace("onFLSelect");
			dispatchEvent(new Event(START_LOADING, false, false)); //开始加载
			
			var i:int;
			for(i = 0;i < fileFL.fileList.length;i ++)
			{
				if(debugMode)
					trace("starts loading " + "\"" + fileFL.fileList[i].name + "\"");
				tasks[fileFL.fileList[i].name] = {percent: 0, successed: false, data: null};
				fileFL.fileList[i].addEventListener(ProgressEvent.PROGRESS, onProgress);
				fileFL.fileList[i].addEventListener(Event.COMPLETE, onComplete);
				fileFL.fileList[i].load();
			}
		}
		
		private function onCancel(evt:Event):void
		{
//			trace("onFLCancel");
		}
		
		private function onProgress(evt:ProgressEvent):void
		{
			tasks[evt.target.name].percent = evt.bytesLoaded / evt.bytesTotal;
			update();
		}
		
		private function onComplete(evt:Event):void
		{
			if(debugMode)
				trace("complete loading " + "\"" + evt.target.name + "\"");
			var fr:FileReference = evt.target as FileReference;
			var data:ByteArray = fr.data;
			var fileExtention:String = MyMath.analysisFileExtentionFromURL(fr.name).toUpperCase();
			tasks[fr.name].extension = fileExtention;
			if(fileExtention == "JPG" || fileExtention == "PNG" || fileExtention == "BMP" || fileExtention == "SWF")
			{
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				loader.loadBytes(data);
				tasks[fr.name].loader = loader;
			}
			else if(fileExtention == "TGA")
			{
				var decoder:TgaDecoder = new TgaDecoder();
				decoder.Decode(data, false);
				tasks[fr.name].percent = 1;
				tasks[fr.name].successed = true;
				tasks[fr.name].data = {"bitmapData": decoder.bitmapData};
				update();
			}
			else if(fileExtention == "FUWO3D" || fileExtention == "3DS")
			{
				tasks[fr.name].percent = 1;
				tasks[fr.name].successed = true;
				tasks[fr.name].data = data;
				update();
			}
			else if(fileExtention == "TXT" || fileExtention == "JSON")
			{
				tasks[fr.name].percent = 1;
				tasks[fr.name].successed = true;
				tasks[fr.name].data = data.readUTFBytes(data.length);
				update();
			}
			else
			{
				tasks[fr.name].percent = 1;
				tasks[fr.name].successed = true;
				tasks[fr.name].data = data;
				update();
			}
		}
		
		private function onLoadComplete(evt:Event):void
		{
			evt.target.removeEventListener(Event.COMPLETE, onLoadComplete);
			
			var keys:Array = [];
			var key:*;
			for(key in tasks)
				keys.push(key);
			for each(key in keys)
			{
				if(tasks[key].loader == evt.target.loader)
				{
					tasks[key].percent = 1;
					tasks[key].successed = true;
					tasks[key].data = evt.target.content;
					tasks[key].loader = null;
					break;
				}
			}
			
			update();
		}
		
		private function onIOError(evt:IOErrorEvent):void
		{
			trace(evt.errorID, evt.eventPhase);
			evt.target.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			for(var key:* in tasks)
			{
				if(tasks[key].loader == evt.target.loader)
				{
					tasks[key].percent = 1;
					tasks[key].successed = false;
					tasks[key].data = evt.target.content;
					tasks[key].loader = null;
					break;
				}
			}
			
			update();
		}
		
		private function update():void
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
				if(tasks[key].successed == false)
					complete = false;
			}
			if(complete)
				dispatchEvent(new Event(Event.COMPLETE, false, false));
			else
			{
				dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, lowestPrecent, 1));
			}
		}
		
		public static function filesFilter(description:String, fileNames:Vector.<String>):FileFilter
		{
			var extension:String = "";
			var i:int;
			for(i = 0; i < fileNames.length - 1; i ++)
				extension += fileNames[i] + ";";
			if(fileNames.length > 0)
				extension += fileNames[fileNames.length - 1];
			
			return new FileFilter(description, extension);
		}
		public static function allFileFilter(description:String):FileFilter
		{
			return new FileFilter(description, "*.*");
		}
		public static function imageFilter(description:String):FileFilter
		{
			return new FileFilter(description, "*.jpg;*.png;*.bmp;*.tga");
		}
	}
}