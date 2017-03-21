package editor.view.mediator.commandpanel
{
	import editor.ApplicationFacade;
	import editor.view.commandpanel.SubModifyPanel;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	public class SubModifyPanelMediator extends Mediator
	{
		public static const NAME:String = 'SubModifyPanelMediator';
		
		public function SubModifyPanelMediator(mediatorName:String=null, viewComponent:Object=null)
		{
			super(mediatorName, viewComponent);
		}
		
		override public function onRegister():void
		{
			
		}
		
		override public function listNotificationInterests():Array
		{
			return [
				ApplicationFacade.OBJECT3D_IS_SELECTED
			];
		}
		
		override public function handleNotification(notification:INotification):void
		{
			switch(notification.getName())
			{
				case ApplicationFacade.OBJECT3D_IS_SELECTED:
					view.object = notification.getBody().object;
					break;
			}
		}
		
		public function get view():SubModifyPanel
		{
			return viewComponent as SubModifyPanel;
		}
	}
}