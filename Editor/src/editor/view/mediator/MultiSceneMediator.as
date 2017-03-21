package editor.view.mediator
{
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import mx.events.CloseEvent;
	
	import spark.events.IndexChangeEvent;
	import spark.utils.DataItem;
	
	import editor.ApplicationFacade;
	import editor.view.MultiScene;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	public class MultiSceneMediator extends Mediator
	{
		public static const NAME:String = 'MultiSceneMediator';
		
		private var tasks:Dictionary;
		public function MultiSceneMediator(mediatorName:String=null, viewComponent:Object=null)
		{
			super(mediatorName, viewComponent);
		}
		
		override public function onRegister():void
		{
			view.fuwo3dList.addEventListener(IndexChangeEvent.CHANGE, onIndexChange);
			view.cancleButton.addEventListener(MouseEvent.CLICK, onCancleButtonClick);
			view.loadButton.addEventListener(MouseEvent.CLICK, onLoadButtonClick);
			
			view.addEventListener(CloseEvent.CLOSE, onCloseButtonClick);
			view.closeButton.buttonMode = true;
		}
		private function onIndexChange(evt:IndexChangeEvent):void
		{
			if(view.fuwo3dList.selectedIndex >= 0)
				view.loadButton.mouseEnabled = true;
		}
		private function onCancleButtonClick(evt:MouseEvent):void
		{
			onCloseButtonClick();
		}
		private function onLoadButtonClick(evt:MouseEvent):void
		{
			var fuwo3d:String = view.fuwo3dList.selectedItem.fuwo3d;
			for(var key:* in tasks)
			{
				if(key != fuwo3d && (tasks[key].extension == "FUWO3D" || tasks[key].extension == "F3D"))
					delete tasks[key];
			}
			facade.sendNotification(ApplicationFacade.LOAD_SCENEFILES_COMPLETE, {"tasks": tasks, "fuwo3d": fuwo3d}, null);
			onCloseButtonClick();
		}
		private function onCloseButtonClick(evt:CloseEvent = null):void
		{
			view.visible = false;
			if(tasks)
				tasks = null;
		}
		override public function listNotificationInterests():Array
		{
			return [
				ApplicationFacade.WARN_MULTI_SCENE
			];
		}
		
		override public function handleNotification(notification:INotification):void
		{
			switch(notification.getName())
			{
				case ApplicationFacade.WARN_MULTI_SCENE:
					var fuwo3ds:Vector.<String> = notification.getBody().fuwo3ds as Vector.<String>;
					tasks = notification.getBody().tasks as Dictionary;
					var i:int;
					var di:DataItem;
					view.listData.removeAll();
					for(i = 0; i < fuwo3ds.length; i ++)
					{
						di = new DataItem();
						di.fuwo3d = fuwo3ds[i];
						view.listData.addItem(di);
					}
					view.visible = true;
					view.loadButton.mouseEnabled = false;
					break;
				default:
					break;
			}
		}
		
		public function get view():MultiScene
		{
			return viewComponent as MultiScene;
		}
	}
}