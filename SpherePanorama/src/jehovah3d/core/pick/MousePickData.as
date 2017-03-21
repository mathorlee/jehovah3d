package jehovah3d.core.pick
{
	import flash.geom.Vector3D;

	public class MousePickData
	{
		private var _object:Object;
		private var _dist:Number;
		private var _position:Vector3D;
		public var isPenetrable:Boolean = false; //是否可穿透
		
		/**
		 * RayIntersectionData. 
		 * @param target
		 * @param dist
		 * 
		 */		
		public function MousePickData(target:Object, dist:Number, position:Vector3D = null)
		{
			_object = target;
			_dist = dist;
			if (position)
				_position = position;
		}
		
		/**
		 * 物体。
		 * @return 
		 * 
		 */		
		public function get object():Object
		{
			return _object;
		}
		
		/**
		 * 距离。
		 * @return 
		 * 
		 */		
		public function get dist():Number
		{
			return _dist;
		}
		
		/**
		 * 坐标。
		 * @return 
		 * 
		 */		
		public function get position():Vector3D
		{
			return _position;
		}
		
		public function clear():void
		{
			_object = null;
			_position = null;
		}
		
		public function output():void
		{
			trace(this.object, this.dist, this.position);
		}
	}
}