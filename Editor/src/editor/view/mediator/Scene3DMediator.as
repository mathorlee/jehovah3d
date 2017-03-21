package editor.view.mediator
{
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import editor.ApplicationFacade;
	import editor.view.Scene3D;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.event.MouseEvent3D;
	import jehovah3d.util.HexColor;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	public class Scene3DMediator extends Mediator
	{
		public static const NAME:String = 'Scene3DMediator';
		public static const MISSING_TEXTURE:String = "MissingTexture";
		
		public function Scene3DMediator(mediatorName:String=null, viewComponent:Object=null)
		{
			super(mediatorName, viewComponent);
		}
		
		override public function onRegister():void
		{
			view.addEventListener(MISSING_TEXTURE, onMissingTexture);
			view.addEventListener(MouseEvent3D.MOUSE_CLICK, onObject3DSelected);
			view.addEventListener(Scene3D.CAMERA_CHANGE, onCameraChange);
		}
		private function onCameraChange(evt:Event):void
		{
			facade.sendNotification(ApplicationFacade.CAMERA_ZNEAR_ZFAR_CHANGE, {"zNear": view.camera.zNear, "zFar": view.camera.zFar}, null);
		}
		private function onMissingTexture(evt:Event):void
		{
			var key:String;
			var keys:Vector.<String> = new Vector.<String>();
			for(key in view.missingTextureDict)
				keys.push(key);
			
			if(keys.length > 0)
				facade.sendNotification(ApplicationFacade.WARN_MISSING_TEXTURE, {"missingTextures": keys}, null);
		}
		private function onObject3DSelected(evt:MouseEvent3D):void
		{
			facade.sendNotification(ApplicationFacade.OBJECT3D_IS_SELECTED, {"object": evt.obj3d}, null);
		}
		override public function listNotificationInterests():Array
		{
			return [
				ApplicationFacade.STAGE_RESIZE, 
				ApplicationFacade.LOAD_SCENEFILES_COMPLETE, 
				ApplicationFacade.LOAD_MISSINGTEXTURES_COMPLETE, 
				ApplicationFacade.USE_DEFAULT_LIGHT, 
				ApplicationFacade.BACKGROUNDCOLOR_CHANGE, 
				ApplicationFacade.BACKGROUNDIMAGE_CHANGE, 
				ApplicationFacade.BACKGROUNDIMAGE_VISIBLE_CHANGE, 
				ApplicationFacade.CREATE_FREE_LIGHT
			];
		}
		
		override public function handleNotification(notification:INotification):void
		{
			switch(notification.getName())
			{
				case ApplicationFacade.STAGE_RESIZE:
					if(notification.getBody().width > 0 && notification.getBody().height > 0)
					{
						view.width = notification.getBody().width - 300;
						view.height = notification.getBody().height;
					}
					break;
				
				case ApplicationFacade.LOAD_SCENEFILES_COMPLETE:
					view.refreshScene(notification.getBody().tasks, notification.getBody().fuwo3d);
					break;
				
				case ApplicationFacade.LOAD_MISSINGTEXTURES_COMPLETE:
					view.addMissings(notification.getBody().tasks);
					break;
				
				case ApplicationFacade.USE_DEFAULT_LIGHT:
					Jehovah.useDefaultLight = Boolean(notification.getBody().useDefaultLight);
					//清空select系统, 清空Modifer
					view.selectManager.target = null;
					view.selectMove.movingTarget = null;
					view.selectMove.visible = false;
					facade.sendNotification(ApplicationFacade.OBJECT3D_IS_SELECTED, {"object": null}, null);
					//如果使用默认光照, 删掉Jehovah.lights, 只保留Jehovah.defaultLight
					if(Jehovah.useDefaultLight)
					{
						var i:int;
						for(i = 0; i < Jehovah.lights.length; i ++)
							view.scene.removeChild(Jehovah.lights[i]);
						Jehovah.lights.length = 0;
					}
					break;
				
				case ApplicationFacade.BACKGROUNDCOLOR_CHANGE:
					view.camera.bgColor = new HexColor(notification.getBody().color, 1);
					break;
				
				case ApplicationFacade.BACKGROUNDIMAGE_CHANGE:
					view.updateBackgroundImage(notification.getBody().bitmapData);
					break;
				
				case ApplicationFacade.BACKGROUNDIMAGE_VISIBLE_CHANGE:
					if(view.bg3d)
						view.bg3d.visible = notification.getBody().visible;
					break;
				
				case ApplicationFacade.CREATE_FREE_LIGHT:
					view.createAFreeLight();
					break;
				
				default:
					break;
			}
		}
		
		/**
		 * 处理丢失的材质 
		 * @param tasks
		 * 
		 */		
		private function handleMissingImages(tasks:Dictionary):void
		{
			
		}
		
		public function get view():Scene3D
		{
			return viewComponent as Scene3D;
		}
	}
}