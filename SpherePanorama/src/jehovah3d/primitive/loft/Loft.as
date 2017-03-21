package jehovah3d.primitive.loft
{
	import com.fuwo.math.MyMath;
	
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import jehovah3d.core.pick.Line;
	import jehovah3d.core.pick.MousePickManager;
	import jehovah3d.core.resource.GeometryResource;
	
	import phoenix.view.threed.wall.Floor3D;

	public class Loft
	{
		private var _path:LoftPath;
		private var _shape:LoftShape;
		private var _cutPoints:Vector.<Vector.<Vector3D>>; //{"points": Vector.<Point>}
		
		public var vertices:Vector.<Vector3D>;
		public var uvs:Vector.<Point>;
		public var normals:Vector.<Vector3D>;
		public var indices:Vector.<uint>;
		
		public function Loft(path:LoftPath, shape:LoftShape)
		{
			_path = path;
			_shape = shape;
			initCutPoints();
			initGeometryData();
		}
		
		/**
		 * 计算顶点
		 * 
		 */		
		public function initCutPoints():void
		{
			_cutPoints = new Vector.<Vector.<Vector3D>>();
			var i:int;
			var j:int;
			for(i = 0; i < path.n; i ++)
			{
				var line:Line;
				
				var v0:Point = path.points[i];
				var v1:Point = path.points[(i == path.n - 1 && !path.closed)? MyMath.preIndex(i, path.n) : MyMath.nextIndex(i, path.n)];
				var v01:Vector3D = (i == path.n - 1 && !path.closed)? new Vector3D(v0.x - v1.x, v0.y - v1.y) : new Vector3D(v1.x - v0.x, v1.y - v0.y, 0);
				v01.normalize();
				var rz:Number = Math.atan2(v01.y, v01.x);
				var matrix:Matrix3D = new Matrix3D();
				matrix.appendRotation(rz * 180 / Math.PI, Vector3D.Z_AXIS);
				matrix.appendTranslation(v0.x, v0.y, 0);
				
				_cutPoints.push(new Vector.<Vector3D>());
				for(j = 0; j < _shape.n; j ++)
				{
					var v2:Vector3D = matrix.transformVector(new Vector3D(0, _shape.points[j].x, _shape.points[j].y));
					line = new Line(v2, v01);
					var intersect:Object = MousePickManager.linePlaneIntersect(line, path.planes[i]);
					_cutPoints[i].push(intersect.point);
				}
			}
		}
		
		public function initGeometryData():void
		{
			var i:int;
			var j:int;
			var n:int = _path.n;
			var m:int = _shape.n;
			
			//计算vList 没断是重复的。存储uv的v信息。3ds max uv坐标系的。stage3D的v要取反
			var dist:Number = 0;
			var vList:Vector.<Number> = new Vector.<Number>();
			for(i = 0; i < m; i ++)
			{
				vList.push(dist);
				dist += _shape.points[(i + 1) % m].subtract(_shape.points[i]).length;
			}
			vList.push(dist);
			
			/*
			数组1：shape每条边起点的顶点索引（新的顶点）
			数组2：shape新的顶点序列是从老顶点序列的拷贝
			*/
			var t:int = 0; //用smoothingGroup拆分顶点后shape新的顶点数量
			var newVertexIndexOfSegment:Dictionary = new Dictionary();
			var splitedVDict:Dictionary = new Dictionary();
			for(i = 0; i < m; i ++)
			{
				if(i == 0)
					newVertexIndexOfSegment[i] = t;
				else
				{
					if(_shape.smoothingGroups[i] == 0 || _shape.smoothingGroups[i - 1] == 0 || _shape.smoothingGroups[i] != _shape.smoothingGroups[i - 1])
						newVertexIndexOfSegment[i] = ++ t;
					else
						newVertexIndexOfSegment[i] = t;
				}
				
				splitedVDict[t] = i;
				splitedVDict[++ t] = MyMath.nextIndex(i, m);
			}
			t ++;
			
			//创建顶点序列
			vertices = new Vector.<Vector3D>();
			for(i = 0; i < n; i ++)
			{
				if(i == n - 1 && !_path.closed)
					continue;
				for(j = 0; j < t; j ++)
					vertices.push(_cutPoints[i][splitedVDict[j]]);
				for(j = 0; j < t; j ++)
					vertices.push(_cutPoints[MyMath.nextIndex(i, n)][splitedVDict[j]]);
			}
			//创建uv序列和indices序列
			uvs = new Vector.<Point>(vertices.length);
			indices = new Vector.<uint>();
			
			for(i = 0; i < n; i ++)
			{
				if(i == n - 1 && !_path.closed)
					continue;
				
				var basePoint:Vector3D = vertices[2 * i * t]; //计算uv的基准点
				var dir:Point = _path.points[MyMath.nextIndex(i, _path.n)].subtract(_path.points[i]);
				dir.normalize(1);
				for(j = 0; j < m; j ++)
				{
					var i0:int = i * 2 * t + newVertexIndexOfSegment[j];
					var i1:int = i * 2 * t + newVertexIndexOfSegment[j] + 1;
					var i2:int = (i * 2 + 1) * t + newVertexIndexOfSegment[j] + 1;
					var i3:int = (i * 2 + 1) * t + newVertexIndexOfSegment[j];
					
					var u0:Number = -MyMath.dotProduct(dir, new Point(vertices[i0].x - basePoint.x, vertices[i0].y - basePoint.y));
					var u1:Number = -MyMath.dotProduct(dir, new Point(vertices[i1].x - basePoint.x, vertices[i1].y - basePoint.y));
					var u2:Number = -MyMath.dotProduct(dir, new Point(vertices[i2].x - basePoint.x, vertices[i2].y - basePoint.y));
					var u3:Number = -MyMath.dotProduct(dir, new Point(vertices[i3].x - basePoint.x, vertices[i3].y - basePoint.y));
					
					//默认4个顶点的uv
					var v0:Number = vList[j];
					var v1:Number = vList[j + 1];
					var uv0:Point = new Point(u0, v0);
					var uv1:Point = new Point(u1, v1);
					var uv2:Point = new Point(u2, v1);
					var uv3:Point = new Point(u3, v0);
					indices.push(i0, i1, i2, i0, i2, i3);
					uvs[i0] = uv0;
					uvs[i1] = uv1;
					uvs[i2] = uv2;
					uvs[i3] = uv3;
				}
			}
			
			initStartSectionGeometry();
			initStopSectionGeometry();
			normals = GeometryResource.calculateNormalsByVerticesAndIndices(vertices, indices);
//			traceLoftData();
		}
		
		private function initStartSectionGeometry():void
		{
			if(_path.closed)
				return ;
			
			var i:int;
			var p0:Point = _path.points[1].subtract(_path.points[0]);
			p0 = MyMath.rotateByZ(p0, Math.PI / 2);
			var xAxis:Vector3D = new Vector3D(p0.x, p0.y, 0);
			var yAxis:Vector3D = new Vector3D(0, 0, 1);
			var zAxis:Vector3D = xAxis.crossProduct(yAxis);
			var matrix:Matrix3D = new Matrix3D(Vector.<Number>([
				xAxis.x, xAxis.y, xAxis.z, 0, 
				yAxis.x, yAxis.y, yAxis.z, 0, 
				zAxis.x, zAxis.y, zAxis.z, 0, 
				_path.points[0].x, _path.points[0].y, 0, 1
			]));
			
			var section:Object = Floor3D.splitPolygonToTriangles(_shape.points);
			var currentVCount:int = vertices.length;
			for(i = 0; i < section.vertices.length; i ++)
				vertices.push(matrix.transformVector(section.vertices[i]));
			for(i = 0; i < section.indices.length / 3; i ++)
				indices.push(section.indices[i * 3 + 2] + currentVCount, section.indices[i * 3 + 1] + currentVCount, section.indices[i * 3 + 0] + currentVCount);
			MyMath.mergeTwoArray(uvs, section.uvs, true);
		}
		
		private function initStopSectionGeometry():void
		{
			if(_path.closed)
				return ;
			
			var i:int;
			var p0:Point = _path.points[_path.n - 1].subtract(_path.points[_path.n - 2]);
			p0 = MyMath.rotateByZ(p0, Math.PI / 2);
			var xAxis:Vector3D = new Vector3D(p0.x, p0.y, 0);
			var yAxis:Vector3D = new Vector3D(0, 0, 1);
			var zAxis:Vector3D = xAxis.crossProduct(yAxis);
			var matrix:Matrix3D = new Matrix3D(Vector.<Number>([
				xAxis.x, xAxis.y, xAxis.z, 0, 
				yAxis.x, yAxis.y, yAxis.z, 0, 
				zAxis.x, zAxis.y, zAxis.z, 0, 
				_path.points[_path.n - 1].x, _path.points[_path.n - 1].y, 0, 1
			]));
			
			var section:Object = Floor3D.splitPolygonToTriangles(_shape.points);
			var currentVCount:int = vertices.length;
			for(i = 0; i < section.vertices.length; i ++)
				vertices.push(matrix.transformVector(section.vertices[i]));
			for(i = 0; i < section.indices.length; i ++)
				indices.push(section.indices[i] + currentVCount);
			MyMath.mergeTwoArray(uvs, section.uvs, true);
		}
		
		public function traceLoftData():void
		{
			trace("numPathSeg: " + _path.n);
			trace("numShapeSeg: " + _shape.n);
			trace("numVertices: " + vertices.length);
			trace("numTriangles: " + indices.length / 3);
		}
		
		public function get coordinateData():Vector.<Number>
		{
			var ret:Vector.<Number> = new Vector.<Number>();
			var i:int;
			for(i = 0; i < vertices.length; i ++)
				ret.push(vertices[i].x, vertices[i].y, vertices[i].z);
			return ret;
		}
		public function getDiffuseUVData(textureWidth:Number, textureHeight:Number):Vector.<Number>
		{
			var ret:Vector.<Number> = new Vector.<Number>();
			var i:int;
			for(i = 0; i < uvs.length; i ++)
				ret.push(uvs[i].x / textureWidth, -uvs[i].y / textureHeight);
			return ret;
		}
		public function get indexData():Vector.<uint>
		{
			return indices;
		}
		
		public function get cutPoints():Vector.<Vector.<Vector3D>>
		{
			return _cutPoints;
		}
		/**
		 * LoftPath
		 * @return 
		 * 
		 */		
		public function get path():LoftPath
		{
			return _path;
		}
		
		/**
		 * LoftShap
		 * @return 
		 * 
		 */		
		public function get shape():LoftShape
		{
			return _shape;
		}
		
		public function get realWidth():Number
		{
			return _path.realWidth;
		}
		public function get realLength():Number
		{
			return _path.realLength;
		}
		public function get realHeight():Number
		{
			return _shape.realHeight;
		}
		public function get realX():Number
		{
			return _path.realX;
		}
		public function get realY():Number
		{
			return _path.realY;
		}
		
		public function updateLoftShape(points:Array, smoothingGroups:Array, no:String):void
		{
			_shape = new LoftShape(points, smoothingGroups, no);
			initCutPoints();
			initGeometryData();
		}
	}
}