package editor.contorller.init
{
	import editor.Editor;
	import editor.view.mediator.AOMediator;
	import editor.view.mediator.AnimationEditMediator;
	import editor.view.mediator.BackgroundMediator;
	import editor.view.mediator.EditorMediator;
	import editor.view.mediator.LoadMediator;
	import editor.view.mediator.LoadingBarMediator;
	import editor.view.mediator.MissingTextureMediator;
	import editor.view.mediator.MultiSceneMediator;
	import editor.view.mediator.Scene3DMediator;
	import editor.view.mediator.commandpanel.CommandPanelMediator;
	import editor.view.mediator.commandpanel.SubCreatePanelMediator;
	import editor.view.mediator.commandpanel.SubModifyPanelMediator;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.command.SimpleCommand;
	
	public class InitViewCommand extends SimpleCommand
	{
		override public function execute(notification:INotification):void
		{
			var app:Editor = notification.getBody() as Editor;
			facade.registerMediator(new EditorMediator(EditorMediator.NAME, app));
			facade.registerMediator(new Scene3DMediator(Scene3DMediator.NAME, app.scene3D));
			facade.registerMediator(new LoadMediator(LoadMediator.NAME, app.load));
			facade.registerMediator(new AOMediator(AOMediator.NAME, app.load.ao));
			facade.registerMediator(new BackgroundMediator(BackgroundMediator.NAME, app.load.bg));
			facade.registerMediator(new LoadingBarMediator(LoadingBarMediator.NAME, app.loadingBar));
			facade.registerMediator(new MultiSceneMediator(MultiSceneMediator.NAME, app.multiScene));
			facade.registerMediator(new MissingTextureMediator(MissingTextureMediator.NAME, app.missingTexture));
			facade.registerMediator(new AnimationEditMediator(AnimationEditMediator.NAME, app.animationEdit));
			
			//register mediator for command panel and it's sub panels.
			facade.registerMediator(new CommandPanelMediator(CommandPanelMediator.NAME, app.commandPanel));
			facade.registerMediator(new SubCreatePanelMediator(SubCreatePanelMediator.NAME, app.commandPanel.createPanel));
			facade.registerMediator(new SubModifyPanelMediator(SubModifyPanelMediator.NAME, app.commandPanel.modifyPanel));
		}
	}
}