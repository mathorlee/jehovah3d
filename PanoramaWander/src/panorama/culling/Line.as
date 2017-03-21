package panorama.culling
{
	import flash.geom.Vector3D;

	public class Line
	{
//		public function Line(p0:Vector3D, dir:Vector3D)
//		{
//			_p0 = p0.clone();
//			_dir = dir.clone();
//		}
		
		public function Line(p0:Vector3D, p1:Vector3D)
		{
			_p0 = p0.clone();
			_dir = p1.subtract(p0);
			if(_dir.length > 0.001)
				_dir.normalize();
		}
		
		
		private var _p0:Vector3D;
		public function get p0():Vector3D { return _p0; }
		
		public function set p0(value:Vector3D):void
		{
			if (_p0 == value)
				return;
			_p0 = value.clone();
		}
		
		private var _dir:Vector3D;
		public function get dir():Vector3D { return _dir; }
		
		public function set dir(value:Vector3D):void
		{
			if (_dir == value)
				return;
			_dir = value.clone();
		}
	}
}