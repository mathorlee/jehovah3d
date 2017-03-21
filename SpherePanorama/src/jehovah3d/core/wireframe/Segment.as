package jehovah3d.core.wireframe
{
	import flash.geom.Vector3D;
	
	import mx.utils.UIDUtil;
	
	public class Segment extends WireFrame
	{
		public function Segment(vertexList:Vector.<Vector3D>, color:uint, thickness:Number)
		{
			super(vertexList, color, thickness);
			name = UIDUtil.createUID();
		}
		
		public function get spline():Spline
		{
			return parent as Spline;
		}
		
		override public function set position(value:Vector3D):void
		{
			var i:int;
			for(i = 0; i < _vertexList.length; i ++)
			{
				_vertexList[i].x += value.x;
				_vertexList[i].y += value.y;
				_vertexList[i].z += value.z;
			}
		}
		
		override public function set isSelected(value:Boolean):void
		{
			_isSelected = value;
			updateColor();
		}
		
		public function updateColor():void
		{
			if(_isSelected)
			{
				color = Spline.VERTEX_SEGMENT_SELECTED_COLOR;
			}
			else
			{
				if(spline.isSelected)
					color = Spline.ALL_SELECTED;
				else
					color = spline.allUnselected;
			}
		}
		
		public function clone():Segment
		{
			var v0:Vector3D = _vertexList[0].clone();
			var v1:Vector3D = _vertexList[1].clone();
			var seg:Segment = new Segment(Vector.<Vector3D>([v0, v1]), 0x0000FF, 2);
			return seg;
		}
	}
}