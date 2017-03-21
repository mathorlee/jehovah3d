package editor.contorller.popup
{
	import editor.Editor;
	import editor.view.mediator.EditorMediator;
	import editor.view.mediator.popup.DecimalVRSceneMediator;
	import editor.view.popup.DecimalVRScene;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.command.SimpleCommand;
	
	public class PopupDecimalVRSceneCommand extends SimpleCommand
	{
		override public function execute(notification:INotification):void
		{
			var view:DecimalVRScene;
			if(facade.retrieveMediator(DecimalVRSceneMediator.NAME))
			{
				view = DecimalVRSceneMediator(facade.retrieveMediator(DecimalVRSceneMediator.NAME)).view;
				view.decimalTA.text = notification.getBody().decimalVRScene;
			}
			else
			{
				view = new DecimalVRScene();
				view.horizontalCenter = view.verticalCenter = 0;
				var app:Editor = EditorMediator(facade.retrieveMediator(EditorMediator.NAME)).view;
				app.addElement(view);
				view.decimalTA.text = notification.getBody().decimalVRScene;
				facade.registerMediator(new DecimalVRSceneMediator(DecimalVRSceneMediator.NAME, view));
			}
		}
	}
}