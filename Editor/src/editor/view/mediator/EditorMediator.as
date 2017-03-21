package editor.view.mediator
{
	import editor.Editor;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	public class EditorMediator extends Mediator
	{
		public static const NAME:String = 'EditorMediator';
		
		public function EditorMediator(mediatorName:String=null, viewComponent:Object=null)
		{
			super(mediatorName, viewComponent);
		}
		
		override public function onRegister():void
		{
			
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
		
		public function get view():Editor
		{
			return viewComponent as Editor;
		}
	}
}