package editor.contorller.popup
{
	import editor.Editor;
	import editor.view.mediator.EditorMediator;
	import editor.view.mediator.popup.DecimalVRSceneMediator;
	import editor.view.popup.DecimalVRScene;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.command.SimpleCommand;
	
	public class DestroyDecimalVRSceneCommand extends SimpleCommand
	{
		override public function execute(notification:INotification):void
		{
			var view:DecimalVRScene = DecimalVRSceneMediator(facade.retrieveMediator(DecimalVRSceneMediator.NAME)).view;
			var app:Editor = EditorMediator(facade.retrieveMediator(EditorMediator.NAME)).view;
			app.removeElement(view);
			facade.removeMediator(DecimalVRSceneMediator.NAME);
		}
	}
}