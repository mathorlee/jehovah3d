package jehovah3d.core.pick
{
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;

	public class RayGeometryIntersection
	{
		private var _dist:Number;
		private var _position:Vector3D;
		private var _normal:Vector3D;
		private var _uv:Point;
		public function RayGeometryIntersection(dist:Number, position:Vector3D, normal:Vector3D, uv:Point)
		{
			_dist = dist;
			_position = position;
			_normal = normal;
			_uv = uv;
		}
		
		public function get dist():Number
		{
			return _dist;
		}
		public function get position():Vector3D
		{
			return _position;
		}
		public function get normal():Vector3D
		{
			return _normal;
		}
		public function get uv():Point
		{
			return _uv;
		}
		public function set matrix(value:Matrix3D):void
		{
			_position = value.transformVector(_position);
			_normal = value.deltaTransformVector(_normal);
		}
	}
}