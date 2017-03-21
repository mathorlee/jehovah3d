package editor.contorller.init
{
	import org.puremvc.as3.patterns.command.MacroCommand;
	
	public class StartupCommand extends MacroCommand
	{
		override protected function initializeMacroCommand():void
		{
			addSubCommand(InitModelCommand);
			addSubCommand(InitControllerCommand);
			addSubCommand(InitViewCommand);
		}
	}
}