package editor.view.mediator
{
	import editor.ApplicationFacade;
	import editor.view.LoadingBar;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	public class LoadingBarMediator extends Mediator
	{
		public static const NAME:String = 'LoadingBarMediator';
		
		public function LoadingBarMediator(mediatorName:String=null, viewComponent:Object=null)
		{
			super(mediatorName, viewComponent);
		}
		
		override public function onRegister():void
		{
			
		}
		
		override public function listNotificationInterests():Array
		{
			return [
				ApplicationFacade.LOAD_START, 
				ApplicationFacade.LOAD_COMPLETE, 
				ApplicationFacade.LOAD_PROGRESS
			];
		}
		
		override public function handleNotification(notification:INotification):void
		{
			switch(notification.getName())
			{
				case ApplicationFacade.LOAD_START:
					view.visible = true;
					view.loadingBar.percent = 0;
					break;
				
				case ApplicationFacade.LOAD_COMPLETE:
					view.visible = false;
					break;
				
				case ApplicationFacade.LOAD_PROGRESS:
					view.loadingBar.percent = notification.getBody().percent;
					break;
				
				default:
					break;
			}
		}
		
		public function get view():LoadingBar
		{
			return viewComponent as LoadingBar;
		}
	}
}