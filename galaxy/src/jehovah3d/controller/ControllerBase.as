package jehovah3d.controller
{
	import flash.display.InteractiveObject;
	
	import jehovah3d.core.Camera3D;
	import jehovah3d.core.Object3D;

	public class ControllerBase
	{
		protected var _target:Object3D;
		protected var _camera:Camera3D;
		protected var _interactiveObject:InteractiveObject;
		//yaw pitch roll 左右、上下、中轴转
		public function ControllerBase(target:Object3D, camera:Camera3D, interactiveObject:InteractiveObject)
		{
			_target = target;
			_camera = camera;
			_interactiveObject = interactiveObject;
		}
		
		public function dispose():void
		{
			if(_target)
				_target = null;
			if(_camera)
				_camera = null;
			if(_interactiveObject)
				_interactiveObject = null;
		}
	}
}