package editor.view.mediator
{
	import com.fuwo.math.MyMath;
	import com.magi.image.codec.TgaDecoder;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import mx.events.ColorPickerEvent;
	
	import editor.ApplicationFacade;
	import editor.view.Background;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	import utils.file.AdvancedFileFeferenceList;
	
	public class BackgroundMediator extends Mediator
	{
		public static const NAME:String = 'BackgroundMediator';
		private var fileRef:FileReference;
		private var bgimageName:String;
		public function BackgroundMediator(mediatorName:String=null, viewComponent:Object=null)
		{
			super(mediatorName, viewComponent);
		}
		
		override public function onRegister():void
		{
			view.colorPicker.addEventListener(ColorPickerEvent.CHANGE, onColorPickerChange);
			view.loadBGButton.addEventListener(MouseEvent.CLICK, onLoadBGButtonComplete);
			view.hideBGCheckBox.addEventListener(Event.CHANGE, onHideBGCheckBoxChange);
		}
		
		private function onColorPickerChange(evt:Event):void
		{
			facade.sendNotification(ApplicationFacade.BACKGROUNDCOLOR_CHANGE, {"color": view.colorPicker.selectedColor}, null);
		}
		private function onLoadBGButtonComplete(evt:MouseEvent):void
		{
			if(!fileRef)
			{
				fileRef = new FileReference();
				fileRef.addEventListener(Event.SELECT, onFileSelected);
				fileRef.addEventListener(Event.CANCEL, onCancel);
				fileRef.addEventListener(ProgressEvent.PROGRESS, onProgress);
				fileRef.addEventListener(Event.COMPLETE, onComplete);
			}
			fileRef.browse([AdvancedFileFeferenceList.imageFilter("背景图片(*.jpg, *.png, *.bmp, *.tga)")]);
		}
		private function onFileSelected(evt:Event):void
		{
			facade.sendNotification(ApplicationFacade.LOAD_START, null, null);
			fileRef.load();
		}
		public function onCancel(evt:Event):void
		{
			
		}
		private function onComplete(evt:Event):void
		{
			var fileExtention:String = MyMath.analysisFileExtentionFromURL(evt.target.name).toUpperCase();
			var data:ByteArray = evt.target.data as ByteArray;
			bgimageName = evt.target.name;
			if(fileExtention == "JPG" || fileExtention == "PNG" || fileExtention == "BMP")
			{
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				loader.loadBytes(evt.target.data);
			}
			else if(fileExtention == "TGA")
			{
				var decoder:TgaDecoder = new TgaDecoder();
				decoder.Decode(data, false);
				facade.sendNotification(ApplicationFacade.LOAD_COMPLETE, null, null);
				facade.sendNotification(ApplicationFacade.BACKGROUNDIMAGE_CHANGE, {"bitmapData": decoder.bitmapData}, null);
				view.msg.text = "背景图: " + bgimageName;
			}
			else
			{
				facade.sendNotification(ApplicationFacade.LOAD_COMPLETE, null, null);
			}
		}
		private function onLoadComplete(evt:Event):void
		{
			facade.sendNotification(ApplicationFacade.LOAD_COMPLETE, null, null);
			facade.sendNotification(ApplicationFacade.BACKGROUNDIMAGE_CHANGE, {"bitmapData": evt.target.content.bitmapData}, null);
			view.msg.text = "背景图: " + bgimageName;
		}
		private function onIOError(evt:IOErrorEvent):void
		{
			facade.sendNotification(ApplicationFacade.LOAD_COMPLETE, null, null);
		}
		private function onProgress(evt:ProgressEvent):void
		{
			facade.sendNotification(ApplicationFacade.LOAD_PROGRESS, {"percent": evt.bytesLoaded / evt.bytesTotal}, null);
		}
		
		private function onHideBGCheckBoxChange(evt:Event):void
		{
			facade.sendNotification(ApplicationFacade.BACKGROUNDIMAGE_VISIBLE_CHANGE, {"visible": !view.hideBGCheckBox.selected}, null);
		}
		
		override public function listNotificationInterests():Array
		{
			return [
				
			];
		}
		
		override public function handleNotification(notification:INotification):void
		{
			switch(notification.getName())
			{
				
			}
		}
		
		public function get view():Background
		{
			return viewComponent as Background;
		}
	}
}