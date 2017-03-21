package editor.view.mediator.commandpanel
{
	import flash.events.MouseEvent;
	
	import editor.ApplicationFacade;
	import editor.view.commandpanel.SubCreatePanel;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	public class SubCreatePanelMediator extends Mediator
	{
		public static const NAME:String = 'SubCreatePanelMediator';
		
		public function SubCreatePanelMediator(mediatorName:String=null, viewComponent:Object=null)
		{
			super(mediatorName, viewComponent);
		}
		
		override public function onRegister():void
		{
			view.createFreeLightBTN.visible = false;
			view.createFreeLightBTN.addEventListener(MouseEvent.CLICK, onCreateFreeLightClick);
		}
		
		private function onCreateFreeLightClick(evt:MouseEvent):void
		{
			facade.sendNotification(ApplicationFacade.CREATE_FREE_LIGHT, null, null);
		}
		
		override public function listNotificationInterests():Array
		{
			return [
				ApplicationFacade.USE_DEFAULT_LIGHT
			];
		}
		
		override public function handleNotification(notification:INotification):void
		{
			switch(notification.getName())
			{
				case ApplicationFacade.USE_DEFAULT_LIGHT:
					view.createFreeLightBTN.visible = Boolean(1 - notification.getBody().useDefaultLight);
					break;
				
				default:
					break;
			}
		}
		
		public function get view():SubCreatePanel
		{
			return viewComponent as SubCreatePanel;
		}
	}
}