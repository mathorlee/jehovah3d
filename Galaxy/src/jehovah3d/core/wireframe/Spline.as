package jehovah3d.core.wireframe
{
	import flash.geom.Vector3D;
	
	import mx.utils.UIDUtil;
	
	import jehovah3d.core.Object3D;
	import jehovah3d.util.HexColor;
	
	public class Spline extends Object3D
	{
		public static const VERTEX_SEGMENT_SELECTED_COLOR:HexColor = new HexColor(0xFF0000, 1); //顶点和边被选中的颜色。
		public static const VERTEX_UNSELECTED_COLOR:HexColor = new HexColor(0xFFFF00); //顶点的默认颜色。
		public static const ALL_SELECTED:HexColor = new HexColor(0xFFFFFF, 1); //spline全部被选中的颜色。
		public var allUnselected:HexColor = new HexColor(0x0000FF); //spline的默认颜色。
		
		private var _points:Vector.<Vector3D> = new Vector.<Vector3D>(); //points。
		private var _edges:Vector.<int> = new Vector.<int>(); //Edge<startPointIndex, stopPointIndex>。
		
		private var _vertices:Vector.<Vertex> = new Vector.<Vertex>(); //点。
		private var _segments:Vector.<Segment> = new Vector.<Segment>(); //边。
		
		private var _isVertexSelected:Vector.<Boolean>; //点是否是选中状态。
		private var _isSegmentSelected:Vector.<Boolean>; //边是否是选中状态。
		
		public function Spline(points:Vector.<Vector3D>, edges:Vector.<int>)
		{
			name = UIDUtil.createUID();
			_points = points.slice();
			_edges = edges.slice();
			var i:int;
			var segment:Segment;
			for(i = 0; i < _edges.length / 2; i ++)
			{
				segment = new Segment(Vector.<Vector3D>([points[_edges[i * 2]], points[_edges[2 * i + 1]]]), 0x0000FF, 2);
				_segments.push(segment);
				addChild(segment);
			}
			_isSegmentSelected = new Vector.<Boolean>(_edges.length / 2);
			
			var vertex:Vertex;
			for(i = 0; i < _points.length; i ++)
			{
				vertex = new Vertex(_points[i], 8);
				vertex.visible = false;
				_vertices.push(vertex);
				addChild(vertex);
			}
			_isVertexSelected = new Vector.<Boolean>(_edges.length / 2);
		}
		
		public function get points():Vector.<Vector3D>
		{
			return _points;
		}
		public function get vertices():Vector.<Vertex>
		{
			return _vertices;
		}
		public function get segments():Vector.<Segment>
		{
			return _segments;
		}
		
		override public function set isSelected(value:Boolean):void
		{
			if(_isSelected != value)
			{
				_isSelected = value;
				var i:int;
				for(i = 0; i < _vertices.length; i ++)
					_vertices[i].updateColor();
				for(i = 0; i < _segments.length; i ++)
					_segments[i].updateColor();
			}
		}
		
		/**
		 * 拖拽复制一个segment，添加这个segment。 
		 * @param seg
		 * 
		 */		
		public function addSegment(seg:Segment):void
		{
			//更新_points
			_points.push(seg.vertexList[0]);
			_points.push(seg.vertexList[1]);
			
			//添加2个Vertex
			var v0:Vertex = new Vertex(seg.vertexList[0], 8);
			var v1:Vertex = new Vertex(seg.vertexList[1], 8);
			_vertices.push(v0);
			_vertices.push(v1);
			addChild(v0);
			addChild(v1);
			
			//添加seg
			_segments.push(seg);
			addChild(seg);
		}
	}
}