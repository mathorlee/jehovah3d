package jehovah3d.core.pick
{
	import jehovah3d.core.Object3D;

	public class MousePickData
	{
		private var _object:Object3D; //groupAncestor
		private var _rayDetectiveObject:Object3D; //射线检测相交的物体
		private var _dist:Number;
		
		/**
		 * RayIntersectionData. 
		 * @param target
		 * @param dist
		 * 
		 */		
		public function MousePickData(target:Object3D, rayDetectiveObject:Object3D, dist:Number)
		{
			_object = target;
			_rayDetectiveObject = rayDetectiveObject;
			_dist = dist;
		}
		
		/**
		 * target. 
		 * @return 
		 * 
		 */		
		public function get object():Object3D
		{
			return _object;
		}
		public function get rayDetectiveObject():Object3D
		{
			return _rayDetectiveObject;
		}
		
		/**
		 * dist. 
		 * @return 
		 * 
		 */		
		public function get dist():Number
		{
			return _dist;
		}
		
		private var _isPenetrable:Boolean = false;
		public function get isPenetrable():Boolean { return _isPenetrable; }
		
		public function set isPenetrable(value:Boolean):void
		{
			if (_isPenetrable == value)
				return;
			_isPenetrable = value;
		}
		
		public function clear():void
		{
			if(_object)
				_object = null;
			if(_rayDetectiveObject)
				_rayDetectiveObject = null;
		}
	}
}