package jehovah3d.core.wireframe
{
	import flash.geom.Vector3D;
	
	import jehovah3d.util.HexColor;

	public class LineData
	{
		private var _v0:Vector3D;
		private var _v1:Vector3D;
		private var _color:HexColor;
		
		public function LineData(v0:Vector3D, v1:Vector3D)
		{
			_v0 = v0;
			_v1 = v1;
		}
		
		public function get v0():Vector3D
		{
			return _v0;
		}
		public function get v1():Vector3D
		{
			return _v1;
		}
		
		public function get color():HexColor
		{
			return _color;
		}
		
		public function set color(value:HexColor):void
		{
			_color = value;
		}
		
	}
}