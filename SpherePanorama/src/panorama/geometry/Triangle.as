package panorama.geometry
{
	import flash.geom.Point;

	public class Triangle
	{
		public function Triangle(va:Vertex, vb:Vertex, vc:Vertex)
		{
			_va = va;
			_vb = vb;
			_vc = vc;
			lengthAB = _vb.position.subtract(_va.position).length;
			lengthBC = _vc.position.subtract(_vb.position).length;
			lengthCA = _va.position.subtract(_vc.position).length;
			uvAB = _vb.uv.subtract(_va.uv);
			uvBC = _vc.uv.subtract(_vb.uv);
			uvCA = _va.uv.subtract(_vc.uv);
		}
		
		
		public function clone():Triangle
		{
			return new Triangle(_va.clone(), _vb.clone(), _vc.clone());
		}
		
		public var lengthAB:Number;
		public var lengthBC:Number;
		public var lengthCA:Number;
		public var uvAB:Point;
		public var uvBC:Point;
		public var uvCA:Point;
		
		
		private var _va:Vertex;
		public function get va():Vertex { return _va; }
		
		public function set va(value:Vertex):void
		{
			if (_va == value)
				return;
			_va = value;
		}
		
		private var _vb:Vertex;
		public function get vb():Vertex { return _vb; }
		
		public function set vb(value:Vertex):void
		{
			if (_vb == value)
				return;
			_vb = value;
		}
		
		private var _vc:Vertex;
		public function get vc():Vertex { return _vc; }
		
		public function set vc(value:Vertex):void
		{
			if (_vc == value)
				return;
			_vc = value;
		}
		
		
	}
}