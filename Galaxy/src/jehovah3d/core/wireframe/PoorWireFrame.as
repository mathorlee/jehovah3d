package jehovah3d.core.wireframe
{
	import flash.display3D.Context3DTriangleFace;
	import flash.geom.Vector3D;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.Object3D;
	import jehovah3d.core.material.DiffuseMtl;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.GeometryResource;
	import jehovah3d.util.HexColor;
	
	/**
	 * WireFrame每次render前需要做的计算太多！太慢！这个是穷人版的WireFrame，会有近大远小的问题！但在正交投影下看不出来！
	 * @author lisongsong
	 * 
	 */	
	public class PoorWireFrame extends Mesh
	{
		private var _thickness:Number;
		
		public function PoorWireFrame(vertexList:Vector.<Vector3D>, color:uint, thickness:Number)
		{
			super();
			this.mouseEnabled = false;
			_thickness = thickness;
			_mtl = new DiffuseMtl();
			_mtl.culling = Context3DTriangleFace.NONE;
			_mtl.diffuseColor = new HexColor(color, 1);
			initGeometry(vertexList);
		}
		
		/**
		 * 设置vertexList时会初始化geometry
		 * @param value
		 * 
		 */		
		private function initGeometry(value:Vector.<Vector3D>):void
		{
			_geometry = new GeometryResource();
			var coordinateData:Vector.<Number> = new Vector.<Number>();
			var indexData:Vector.<uint> = new Vector.<uint>();
			
			var i:int;
			var v0:Vector3D;
			var v1:Vector3D;
			var v2:Vector3D;
			for(i = 0; i < value.length / 2; i ++)
			{
				v0 = value[i * 2];
				v1 = value[i * 2 + 1];
				v2 = v0.crossProduct(v1);
				v2.normalize();
				coordinateData.push(
					v1.x + v2.x * _thickness / 2, v1.y + v2.y * _thickness / 2, v1.z + v2.z * _thickness, 
					v1.x - v2.x * _thickness / 2, v1.y - v2.y * _thickness / 2, v1.z - v2.z * _thickness, 
					v0.x - v2.x * _thickness / 2, v0.y - v2.y * _thickness / 2, v0.z - v2.z * _thickness, 
					v0.x + v2.x * _thickness / 2, v0.y + v2.y * _thickness / 2, v0.z + v2.z * _thickness
				);
				
				var v0v1:Vector3D = v1.subtract(v0);
				v0v1.normalize();
				v2 = v2.crossProduct(v0v1);
				coordinateData.push(
					v0.x + v2.x * _thickness / 2, v0.y + v2.y * _thickness / 2, v0.z + v2.z * _thickness, 
					v0.x - v2.x * _thickness / 2, v0.y - v2.y * _thickness / 2, v0.z - v2.z * _thickness, 
					v1.x - v2.x * _thickness / 2, v1.y - v2.y * _thickness / 2, v1.z - v2.z * _thickness, 
					v1.x + v2.x * _thickness / 2, v1.y + v2.y * _thickness / 2, v1.z + v2.z * _thickness
				);
				indexData.push(
					8 * i + 0, 8 * i + 1, 8 * i + 2, 8 * i + 0, 8 * i + 2, 8 * i + 3, 
					8 * i + 4, 8 * i + 5, 8 * i + 6, 8 * i + 4, 8 * i + 6, 8 * i + 7
				);
			}
			_geometry.coordinateData = coordinateData;
			_geometry.indexData = indexData;
			_geometry.upload(Jehovah.context3D);
		}
		
		override public function collectRenderList(opaqueRenderList:Vector.<Object3D>, transparentRenderList:Vector.<Object3D>):void
		{
			if(!visible)
				return ;
			opaqueRenderList.push(this);
		}
	}
}