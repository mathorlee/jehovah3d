package jehovah3d.core.pick
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class Line
	{
		private var _p0:Vector3D;
		private var _dir:Vector3D;
		
		public function Line(p0:Vector3D, dir:Vector3D)
		{
			_p0 = p0;
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
		public function clone():Line
		{
			return new Line(_p0.clone(), _dir.clone());
		}
		
		/**
		 * 返回line在新的坐标系下的表示。 
		 * @param matrix
		 * @return 
		 * 
		 */		
		public function transform(matrix:Matrix3D):Line
		{
			return new Line(matrix.transformVector(_p0), matrix.deltaTransformVector(_dir));
		}
	}
}