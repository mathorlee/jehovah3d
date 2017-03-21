package jehovah3d.core.resource
{
	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import jehovah3d.core.Bounding;
	import jehovah3d.core.pick.MousePickManager;
	import jehovah3d.core.pick.Ray;
	import jehovah3d.core.pick.RectFace;

	public class GeometryResource extends Resource
	{
		private var _coordinateBuffer:VertexBuffer3D; //va0
		private var _coordinateData:Vector.<Number>;
		
		private var _vertexColorBuffer:VertexBuffer3D;
		private var _vertexColorData:Vector.<Number>;
		
		private var _normalBuffer:VertexBuffer3D; //va1
		private var _normalData:Vector.<Number>;
		
		private var _tangentBuffer:VertexBuffer3D;
		private var _tangentData:Vector.<Number>;
		
		private var _diffuseUVBuffer:VertexBuffer3D; //va2-va7
		private var _diffuseUVData:Vector.<Number>;
		
		private var _lightUVBuffer:VertexBuffer3D;
		private var _lightUVData:Vector.<Number>;
		
		private var _indexBuffer:IndexBuffer3D; //
		private var _indexData:Vector.<uint>;
		
		private var _geometryChanged:Boolean = true;
		private var _bounding:Bounding;
		public var isQuadGeometry:Boolean = false;
		public function GeometryResource()
		{
			
		}
		
		/**
		 * upload geometry resource to GPU. 
		 * @param context3D
		 * 
		 */		
		override public function upload(context3D:Context3D):void
		{
			if(isUploaded && cachedContext3D == context3D) //if geometry is uploaded and cached context3d equals current context3d, no need to continue.
				return ;
			else //else, update cached context3d and upload. the can handle context3d loss.
				cachedContext3D = context3D;
			
//			trace("geometry.upload");
			if(_coordinateData)
			{
				if(_coordinateBuffer)
					_coordinateBuffer.dispose();
				_coordinateBuffer = context3D.createVertexBuffer(numVertices, 3);
				_coordinateBuffer.uploadFromVector(_coordinateData, 0, numVertices);
			}
			if(_vertexColorData)
			{
				if(_vertexColorBuffer)
					_vertexColorBuffer.dispose();
				_vertexColorBuffer = context3D.createVertexBuffer(numVertices, 3);
				_vertexColorBuffer.uploadFromVector(_vertexColorData, 0, numVertices);
			}
			if(_diffuseUVData)
			{
				if(_diffuseUVBuffer)
					_diffuseUVBuffer.dispose();
				_diffuseUVBuffer = context3D.createVertexBuffer(numVertices, 2);
				_diffuseUVBuffer.uploadFromVector(_diffuseUVData, 0, numVertices);
			}
			if(_lightUVData)
			{
				if(_lightUVBuffer)
					_lightUVBuffer.dispose();
				_lightUVBuffer = context3D.createVertexBuffer(numVertices, 2);
				_lightUVBuffer.uploadFromVector(_lightUVData, 0, numVertices);
			}
			if(_normalData)
			{
				if(_normalBuffer)
					_normalBuffer.dispose();
				_normalBuffer = context3D.createVertexBuffer(numVertices, 3);
				_normalBuffer.uploadFromVector(_normalData, 0, numVertices);
			}
			if(_tangentData)
			{
				if(_tangentBuffer)
					_tangentBuffer.dispose();
				_tangentBuffer = context3D.createVertexBuffer(numVertices, 3);
				_tangentBuffer.uploadFromVector(_tangentData, 0, numVertices);
			}
			if(_indexData)
			{
				if(_indexBuffer)
					_indexBuffer.dispose();
				_indexBuffer = context3D.createIndexBuffer(numIndices);
				_indexBuffer.uploadFromVector(_indexData, 0, _indexData.length);
			}
			_geometryChanged = false;
		}
		
		/**
		 * 静态方法。根据外部传入的顶点和三角序列计算法线
		 * @param vertices
		 * @param indices
		 * @return 
		 * 
		 */		
		public static function calculateNormalsByVerticesAndIndices(vertices:Vector.<Vector3D>, indices:Vector.<uint>):Vector.<Vector3D>
		{
			var normals:Vector.<Vector3D> = new Vector.<Vector3D>();
			var i:int;
			var numV:int = vertices.length;
			var numT:int = indices.length / 3;
			for(i = 0; i < numV; i ++)
				normals.push(new Vector3D());
			for(i = 0; i < numT; i ++)
			{
				var index1:uint = indices[3 * i];
				var index2:uint = indices[3 * i + 1];
				var index3:uint = indices[3 * i + 2];
				var edge1:Vector3D = vertices[index2].subtract(vertices[index1]);
				
				var edge2:Vector3D = vertices[index3].subtract(vertices[index1]);
				var cp:Vector3D = edge1.crossProduct(edge2);
				cp.normalize();
				
				normals[index1].x += cp.x;
				normals[index1].y += cp.y;
				normals[index1].z += cp.z;
				normals[index2].x += cp.x;
				normals[index2].y += cp.y;
				normals[index2].z += cp.z;
				normals[index3].x += cp.x;
				normals[index3].y += cp.y;
				normals[index3].z += cp.z;
			}
			
			//normalize normals.
			for(i = 0; i < numV; i ++)
				normals[i].normalize();
			
			return normals;
		}
		
		public function calculateNormal():void
		{
			if(!_indexData || !_coordinateData)
				return ;
			var i:uint;
			_normalData = new Vector.<Number>(numVertices * 3);
			for(i = 0; i < _indexData.length / 3; i ++)
			{
				var index1:uint = _indexData[3 * i];
				var index2:uint = _indexData[3 * i + 1];
				var index3:uint = _indexData[3 * i + 2];
				var edge1:Vector3D = new Vector3D(
					_coordinateData[index2 * 3] - _coordinateData[index1 * 3], 
					_coordinateData[index2 * 3 + 1] - _coordinateData[index1 * 3 + 1], 
					_coordinateData[index2 * 3 + 2] - _coordinateData[index1 * 3 + 2]
				);
				var edge2:Vector3D = new Vector3D(
					_coordinateData[index3 * 3] - _coordinateData[index1 * 3], 
					_coordinateData[index3 * 3 + 1] - _coordinateData[index1 * 3 + 1], 
					_coordinateData[index3 * 3 + 2] - _coordinateData[index1 * 3 + 2]
				);
				var cp:Vector3D = edge1.crossProduct(edge2);
				cp.normalize();
				_normalData[index1 * 3] += cp.x;
				_normalData[index1 * 3 + 1] += cp.y;
				_normalData[index1 * 3 + 2] += cp.z;
				_normalData[index2 * 3] += cp.x;
				_normalData[index2 * 3 + 1] += cp.y;
				_normalData[index2 * 3 + 2] += cp.z;
				_normalData[index3 * 3] += cp.x;
				_normalData[index3 * 3 + 1] += cp.y;
				_normalData[index3 * 3 + 2] += cp.z;
			}
			
			//normalize normals.
			var length:Number;
			for(i = 0; i < numVertices; i ++)
			{
				length = Math.sqrt(_normalData[i * 3 + 0] * _normalData[i * 3 + 0] + _normalData[i * 3 + 1] * _normalData[i * 3 + 1] + _normalData[i * 3 + 2] * _normalData[i * 3 + 2]);
				if(length == 0)
					continue;
				_normalData[i * 3 + 0] /= length;
				_normalData[i * 3 + 1] /= length;
				_normalData[i * 3 + 2] /= length;
			}
			_geometryChanged = true;
		}
		
		public function calculateTangent():void
		{
			_tangentData = new Vector.<Number>(numVertices * 3);
			var i:int;
			for(i = 0; i < _indexData.length / 3; i ++)
			{
				var i0:int = _indexData[3 * i + 0];
				var i1:int = _indexData[3 * i + 1];
				var i2:int = _indexData[3 * i + 2];
				
				var positionAB:Vector3D = new Vector3D(
					_coordinateData[i1 * 3 + 0] - _coordinateData[i0 * 3 + 0], 
					_coordinateData[i1 * 3 + 1] - _coordinateData[i0 * 3 + 1], 
					_coordinateData[i1 * 3 + 2] - _coordinateData[i0 * 3 + 2]
				);
				var positionAC:Vector3D = new Vector3D(
					_coordinateData[i2 * 3 + 0] - _coordinateData[i0 * 3 + 0], 
					_coordinateData[i2 * 3 + 1] - _coordinateData[i0 * 3 + 1], 
					_coordinateData[i2 * 3 + 2] - _coordinateData[i0 * 3 + 2]
				);
				var uvAB:Point = new Point(
					_diffuseUVData[i1 * 2 + 0] - _diffuseUVData[i0 * 2 + 0], 
					_diffuseUVData[i1 * 2 + 1] - _diffuseUVData[i0 * 2 + 1]
				);
				var uvAC:Point = new Point(
					_diffuseUVData[i2 * 2 + 0] - _diffuseUVData[i0 * 2 + 0], 
					_diffuseUVData[i2 * 2 + 1] - _diffuseUVData[i0 * 2 + 1]
				);
				
				var r:Number = 1.0 / (uvAB.x * uvAC.y - uvAB.y * uvAC.x);
				var tangent:Vector3D = new Vector3D(
					(uvAC.y * positionAB.x - uvAB.y * positionAC.x) * r, 
					(uvAC.y * positionAB.y - uvAB.y * positionAC.y) * r, 
					(uvAC.y * positionAB.z - uvAB.y * positionAC.z) * r
				);
				
				tangent.normalize();
				
				_tangentData[i0 * 3 + 0] += tangent.x;
				_tangentData[i0 * 3 + 1] += tangent.y;
				_tangentData[i0 * 3 + 2] += tangent.z;
				
				_tangentData[i1 * 3 + 0] += tangent.x;
				_tangentData[i1 * 3 + 1] += tangent.y;
				_tangentData[i1 * 3 + 2] += tangent.z;
				
				_tangentData[i2 * 3 + 0] += tangent.x;
				_tangentData[i2 * 3 + 1] += tangent.y;
				_tangentData[i2 * 3 + 2] += tangent.z;
			}
			
			var n:Vector3D;
			var t:Vector3D;
			
			for(i = 0; i < numVertices; i ++)
			{
				//tangent = (t - n * dot(n, t)).normalize
				n = new Vector3D(_normalData[i * 3 + 0], _normalData[i * 3 + 1], _normalData[i * 3 + 2]);
				t = new Vector3D(_tangentData[i * 3 + 0], _tangentData[i * 3 + 1], _tangentData[i * 3 + 2]);
				n.scaleBy(n.dotProduct(t));
				t = t.subtract(n);
				t.normalize();
				_tangentData[i * 3 + 0] = t.x;
				_tangentData[i * 3 + 1] = t.y;
				_tangentData[i * 3 + 2] = t.z;
			}
		}
		
		public function inverseNormal():void
		{
			var i:int;
			for(i = 0; i < _normalData.length; i ++)
				_normalData[i] = -_normalData[i];
		}
		
		/**
		 * calculate intersection dist. 
		 * @param ray
		 * @return 
		 * 
		 */		
		public function calculateIntersectionDist(ray:Ray):Number
		{
			var i:int;
			var tmp:Vector3D = null;
			var tmpDist:Number;
			var dist:Number;
			for(i = 0; i < _indexData.length / 3; isQuadGeometry ? i += 2 : i ++)
			{
				var index1:uint = _indexData[3 * i];
				var index2:uint = _indexData[3 * i + 1];
				var index3:uint = _indexData[3 * i + 2];
				var v1:Vector3D = new Vector3D(_coordinateData[index1 * 3], _coordinateData[index1 * 3 + 1], _coordinateData[index1 * 3 + 2]);
				var v2:Vector3D = new Vector3D(_coordinateData[index2 * 3], _coordinateData[index2 * 3 + 1], _coordinateData[index2 * 3 + 2]);
				var v3:Vector3D = new Vector3D(_coordinateData[index3 * 3], _coordinateData[index3 * 3 + 1], _coordinateData[index3 * 3 + 2]);
				var face:RectFace = new RectFace(v1, v2, v3);
				tmp = MousePickManager.rayRectFaceIntersect(ray, face, !isQuadGeometry);
				if(tmp)
				{
					tmpDist = tmp.subtract(ray.p0).length / ray.dir.length;
					if(dist)
					{
						if(tmpDist < dist)
							dist = tmpDist;
					}
					else
					{
						dist = tmpDist;
					}
				}
			}
			return dist;
		}
		
		override public function get isUploaded():Boolean
		{
			if(_geometryChanged) 
				return false;
			return true;
		}
		
		public function get coordinateBuffer():VertexBuffer3D
		{
			return _coordinateBuffer;
		}
		public function get vertexColorBuffer():VertexBuffer3D
		{
			return _vertexColorBuffer;
		}
		public function get diffuseUVBuffer():VertexBuffer3D
		{
			return _diffuseUVBuffer;
		}
		public function get lightUVBuffer():VertexBuffer3D
		{
			return _lightUVBuffer;
		}
		public function get normalBuffer():VertexBuffer3D
		{
			return _normalBuffer;
		}
		public function get tangentBuffer():VertexBuffer3D
		{
			return _tangentBuffer;
		}
		public function get indexBuffer():IndexBuffer3D
		{
			return _indexBuffer;
		}
		public function get coordinateData():Vector.<Number>
		{
			return _coordinateData;
		}
		public function set coordinateData(val:Vector.<Number>):void
		{
			_coordinateData = val.slice();
			_geometryChanged = true;
		}
		public function set vertexColorData(val:Vector.<Number>):void
		{
			_vertexColorData = val.slice();
			_geometryChanged = true;
		}
		public function get diffuseUVData():Vector.<Number>
		{
			return _diffuseUVData;
		}
		public function set diffuseUVData(val:Vector.<Number>):void
		{
			_diffuseUVData = val.slice();
			_geometryChanged = true;
		}
		public function set lightUVData(val:Vector.<Number>):void
		{
			_lightUVData = val.slice();
			_geometryChanged = true;
		}
		public function set normalData(val:Vector.<Number>):void
		{
			_normalData = val.slice();
			_geometryChanged = true;
		}
		public function set tangentData(val:Vector.<Number>):void
		{
			_tangentData = val.slice();
			_geometryChanged = true;
		}
		public function get indexData():Vector.<uint>
		{
			return _indexData;
		}
		public function set indexData(val:Vector.<uint>):void
		{
			_indexData = val.slice();
			_geometryChanged = true;
		}
		public function get numVertices():int
		{
			return _coordinateData.length / 3;
		}
		public function get numIndices():int
		{
			return _indexData.length;
		}
		public function get numTriangle():int
		{
			return _indexData.length / 3;
		}
		public function get bounding():Bounding
		{
			var ret:Bounding = new Bounding();
			var i:uint;
			for(i = 0; i < _coordinateData.length / 3; i ++)
			{
				if(_coordinateData[3 * i] > ret.maxX)
					ret.maxX = _coordinateData[3 * i];
				if(_coordinateData[3 * i] < ret.minX)
					ret.minX = _coordinateData[3 * i];
				if(_coordinateData[3 * i + 1] > ret.maxY)
					ret.maxY = _coordinateData[3 * i + 1];
				if(_coordinateData[3 * i + 1] < ret.minY)
					ret.minY = _coordinateData[3 * i + 1];
				if(_coordinateData[3 * i + 2] > ret.maxZ)
					ret.maxZ = _coordinateData[3 * i + 2];
				if(_coordinateData[3 * i + 2] < ret.minZ)
					ret.minZ = _coordinateData[3 * i + 2];
			}
			ret.calculateDimension();
			return ret;
		}
		
		/**
		 * dispose geometry resource. 
		 * 
		 */		
		override public function dispose():void
		{
			super.dispose();
			if(_coordinateBuffer)
			{
				_coordinateBuffer.dispose();
				_coordinateBuffer = null;
			}
			if(_vertexColorBuffer)
			{
				_vertexColorBuffer.dispose();
				_vertexColorBuffer = null;
			}
			if(_diffuseUVBuffer)
			{
				_diffuseUVBuffer.dispose();
				_diffuseUVBuffer = null;
			}
			if(_lightUVBuffer)
			{
				_lightUVBuffer.dispose();
				_lightUVBuffer = null;
			}
			if(_normalBuffer)
			{
				_normalBuffer.dispose();
				_normalBuffer = null;
			}
			if(_tangentBuffer)
			{
				_tangentBuffer.dispose();
				_tangentBuffer = null;
			}
			if(_indexBuffer != null)
			{
				_indexBuffer.dispose();
				_indexBuffer = null;
			}
			if(_coordinateData)
				_coordinateData.length = 0;
			if(_vertexColorData)
				_vertexColorData.length = 0;
			if(_diffuseUVData)
				_diffuseUVData.length = 0;
			if(_lightUVData)
				_lightUVData.length = 0;
			if(_normalData)
				_normalData.length = 0;
			if(_tangentData)
				_tangentData.length = 0;
			if(_indexData)
				_indexData.length = 0;
		}
	}
}