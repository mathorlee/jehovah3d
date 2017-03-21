package editor.view.mediator
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	
	import mx.events.CloseEvent;
	
	import spark.utils.DataItem;
	
	import editor.ApplicationFacade;
	import editor.view.MissingTexture;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	import utils.file.AdvancedFileFeferenceList;
	
	public class MissingTextureMediator extends Mediator
	{
		public static const NAME:String = 'MissingTextureMediator';
		private var fileRef:AdvancedFileFeferenceList;
		private var missingTextures:Vector.<String>; //丢失的贴图的文件名数组
		
		public function MissingTextureMediator(mediatorName:String=null, viewComponent:Object=null)
		{
			super(mediatorName, viewComponent);
		}
		
		override public function onRegister():void
		{
			view.pickButton.addEventListener(MouseEvent.CLICK, onPickButtonClick);
			view.ignoreButton.addEventListener(MouseEvent.CLICK, onIgnoreButtonClick);
			
			view.g0.addEventListener(CloseEvent.CLOSE, onCloseButtonClick);
			view.g0.closeButton.buttonMode = true;
			
			view.unfoldButton.addEventListener(MouseEvent.CLICK, onUnfoldButtonClick);
		}
		
		private function onPickButtonClick(evt:MouseEvent):void
		{
			if(!fileRef)
			{
				fileRef = new AdvancedFileFeferenceList();
				fileRef.addEventListener(AdvancedFileFeferenceList.START_LOADING, onStart);
				fileRef.addEventListener(Event.COMPLETE, onFilesComplete);
				fileRef.addEventListener(ProgressEvent.PROGRESS, onFilesProgress);
			}
			fileRef.browse([AdvancedFileFeferenceList.filesFilter("丢失的贴图(*.jpg, *.png, *.bmp, *.tga)", missingTextures), AdvancedFileFeferenceList.allFileFilter("所有文件(*.*)")]);
		}
		
		private function onStart(evt:Event):void
		{
			hideView();
			facade.sendNotification(ApplicationFacade.LOAD_START, null, null);
		}
		
		private function onFilesComplete(evt:Event):void
		{
			facade.sendNotification(ApplicationFacade.LOAD_COMPLETE, null, null); //隐藏loadingBar
			facade.sendNotification(ApplicationFacade.LOAD_MISSINGTEXTURES_COMPLETE, {"tasks": fileRef.tasks}, null);
		}
		
		private function onFilesProgress(evt:ProgressEvent):void
		{
			facade.sendNotification(ApplicationFacade.LOAD_PROGRESS, {"percent": evt.bytesLoaded / evt.bytesTotal}, null);
		}
		
		private function onIgnoreButtonClick(evt:MouseEvent):void
		{
			foldView();
		}
		
		private function onUnfoldButtonClick(evt:MouseEvent):void
		{
			unfoldView();
		}
		private function onCloseButtonClick(evt:CloseEvent):void
		{
			foldView();
		}
		
		private function hideView():void
		{
			view.visible = false;
		}
		private function showView():void
		{
			view.visible = true;
			unfoldView();
		}
		private function foldView():void
		{
			view.horizontalCenter = undefined;
			view.verticalCenter = undefined;
			view.top = 10;
			view.right = 10 + 300;
			
			view.width = 120;
			view.height = 30;
			view.g0.visible = false;
			view.g1.visible = true;
		}
		
		private function unfoldView():void
		{
			view.horizontalCenter = 0;
			view.verticalCenter = 0;
			view.top = undefined;
			view.right = undefined;
			
			view.width = 400;
			view.height = 200;
			view.g0.visible = true;
			view.g1.visible = false;
		}
		
		override public function listNotificationInterests():Array
		{
			return [
				ApplicationFacade.WARN_MISSING_TEXTURE, 
				ApplicationFacade.HIDE_MISSINGTEXTURE_WARNING
			];
		}
		
		override public function handleNotification(notification:INotification):void
		{
			switch(notification.getName())
			{
				case ApplicationFacade.WARN_MISSING_TEXTURE:
					missingTextures = notification.getBody().missingTextures as Vector.<String>;
					var i:int;
					var di:DataItem;
					view.listData.removeAll();
					for(i = 0; i < missingTextures.length; i ++)
					{
						di = new DataItem();
						di.missingTexture = missingTextures[i];
						view.listData.addItem(di);
					}
					showView();
					break;
				
				case ApplicationFacade.HIDE_MISSINGTEXTURE_WARNING:
					hideView();
					break;
				
				default:
					break;
			}
		}
		
		public function get view():MissingTexture
		{
			return viewComponent as MissingTexture;
		}
	}
}