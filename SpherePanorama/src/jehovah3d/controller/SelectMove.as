package jehovah3d.controller
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.Object3D;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.pick.Plane;
	import jehovah3d.core.wireframe.WireFrame;
	
	/**
	 * 3ds max QWER。W：Select And Move。 
	 * @author lisongsong
	 * 
	 */	
	public class SelectMove extends Object3D
	{
		public static const NAME_XAXIS:String = "xAxis";
		public static const NAME_YAXIS:String = "yAxis";
		public static const NAME_ZAXIS:String = "zAxis";
		
		public static const DIR_X:int = 0;
		public static const DIR_Y:int = 1;
		public static const DIR_Z:int = 2;
		public var moveDir:int = 0;
		
		private var _dimension:Number;
		private var _xAxis:WireFrame;
		private var _yAxis:WireFrame;
		private var _zAxis:WireFrame;
		private var _movingTarget:Object3D; //被移动的物体。
		public var movingPlane:Plane; //射线和movingPlane相交，得到位移。
		
		public function SelectMove(dimension:Number)
		{
			_dimension = dimension;
			
			_xAxis = new WireFrame(Vector.<Vector3D>([
				new Vector3D(_dimension * 0.25, 0, 0), 
				new Vector3D(_dimension, 0, 0)
			]), 0xFF0000, 2);
			_xAxis.name = NAME_XAXIS;
			_xAxis.renderType = Mesh.LAST_ALWAYSE;
			_xAxis.mouseEnabled = true;
			addChild(_xAxis);
			
			_yAxis = new WireFrame(Vector.<Vector3D>([
				new Vector3D(0, _dimension * 0.25, 0), 
				new Vector3D(0, _dimension, 0)
			]), 0x00FF00, 2);
			_yAxis.name = NAME_YAXIS;
			_yAxis.renderType = Mesh.LAST_ALWAYSE;
			_yAxis.mouseEnabled = true;
			addChild(_yAxis);
			
			_zAxis = new WireFrame(Vector.<Vector3D>([
				new Vector3D(0, 0, _dimension * 0.25), 
				new Vector3D(0, 0, _dimension)
			]), 0x0000FF, 2);
			_zAxis.name = NAME_ZAXIS;
			_zAxis.renderType = Mesh.LAST_ALWAYSE;
			_zAxis.mouseEnabled = true;
			addChild(_zAxis);
			actAsGroup = true;
		}
		
		override public function updateHierarchyMatrix_CameraFinal():void
		{	
			//localToCameraMatrix
			var ltc:Matrix3D = localToGlobalMatrix.clone();
			ltc.append(Jehovah.camera.noScaleInverseMatrix);
			var cameraSpacePoint:Vector3D  = ltc.transformVector(new Vector3D(0, 0, 0));
			
			var d:Number;
			if(-cameraSpacePoint.z < Jehovah.camera.zNear)
				d = 0;
			else
			{
				if(Jehovah.camera.orthographic)
					d = _dimension;
				else
					d = _dimension * (-cameraSpacePoint.z) / Jehovah.camera.focalLength;
			}
			
			_xAxis.vertexList = Vector.<Vector3D>([
				new Vector3D(d * 0.25, 0, 0), 
				new Vector3D(d, 0, 0)
			]);
			_yAxis.vertexList = Vector.<Vector3D>([
				new Vector3D(0, d * 0.25, 0), 
				new Vector3D(0, d, 0)
			]);
			_zAxis.vertexList = Vector.<Vector3D>([
				new Vector3D(0, 0, d * 0.25), 
				new Vector3D(0, 0, d)
			]);
			
			super.updateHierarchyMatrix_CameraFinal();
		}
		
		public function get movingTarget():Object3D
		{
			return _movingTarget;
		}
		public function set movingTarget(value:Object3D):void
		{
			if(_movingTarget != value)
			{
				_movingTarget = value;
			}
		}
		
		override public function toString():String
		{
			return "[SelectMove:" + name + "]";
		}
	}
}