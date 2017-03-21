package jehovah3d.core.mesh.lattice
{
	import jehovah3d.Jehovah;
	import jehovah3d.util.HexColor;

	import com.fuwo.math.MyMath;
	import com.fuwo.math.Plane;
	import com.fuwo.math.Ray3D;

	import flash.geom.Vector3D;

	/**
	 * 晶格“边”的类。
	 * @author lisongsong
	 * 
	 */	
	public class SUEdge
	{
		private var _vertex0:SUVertex;
		private var _vertex1:SUVertex;
		public var thickness:Number = LatticeMesh.DEFAULT_EDGE_THICKNESS;
		public var color:HexColor;
		public var cameraSpaceVertex0:Vector3D;
		public var cameraSpaceVertex1:Vector3D;
		public var culled:Boolean = false; //是否被视锥剔除。若为true则在视锥外不可见。
		public var showRenderingLine:Boolean = true; //是否显示表示边的细线。默认显示。
		
		public var parent:LatticeMesh; //父容器
		
		public function SUEdge(vertex0:SUVertex, vertex1:SUVertex)
		{
			_vertex0 = vertex0;
			_vertex1 = vertex1;
			cameraSpaceVertex0 = new Vector3D();
			cameraSpaceVertex1 = new Vector3D();
		}
		
		public function get vertex0():SUVertex
		{
			return _vertex0;
		}
		public function set vertex0(value:SUVertex):void
		{
			_vertex0 = value;
		}
		public function get vertex1():SUVertex
		{
			return _vertex1;
		}
		public function set vertex1(value:SUVertex):void
		{
			_vertex1 = value;
		}
		
		public function dispose():void
		{
			_vertex0 = null;
			_vertex1 = null;
			color = null;
			cameraSpaceVertex0 = null;
			cameraSpaceVertex1 = null;
			parent = null;
		}
		
		public function get length():Number
		{
			return vertex0.position.subtract(vertex1.position).length;
		}
		
		public function update():void
		{
			if (!thickness || !color)
				throw new Error("SUEdge的thickness或color为空！");
			
			var v1:Vector3D;
			var v2:Vector3D;
			var s1:Number;
			var s2:Number;
			var plane:Plane = new Plane(new Vector3D(0, 0, -Jehovah.camera.zNear), new Vector3D(0, 0, -1));
			
			cameraSpaceVertex0.copyFrom(vertex0.cameraSpacePositon.clone());
			cameraSpaceVertex1.copyFrom(vertex1.cameraSpacePositon.clone());
			
			v1 = cameraSpaceVertex0;
			v2 = cameraSpaceVertex1;
			s1 = plane.whichSideIsPointAt(v1);
			s2 = plane.whichSideIsPointAt(v2);
			culled = (s1 < 1 && s2 < 1);
			if (culled)
				return ;
			
			if (s1 * s2 < 0)
			{
				var dir:Vector3D = v2.subtract(v1);
				dir.normalize();
				var ray:Ray3D = new Ray3D(v1, dir);
				var intersect:Object = MyMath.rayPlaneIntersect(ray, plane);
				if(s1 > 0)
					v2.copyFrom(intersect.point);
				else if(s2 > 0)
					v1.copyFrom(intersect.point);
			}
		}
		
		public function get cameraSpaceRay():Ray3D
		{
			var dir:Vector3D = cameraSpaceVertex1.subtract(cameraSpaceVertex0);
			dir.normalize();
			return new Ray3D(cameraSpaceVertex0, dir);
		}
		
		/**
		 * 中点
		 * @return 
		 * 
		 */		
		public function get centerPoint():Vector3D
		{
			var ret:Vector3D = _vertex0.position.add(_vertex1.position);
			ret.scaleBy(0.5);
			return ret;
		}
		
		/**
		 * 更新颜色
		 * 
		 */		
		public function updateColor():void
		{
			//do nothing
		}
		
		/**
		 * 更新直径
		 * 
		 */		
		public function updateRadius():void
		{
			//do nothing
		}
		
		/**
		 * 删除选中的边
		 * 
		 */		
		public function doDelete():void
		{
			parent.doDeleteEdge(this);
		}
		
		/**
		 * 设定起始顶点，返回边的单位向量。
		 * @param startVertex
		 * @return 
		 * 
		 */		
		public function getDirByStartVertex(startVertex:SUVertex):Vector3D
		{
			var ret:Vector3D = (startVertex == vertex0 ? vertex1.position.subtract(vertex0.position) : vertex0.position.subtract(vertex1.position));
			ret.normalize();
			return ret;
		}
		
		/**
		 * 拷贝边的属性。
		 * @param another
		 * 
		 */		
		public function copyAttributeFromAnotherEdge(another:SUEdge):void
		{
			this.thickness = another.thickness;
			this.color = another.color;
			this.showRenderingLine = another.showRenderingLine;
			this.parent = another.parent;
		}
		
		/**
		 * 保存为Object
		 * @return 
		 * 
		 */		
		public function toObject():Object
		{
			var ret:Object = {};
			ret.startIndex = parent.getVertexIndex(_vertex0);
			ret.stopIndex = parent.getVertexIndex(_vertex1);
			ret.color = color.hexColor;
			return ret;
		}
	}
}