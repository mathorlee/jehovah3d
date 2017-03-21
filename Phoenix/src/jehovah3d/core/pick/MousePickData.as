package jehovah3d.core.pick
{
	import flash.geom.Vector3D;
	
	import jehovah3d.core.Object3D;
	import jehovah3d.core.mesh.lattice.SUEdge;
	import jehovah3d.core.mesh.lattice.SUVertex;

	/**
	 * 鼠标拾取的数据
	 * @author lisongsong
	 * 
	 */	
	public class MousePickData
	{
		//单吸附
		public static const ATTACH_TYPE_VERTEX:String = "ATTACH_TYPE_VERTEX"; //vertex
		public static const ATTACH_TYPE_EDGE:String = "ATTACH_TYPE_EDGE"; //edge
		public static const ATTACH_TYPE_MESH:String = "ATTACH_TYPE_MESH"; //mesh
		public static const ATTACH_TYPE_AXIS:String = "ATTACH_TYPE_AXIS"; //axis
		
		//双吸附
		public static const ATTACH_TYPE_AXIS_AND_VERTEX:String = "ATTACH_TYPE_AXIS_AND_VERTEX"; //axis&vertex
		public static const ATTACH_TYPE_AXIS_AND_EDGE:String = "ATTACH_TYPE_AXIS_AND_EDGE"; //axis&edge
		public static const ATTACH_TYPE_AXIS_AND_MESH:String = "ATTACH_TYPE_AXIS_AND_MESH"; //axis&mesh
		
		public var attachVertex:SUVertex;
		public var attachEdge:SUEdge;
		public var attachMesh:Object3D;
		public var attachAxis:String;
		
		private var _dist:Number; //距离
		private var _position:Vector3D; //位置
		private var _normal:Vector3D; //法线
		
		public var isPenetrable:Boolean = false;
		
		public function MousePickData(dist:Number, position:Vector3D = null, normal:Vector3D = null)
		{
			_dist = dist;
			_position = position;
			_normal = normal;
		}
		
		/**
		 * 判断是否是单吸附
		 * @return 
		 * 
		 */		
		public function get isSingleAttach():Boolean
		{
			return (
				this.attachType == ATTACH_TYPE_VERTEX || 
				this.attachType == ATTACH_TYPE_EDGE || 
				this.attachType == ATTACH_TYPE_MESH || 
				this.attachType == ATTACH_TYPE_AXIS
			);
		}
		
		/**
		 * 判断是否是双吸附
		 * @return 
		 * 
		 */		
		public function get isDoubleAttach():Boolean
		{
			return (
				this.attachType == ATTACH_TYPE_AXIS_AND_VERTEX || 
				this.attachType == ATTACH_TYPE_AXIS_AND_EDGE || 
				this.attachType == ATTACH_TYPE_AXIS_AND_MESH
			);
		}
		
		public function get attachType():String
		{
			if (this.attachAxis)
			{
				if (this.attachVertex) return ATTACH_TYPE_AXIS_AND_VERTEX;
				if (this.attachEdge) return ATTACH_TYPE_AXIS_AND_EDGE;
				if (this.attachMesh) return ATTACH_TYPE_AXIS_AND_MESH;
				return ATTACH_TYPE_AXIS;
			}
			
			if (this.attachVertex) return ATTACH_TYPE_VERTEX;
			if (this.attachEdge) return ATTACH_TYPE_EDGE;
			if (this.attachMesh) return ATTACH_TYPE_MESH;
			return null;
		}
		
		
		/**
		 * 距离。
		 * @return 
		 * 
		 */		
		public function get dist():Number
		{
			return _dist;
		}
		
		/**
		 * 坐标。
		 * @return 
		 * 
		 */		
		public function get position():Vector3D
		{
			return _position;
		}
		
		public function get normal():Vector3D
		{
			return _normal;
		}
		
		public function dispose():void
		{
			attachVertex = null;
			attachEdge = null;
			attachMesh = null;
			attachAxis = null;
			_position = null;
			_normal = null;
		}
		
		public function output():void
		{
			var str:String = "";
			str += this.attachType;
			if (this.attachAxis)
				str += ":" + this.attachAxis;
			if (this.attachMesh)
				str += ":" + this.attachMesh;
			str += " " + dist + " " + position;
			trace(str);
		}
		
		public function clone():MousePickData
		{
			var ret:MousePickData = new MousePickData(this._dist, this._position, this._normal);
			ret.attachVertex = this.attachVertex;
			ret.attachEdge = this.attachEdge;
			ret.attachMesh = this.attachMesh;
			ret.attachAxis = this.attachAxis;
			return ret;
		}
		public function get object():Object3D
		{
			return attachMesh;
		}
	}
}