package editor.view.mediator
{
	import flash.events.MouseEvent;
	import flash.net.FileReference;
	
	import mx.events.CloseEvent;
	
	import editor.ApplicationFacade;
	import editor.view.AnimationEdit;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	public class AnimationEditMediator extends Mediator
	{
		public static const NAME:String = 'AnimationEditMediator';
		
		public function AnimationEditMediator(mediatorName:String=null, viewComponent:Object=null)
		{
			super(mediatorName, viewComponent);
		}
		
		override public function onRegister():void
		{
			view.g0.addEventListener(CloseEvent.CLOSE, onCloseButtonClick);
			view.g0.closeButton.buttonMode = true;
			view.exportBTN.addEventListener(MouseEvent.CLICK, onExportButtonClick);
		}
		private function onCloseButtonClick(evt:CloseEvent):void
		{
			view.visible = false;
			view.updateData();
		}
		private function onExportButtonClick(evt:MouseEvent):void
		{
			view.updateData();
			var ff:FileReference = new FileReference();
			var obj:Object = {};
			obj.interaction = [];
			for each(var key:* in view.data)
				obj.interaction.push(key);
			ff.save(JSON.stringify(obj), "interaction.json");
		}
		
		override public function listNotificationInterests():Array
		{
			return [
				ApplicationFacade.PARSE_ANIMATION_COMPLETE
			];
		}
		
		override public function handleNotification(notification:INotification):void
		{
			switch(notification.getName())
			{
				case ApplicationFacade.PARSE_ANIMATION_COMPLETE:
					view.visible = true;
					view.data = notification.getBody();
					break;
			}
		}
		
		public function get view():AnimationEdit
		{
			return viewComponent as AnimationEdit;
		}
	}
}