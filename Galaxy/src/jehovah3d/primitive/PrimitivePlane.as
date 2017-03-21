package jehovah3d.primitive
{
	import flash.geom.Vector3D;
	
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.GeometryResource;
	
	public class PrimitivePlane extends Mesh
	{
		private var _width:Number;
		private var _length:Number;
		public function PrimitivePlane(width:Number, length:Number)
		{
			_width = width;
			_length = length;
			initGeometry();
		}
		
		private function initGeometry():void
		{
			geometry = new GeometryResource();
			var points:Vector.<Vector3D> = new Vector.<Vector3D>();
			points.push(
				new Vector3D(_width / 2, _length / 2, 0), 
				new Vector3D(-_width / 2, _length / 2, 0), 
				new Vector3D(-_width / 2, -_length / 2, 0), 
				new Vector3D(_width / 2, -_length / 2, 0)
			);
			var i:int;
			var coordinateData:Vector.<Number> = new Vector.<Number>();
			for(i = 0; i < 4; i ++)
				coordinateData.push(points[i].x, points[i].y, points[i].z);
			geometry.coordinateData = coordinateData;
			var uvData:Vector.<Number> = new Vector.<Number>();
			uvData.push(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0);
			geometry.diffuseUVData = uvData;
			
			var indices:Vector.<uint> = Vector.<uint>([
				0, 1, 2, 0, 2, 3
			]);
			geometry.indexData = indices;
			geometry.calculateNormal();
		}
	}
}