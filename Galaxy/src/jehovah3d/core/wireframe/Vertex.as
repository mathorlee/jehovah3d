package jehovah3d.core.wireframe
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import mx.utils.UIDUtil;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.material.DiffuseMtl;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.pick.MousePickData;
	import jehovah3d.core.pick.MousePickManager;
	import jehovah3d.core.pick.Ray;
	import jehovah3d.core.resource.GeometryResource;
	import jehovah3d.util.HexColor;
	
	public class Vertex extends Mesh
	{
		public static var CLOSER_TO_CAMERA:Number = 10;
		private var _point:Vector3D;
		private var _dimension:Number;
		private var _cameraSpacePoint:Vector3D;
		
		public function Vertex(point:Vector3D, dimension:Number)
		{
			name = UIDUtil.createUID();
			_point = point;
			_dimension = dimension;
			_geometry = new GeometryResource();
			_geometry.coordinateData = Vector.<Number>([_point.x, _point.y, _point.z, _point.x, _point.y, _point.z, _point.x, _point.y, _point.z, _point.x, _point.y, _point.z]);
			_geometry.indexData = Vector.<uint>([0, 1, 2, 0, 2, 3]);
			_geometry.upload(Jehovah.context3D);
			
			_mtl = new DiffuseMtl();
			_mtl.diffuseColor = Spline.VERTEX_UNSELECTED_COLOR;
			_mtl.culling = "none";
		}
		
		override public function updateHierarchyMatrix():void
		{
			super.updateHierarchyMatrix();
			
			//localToCameraMatrix
			var ltc:Matrix3D = localToGlobalMatrix.clone();
			ltc.append(Jehovah.camera.noScaleInverseMatrix);
			_cameraSpacePoint = ltc.transformVector(_point);
			
			var d:Number;
			if(-_cameraSpacePoint.z < Jehovah.camera.zNear)
				d = 0;
			else
			{
				if(Jehovah.camera.orthographic)
					d = _dimension;
				else
					d = _dimension * (-_cameraSpacePoint.z) / Jehovah.camera.focalLength;
			}
			
			var coordinateData:Vector.<Number> = new Vector.<Number>();
			var i:int;
			var v0:Vector3D = new Vector3D();
			for(i = 0; i < 4; i ++)
			{
				if(i == 0 || i == 3)
					v0.x = _cameraSpacePoint.x + d * 0.5;
				else
					v0.x = _cameraSpacePoint.x - d * 0.5;
				if(i == 0 || i == 1)
					v0.y = _cameraSpacePoint.y + d * 0.5;
				else
					v0.y = _cameraSpacePoint.y - d * 0.5;
				v0.z = _cameraSpacePoint.z;
				v0 = globalToLocalMatrix.transformVector(Jehovah.camera.matrix.transformVector(v0));
				coordinateData.push(v0.x, v0.y, v0.z);
			}
			_geometry.coordinateData = coordinateData;
			_geometry.upload(Jehovah.context3D);
		}
		
		public function get spline():Spline
		{
			return parent as Spline;
		}
		public function get point():Vector3D
		{
			return _point;
		}
		
		override public function set position(value:Vector3D):void
		{
			_point.x += value.x;
			_point.y += value.y;
			_point.z += value.z;
		}
		
		public function get color():HexColor
		{
			return _mtl.diffuseColor;
		}
		public function set color(value:HexColor):void
		{
			_mtl.diffuseColor = value;
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
				visible = true;
			}
			else
			{
				if(spline.isSelected)
				{
					color = Spline.VERTEX_UNSELECTED_COLOR;
					visible = true;
				}
				else
				{
					color = Spline.VERTEX_UNSELECTED_COLOR;
					visible = false;
				}
			}
		}
		
		override public function mousePick(ray:Ray):void
		{
			if(!mouseEnabled || !visible)
				return ;
			var rayCopy:Ray = new Ray(globalToLocalMatrix.transformVector(ray.p0), globalToLocalMatrix.deltaTransformVector(ray.dir));
			var dist:Number = _geometry.calculateIntersectionDist(rayCopy);
			if(dist)
				MousePickManager.add(new MousePickData(this.groupAncestor, this, dist - 1.0)); //顶点希望被优先选中。
			
			mousePickChildren(ray);
		}
		
		public function clone():Vertex
		{
			var vert:Vertex = new Vertex(_point.clone(), _dimension);
			return vert;
		}
	}
}