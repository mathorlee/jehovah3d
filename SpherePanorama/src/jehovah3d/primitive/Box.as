package jehovah3d.primitive
{
	import flash.geom.Vector3D;
	
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.GeometryResource;
	
	public class Box extends Mesh
	{
		private var _width:Number;
		private var _length:Number;
		private var _height:Number;
		public function Box(width:Number = 100.0, length:Number = 100.0, height:Number = 100.0)
		{
			_width = width;
			_length = length;
			_height = height;
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
				new Vector3D(_width / 2, -_length / 2, 0), 
				new Vector3D(_width / 2, _length / 2, _height), 
				new Vector3D(-_width / 2, _length / 2, _height), 
				new Vector3D(-_width / 2, -_length / 2, _height), 
				new Vector3D(_width / 2, -_length / 2, _height)
			);
			var i:int;
			var coordinateData:Vector.<Number> = new Vector.<Number>();
			var normalData:Vector.<Number> = new Vector.<Number>();
			var uvData:Vector.<Number> = new Vector.<Number>();
			var indices:Vector.<uint> = Vector.<uint>([
				5, 4, 0, 5, 0, 1, 
				6, 5, 1, 6, 1, 2, 
				7, 6, 2, 7, 2, 3, 
				4, 7, 3, 4, 3, 0, 
				1, 0, 3, 1, 3, 2, 
				4, 5, 6, 4, 6, 7
			]);
			for(i = 0; i < indices.length; i ++)
				coordinateData.push(points[indices[i]].x, points[indices[i]].y, points[indices[i]].z);
			for(i = 0; i < indices.length / 3; i ++)
			{
				var v1:Vector3D = points[indices[3 * i]];
				var v2:Vector3D = points[indices[3 * i + 1]];
				var v3:Vector3D = points[indices[3 * i + 2]];
				var v1v2:Vector3D = v2.subtract(v1);
				var v1v3:Vector3D = v3.subtract(v1);
				var normal:Vector3D = v1v2.crossProduct(v1v3);
				normal.normalize();
				normalData.push(normal.x, normal.y, normal.z);
				normalData.push(normal.x, normal.y, normal.z);
				normalData.push(normal.x, normal.y, normal.z);
			}
			for(i = 0; i < indices.length / 6; i ++)
				uvData.push(1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1);
			for(i = 0; i < indices.length; i ++)
				indices[i] = i;
			geometry.coordinateData = coordinateData;
			geometry.diffuseUVData = uvData;
			geometry.indexData = indices;
			geometry.calculateNormal();
		}
	}
}