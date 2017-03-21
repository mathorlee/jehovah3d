package jehovah3d
{
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Point;
	
	import jehovah3d.core.Camera3D;
	import jehovah3d.core.Object3D;
	import jehovah3d.util.AssetsManager;
	
	public class Scene3DTemplateForASProject extends Sprite
	{
		public var scene:Object3D;
		public var stage3D:Stage3D;
		public var camera:Camera3D;
		
		public function Scene3DTemplateForASProject()
		{
			if(stage)
				onAdded();
			else
				addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function onAdded(evt:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemove);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onResize);
			
			initCamera();
			
			stage3D = stage.stage3Ds[0];
			var pos:Point = localToGlobal(new Point(0, 0)); //calculate global coordinate of stage3d.
			stage3D.x = pos.x;
			stage3D.y = pos.y;
			if(stage3D.context3D && stage3D.context3D.driverInfo != "Disposed")
				init3D();
			else
			{
				stage3D.addEventListener(Event.CONTEXT3D_CREATE, init3D); //even if context3D already exist, still listen context3d_create event in case of device loss(context3d disposed).
				stage3D.requestContext3D("auto");
			}
		}
		private function init3D(evt:Event = null):void
		{
			stage3D.removeEventListener(Event.CONTEXT3D_CREATE, init3D);
			stage3D.addEventListener(Event.CONTEXT3D_CREATE, handleContextLoss);
			
			scene = new Object3D();
			addChildAt(camera.view, 0);
			Jehovah.camera = camera;
			Jehovah.scene = scene;
			Jehovah.context3D = stage3D.context3D;
			Jehovah.context3D.enableErrorChecking = true;
			Jehovah.enableCollisionDetection = true;
			camera.view.updateDriverInfo(Jehovah.context3D.driverInfo);
			
			initMaterial();
			initScene();
		}
		private function handleContextLoss(evt:Event):void
		{
			trace("handle context loss.");
			/*
			Stage3D content doesn't render correctly after device rotation or screen saver
			
			Issue
			When you view Stage3D content, you sometimes see rendering errors, a black screen, or what appears to be a frozen screen. This issue is known as device loss. Device loss occurs when the underlying window or GPU resource Flash is using to render with is re-created. On Windows desktop, this issue occurs anytime you press CTRL+ALT+DEL or the screen saver kicks in. On Android devices, this issue occurs anytime you rotate the device (if the orientation is not locked).
			
			Note: On the Kindle Fire or the Galaxy S2, this issue can occur during normal app startup. Device loss can also occur on Android when coming back to an application that had been put in the background.
			
			Solution
			When device loss occurs, a new CONTEXT3D_CREATE event is dispatched to let the content know that the GPU context has changed. All of the Textures, vertexBuffers, indexBuffers that you have created through Stage3D commands before this event have now become invalid. They belonged to the previous Context3D, which as been lost or disposed. To recover from device loss, re-create any textures, vertex buffers, and index buffers you are still using after you receive a CONTEXT3D_CREATE event.
			*/
			if(!stage3D.context3D || stage3D.context3D.driverInfo == "Disposed")
				return ;
			if(Jehovah.context3D) //if Jehovah.context3D is not null, it means the 3d scene has already builded. The old context3d is disposed by context3d loss. re-create resource by the new context3d, using resource.upload() methord.
			{
				Jehovah.context3D = stage3D.context3D;
				Jehovah.context3D.enableErrorChecking = true;
				camera.configBackBufferNeeded = true;
				camera.context3DProperty.sourceFactor = null;
				camera.context3DProperty.destinationFactor = null;
				camera.context3DProperty.culling = null;
				scene.uploadResource(Jehovah.context3D);
				if(camera)
					camera.view.updateDriverInfo(Jehovah.context3D.driverInfo);
				return ;
			}
		}
		private function onRemove(evt:Event = null):void
		{
			removeEventListener(Event.REMOVED_FROM_STAGE, onRemove);
			removeEventListener(Event.RESIZE, onResize);
			dispose();
		}
		public function dispose():void
		{
			if(numChildren > 0)
				removeChildren(0, numChildren - 1);
			if(stage3D.context3D)
			{
				stage3D.context3D.clear(1, 1, 1, 1);
				stage3D.context3D.present();
			}
			if(camera)
			{
				camera.dispose();
				camera = null;
			}
			if(stage3D)
			{
				if(stage3D.hasEventListener(Event.CONTEXT3D_CREATE))
					stage3D.removeEventListener(Event.CONTEXT3D_CREATE, init3D);
				if(stage3D.hasEventListener(Event.CONTEXT3D_CREATE))
					stage3D.removeEventListener(Event.CONTEXT3D_CREATE, handleContextLoss);
				stage3D = null;
			}
			scene.removeAllChild();
			scene.dispose();
			scene = null;
			Jehovah.dispose();
			AssetsManager.dispose();
		}
		public function onResize(evt:Event):void
		{
			if(stage.stageWidth > 0 && stage.stageHeight > 0)
			{
				if(camera)
				{
					camera.viewWidth = stage.stageWidth;
					camera.viewHeight = stage.stageHeight;
					var pos:Point = localToGlobal(new Point(0, 0));
					stage3D.x = pos.x;
					stage3D.y = pos.y;
				}
			}
		}
		public function initCamera():void
		{
			
		}
		public function initMaterial():void
		{
			
		}
		public function initScene():void
		{
			
		}
	}
}