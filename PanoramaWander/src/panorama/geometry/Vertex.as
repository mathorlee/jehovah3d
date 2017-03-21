package panorama.geometry
{
	import flash.geom.Point;
	import flash.geom.Vector3D;

	public class Vertex
	{
		public function Vertex(position:Vector3D, uv:Point)
		{
			_position = position;
			_uv = uv;
		}
		
		
		public function clone():Vertex
		{
			return new Vertex(_position.clone(), _uv.clone());
		}
		
		private var _position:Vector3D;
		public function get position():Vector3D { return _position; }
		
		public function set position(value:Vector3D):void
		{
			if (_position == value)
				return;
			_position = value.clone();
		}
		
		private var _uv:Point;
		public function get uv():Point { return _uv; }
		
		public function set uv(value:Point):void
		{
			if (_uv == value)
				return;
			_uv = value.clone();
		}
		
	}
}