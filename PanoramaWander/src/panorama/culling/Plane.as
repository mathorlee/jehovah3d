package panorama.culling
{
	import flash.geom.Vector3D;
	
	import panorama.geometry.Triangle;

	public class Plane
	{
		public function Plane(p0:Vector3D, dir:Vector3D)
		{
			_p0 = p0.clone();
			_dir = dir.clone();
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
		
		public function whichSideIsPointAt(point:Vector3D):Boolean
		{
			var v1:Vector3D = point.subtract(_p0);
			v1.normalize();
			return v1.dotProduct(_dir) >= 0;
		}
	}
}