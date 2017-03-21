package editor.view.mediator.popup
{
	import flash.events.MouseEvent;
	import flash.net.FileReference;
	
	import mx.events.CloseEvent;
	
	import editor.ApplicationFacade;
	import editor.view.popup.DecimalVRScene;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	public class DecimalVRSceneMediator extends Mediator
	{
		public static const NAME:String = 'AOMediator.as';
		
		public function DecimalVRSceneMediator(mediatorName:String=null, viewComponent:Object=null)
		{
			super(mediatorName, viewComponent);
		}
		
		override public function onRegister():void
		{
			view.g0.addEventListener(CloseEvent.CLOSE, onCloseButtonClick);
			view.g0.closeButton.buttonMode = true;
			view.saveBTN.addEventListener(MouseEvent.CLICK, onSaveBTNClick);
		}
		private function onCloseButtonClick(evt:CloseEvent):void
		{
			facade.sendNotification(ApplicationFacade.DESTROY_DECIMAL_VRSCENE, null, null);
		}
		private function onSaveBTNClick(evt:MouseEvent):void
		{
			var ff:FileReference = new FileReference();
			ff.save(view.decimalTA.text, "1.vrscene");
		}
		override public function listNotificationInterests():Array
		{
			return [];
		}
		
		override public function handleNotification(notification:INotification):void
		{
			
		}
		
		public function get view():DecimalVRScene
		{
			return viewComponent as DecimalVRScene;
		}
	}
}