package jehovah3d.core.pick
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class Ray
	{
		private var _p0:Vector3D;
		private var _p1:Vector3D;
		private var _dir:Vector3D;
		public var length:Number = Number.MAX_VALUE;
		/**
		 * Line/Ray. 
		 * @param p0: Start Point of Line.
		 * @param dir: Direction of Ray. Normalized vector.
		 * 
		 */		
		public function Ray(p0:Vector3D, dir:Vector3D)
		{
			_p0 = p0;
			_p1 = new Vector3D(p0.x + dir.x * 1, p0.y + dir.y * 1, p0.z + dir.z * 1);
			_dir = dir;
		}
		
		/**
		 * start point of ray. 
		 * @return 
		 * 
		 */		
		public function get p0():Vector3D
		{
			return _p0;
		}
		
		public function get p1():Vector3D
		{
			return _p1;
		}
		
		/**
		 * direction of ray, normalized vector. 
		 * @return 
		 * 
		 */		
		public function get dir():Vector3D
		{
			return _dir;
		}
		
		/**
		 * return a clone of itself. 
		 * @return 
		 * 
		 */		
		public function clone():Ray
		{
			var copy:Ray = new Ray(_p0.clone(), _p1.clone());
			copy.length = length;
			return copy;
		}
		
		/**
		 * 返回ray在新的坐标系下的表示。 
		 * @param matrix
		 * @return 
		 * 
		 */		
		public function transform(matrix:Matrix3D):Ray
		{
			return new Ray(matrix.transformVector(_p0), matrix.deltaTransformVector(_dir));
		}
	}
}