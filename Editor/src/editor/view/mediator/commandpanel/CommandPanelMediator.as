package editor.view.mediator.commandpanel
{
	import flash.events.Event;
	
	import editor.view.commandpanel.CommandPanel;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	public class CommandPanelMediator extends Mediator
	{
		public static const NAME:String = 'CommandPanelMediator';
		
		public function CommandPanelMediator(mediatorName:String=null, viewComponent:Object=null)
		{
			super(mediatorName, viewComponent);
		}
		
		override public function onRegister():void
		{
			view.menu.addEventListener(Event.CHANGE, onMenuChange);
		}
		
		private function onMenuChange(evt:Event):void
		{
			var obj:Object = view.menu.selectedItem;
			switch(view.menu.selectedItem)
			{
				case "Create":
					view.createPanel.visible = true;
					view.modifyPanel.visible = false;
					break;
				case "Modify":
					view.createPanel.visible = false;
					view.modifyPanel.visible = true;
					break;
				default:
					break;
			}
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
		
		public function get view():CommandPanel
		{
			return viewComponent as CommandPanel;
		}
	}
}