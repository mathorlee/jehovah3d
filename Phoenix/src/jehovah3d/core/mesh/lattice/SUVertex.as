package jehovah3d.core.mesh.lattice
{
	import flash.geom.Vector3D;
	
	import jehovah3d.Jehovah;
	import jehovah3d.util.HexColor;

	/**
	 * 晶格“点”的类。
	 * @author lisongsong
	 * 
	 */	
	public class SUVertex
	{
		protected var _position:Vector3D = new Vector3D(); //坐标
		protected var _cameraSpacePositon:Vector3D = new Vector3D(); //相机空间的坐标
		public var thickness:Number = LatticeMesh.DEFAULT_VERTEX_THICKNESS;
		public var color:HexColor; //顶点颜色
		public var culled:Boolean = false; //是否被视锥剔除。若为true则在视锥外不可见。
		public var parent:LatticeMesh; //父容器
		public var degree:int = 0; //节点的度
		public var visible:Boolean = false; //顶点是否可见
		
		public function SUVertex(position:Vector3D)
		{
			_position = position;
		}
		
		public function get position():Vector3D
		{
			return _position;
		}
		public function set position(value:Vector3D):void
		{
			_position.copyFrom(value);
		}
		public function get cameraSpacePositon():Vector3D
		{
			return _cameraSpacePositon;
		}
		public function set cameraSpacePositon(value:Vector3D):void
		{
			_cameraSpacePositon.copyFrom(value);
		}
		
		public function dispose():void
		{
			_position = null;
			_cameraSpacePositon = null;
			color = null;
			parent = null;
		}
		
		public function update():void
		{
			cameraSpacePositon = parent.localToCameraMatrix.transformVector(position);
			culled = (cameraSpacePositon.z >= -Jehovah.camera.zNear);
		}
		
		/**
		 * 返回顶点的所有边。
		 * @return 
		 * 
		 */		
		public function get edges():Vector.<SUEdge>
		{
			var ret:Vector.<SUEdge> = new Vector.<SUEdge>();
			for each (var edge:SUEdge in parent.edges)
			{
				if (edge.vertex0 == this || edge.vertex1 == this)
					ret.push(edge);
			}
			return ret;
		}
		
		/**
		 * 更新顶点的度。
		 * 
		 */		
		public function updateDegree():void
		{
			degree = edges.length;
		}
		
		/**
		 * 保存为Object
		 * @return 
		 * 
		 */		
		public function toObject():Object
		{
			return {"x": position.x, "y": position.y, "z": position.z};
		}
	}
}