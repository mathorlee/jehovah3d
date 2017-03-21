package editor.contorller.init
{
	import editor.ApplicationFacade;
	import editor.contorller.popup.DestroyDecimalVRSceneCommand;
	import editor.contorller.popup.PopupDecimalVRSceneCommand;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.command.SimpleCommand;
	
	
	public class InitControllerCommand extends SimpleCommand
	{
		override public function execute(notification:INotification):void
		{
			facade.registerCommand(ApplicationFacade.POPUP_DECIMAL_VRSCENE, PopupDecimalVRSceneCommand);
			facade.registerCommand(ApplicationFacade.DESTROY_DECIMAL_VRSCENE, DestroyDecimalVRSceneCommand);
		}
	}
}