package editor.view.mediator
{
	import flash.events.Event;
	import flash.events.FocusEvent;
	
	import mx.events.FlexEvent;
	
	import spark.components.TextInput;
	
	import editor.view.AmbientOcclusion;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.renderer.SSAORenderer;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	public class AOMediator extends Mediator
	{
		public static const NAME:String = 'AOMediator';
		
		public function AOMediator(mediatorName:String=null, viewComponent:Object=null)
		{
			super(mediatorName, viewComponent);
		}
		
		override public function onRegister():void
		{
			view.useAOCB.addEventListener(Event.CHANGE, onUseAOChange);
			
			var paramsTIs:Vector.<TextInput> = view.paramTIs;
			var i:int;
			for(i = 0; i < paramsTIs.length; i ++)
			{
				paramsTIs[i].mouseEnabled = paramsTIs[i].editable = paramsTIs[i].selectable = false;
				paramsTIs[i].addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
				paramsTIs[i].addEventListener(FlexEvent.ENTER, onEnter);
			}
		}
		
		private function onUseAOChange(evt:Event):void
		{
			var paramsTIs:Vector.<TextInput> = view.paramTIs;
			var i:int;
			for(i = 0; i < paramsTIs.length; i ++)
				paramsTIs[i].mouseEnabled = paramsTIs[i].editable = paramsTIs[i].selectable = view.useAOCB.selected;
			
			Jehovah.useSSAO = view.useAOCB.selected;
			
			//使用AO
			if(view.useAOCB.selected)
			{
				var no:String = SSAORenderer.NAME;
				if(!Jehovah.camera.rendererDict[no])
					Jehovah.camera.rendererDict[no] = new SSAORenderer(null);
				
				//初始化/更新view
				view.scaleTI.text = String(SSAORenderer(Jehovah.camera.rendererDict[no]).scale);
				view.biasTI.text = String(SSAORenderer(Jehovah.camera.rendererDict[no]).bias);
				view.sampleRadiusTI.text = String(SSAORenderer(Jehovah.camera.rendererDict[no]).sampleRadius);
				view.intensityTI.text = String(SSAORenderer(Jehovah.camera.rendererDict[no]).intensity);
			}
		}
		
		private function onFocusOut(evt:FocusEvent):void
		{
			onChange(evt.currentTarget);
		}
		private function onEnter(evt:FlexEvent):void
		{
			Scene3DMediator(facade.retrieveMediator(Scene3DMediator.NAME)).view.setFocus();
		}
		private function onChange(target:Object):void
		{
			var no:String = SSAORenderer.NAME;
			var ssaoRenderer:SSAORenderer = Jehovah.camera.rendererDict[no];
			if(!ssaoRenderer)
//				throw new Error("?");
				return ;
			
			switch(target)
			{
				case view.scaleTI:
					ssaoRenderer.scale = Number(view.scaleTI.text);
					break;
				
				case view.biasTI:
					ssaoRenderer.bias = Number(view.biasTI.text);
					break;
				
				case view.sampleRadiusTI:
					ssaoRenderer.sampleRadius = Number(view.sampleRadiusTI.text);
					break;
				
				case view.intensityTI:
					ssaoRenderer.intensity = Number(view.intensityTI.text);
					break;
				
				default:
					break;
			}
		}
		
		override public function listNotificationInterests():Array
		{
			return [];
		}
		
		override public function handleNotification(notification:INotification):void
		{
			
		}
		
		public function get view():AmbientOcclusion
		{
			return viewComponent as AmbientOcclusion;
		}
	}
}