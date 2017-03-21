package jehovah3d.controller
{
	import jehovah3d.core.Object3D;

	public class SelectManager
	{
		private var _target:Object3D;
		
		public function SelectManager()
		{
			
		}
		
		public function get target():Object3D
		{
			return _target;
		}
		public function set target(value:Object3D):void
		{
			if(_target != value)
			{
				if(_target)
					_target.isSelected = false;
				_target = value;
				if(_target)
					_target.isSelected = true;
			}
		}
	}
}