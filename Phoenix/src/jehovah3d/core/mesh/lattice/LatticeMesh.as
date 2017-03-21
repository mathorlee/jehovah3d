package jehovah3d.core.mesh.lattice
{
	import jehovah3d.Jehovah;
	import jehovah3d.core.Context3DProperty;
	import jehovah3d.core.material.DiffuseMtl;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.pick.MousePickData;
	import jehovah3d.core.pick.MousePickManager;
	import jehovah3d.core.renderer.LineRenderer;
	import jehovah3d.core.renderer.Renderer;
	import jehovah3d.core.resource.GeometryResource;
	import jehovah3d.util.HexColor;

	import com.fuwo.math.CGeometry;
	import com.fuwo.math.MyMath;
	import com.fuwo.math.Ray3D;

	import flash.display3D.Context3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	/**
	 * 晶格类。点、线组成的物体特像晶格。
	 * @author lisongsong
	 * 
	 */	
	public class LatticeMesh extends Mesh
	{
		public static const DEFAULT_VERTEX_THICKNESS:Number = 4; //默认顶点厚度
		public static const DEFAULT_EDGE_THICKNESS:Number = 4; //默认边厚度
		public static const DEFAULT_DIST_OFFSET_WHEN_SELECT_VERTEX:Number = 8; //默认选中点时dist的offset值
		public static const DEFAULT_DIST_OFFSET_WHEN_SELECT_EDGE:Number = 4; //默认选中边时dist的offset值
		
		protected var _vertices:Vector.<SUVertex> = new Vector.<SUVertex>(); //维护点
		protected var _edges:Vector.<SUEdge> = new Vector.<SUEdge>(); //维护线
		
		public var funcName:String = ""; //用户自定义的名称
		
		public function LatticeMesh()
		{
			_mtl = new DiffuseMtl();
			_mtl.diffuseColor = new HexColor(0, 1);
		}
		
		override public function updateHierarchyMatrix_CameraFinal():void
		{
			super.updateHierarchyMatrix_CameraFinal();
			
			//更新顶点和边
			for each (var vertex:SUVertex in _vertices)
			{
				vertex.update();
			}
			for each (var edge:SUEdge in _edges)
			{
				edge.update();
			}
			
			if (!visible) return ;
			
			var coordinateData:Vector.<Number> = new Vector.<Number>();
			var vertexColorData:Vector.<Number> = new Vector.<Number>();
			var indexData:Vector.<uint> = new Vector.<uint>();
			
			//填充顶点和边的几何数据
//			dunkVertices(coordinateData, vertexColorData, indexData);
			dunkEdges(coordinateData, vertexColorData, indexData);
			
			if (coordinateData.length == 0)
			{
				if (geometry)
				{
					geometry.dispose();
					geometry = null;
				}
			}
			else
			{
				if (!_geometry)
					_geometry = new GeometryResource();
				_geometry.coordinateData = coordinateData;
				_geometry.vertexColorData = vertexColorData;
				_geometry.indexData = indexData;
				_geometry.upload(Jehovah.context3D);
			}
		}
		
		protected function dunkVertices(coordinateData:Vector.<Number>, vertexColorData:Vector.<Number>, indexData:Vector.<uint>):void
		{
			for each (var vertex:SUVertex in _vertices)
			{
				if (vertex.culled || !vertex.visible)
					continue;
				
				var currentVertexCount:uint = coordinateData.length / 3;
				var v0:Vector3D = vertex.cameraSpacePositon;
				var offset:Number = Jehovah.camera.orthographic ? vertex.thickness : -vertex.cameraSpacePositon.z / Jehovah.camera.focalLength * vertex.thickness;
				coordinateData.push(
					v0.x + offset / 2, v0.y + offset / 2, v0.z, 
					v0.x - offset / 2, v0.y + offset / 2, v0.z, 
					v0.x - offset / 2, v0.y - offset / 2, v0.z, 
					v0.x + offset / 2, v0.y - offset / 2, v0.z
				);
				vertexColorData.push(
					vertex.color.fractionalRed, vertex.color.fractionalGreen, vertex.color.fractionalBlue, 
					vertex.color.fractionalRed, vertex.color.fractionalGreen, vertex.color.fractionalBlue, 
					vertex.color.fractionalRed, vertex.color.fractionalGreen, vertex.color.fractionalBlue, 
					vertex.color.fractionalRed, vertex.color.fractionalGreen, vertex.color.fractionalBlue
				);
				indexData.push(
					currentVertexCount + 0, 
					currentVertexCount + 1, 
					currentVertexCount + 2, 
					currentVertexCount + 0, 
					currentVertexCount + 2, 
					currentVertexCount + 3
				);
			}
		}
		
		protected function dunkEdges(coordinateData:Vector.<Number>, vertexColorData:Vector.<Number>, indexData:Vector.<uint>):void
		{
			var v1:Vector3D;
			var v2:Vector3D;
			for each (var edge:SUEdge in _edges)
			{
				if (edge.culled || !edge.showRenderingLine) //边不在视锥内或不显示rendering line，continue
					continue;
				v1 = edge.cameraSpaceVertex0;
				v2 = edge.cameraSpaceVertex1;
				var currentVertexCount:uint = coordinateData.length / 3;
				var cp:Vector3D;
				var d1:Number;
				var d2:Number;
				if(Jehovah.camera.orthographic)
				{
					cp = new Vector3D(0, 0, -1).crossProduct(v2.subtract(v1));
					d1 = d2 = edge.thickness / Jehovah.camera.viewScale;
				}
				else
				{
					cp = v1.crossProduct(v2);
					d1 = -v1.z / Jehovah.camera.focalLength * edge.thickness;
					d2 = -v2.z / Jehovah.camera.focalLength * edge.thickness;
					if(d1 < 0)
						d1 = 0;
					if(d2 < 0)
						d2 = 0;
				}
				cp.normalize();
				coordinateData.push(
					v1.x - cp.x * d1 / 2, v1.y - cp.y * d1 / 2, v1.z - cp.z * d1 / 2, 
					v1.x + cp.x * d1 / 2, v1.y + cp.y * d1 / 2, v1.z + cp.z * d1 / 2, 
					v2.x + cp.x * d2 / 2, v2.y + cp.y * d2 / 2, v2.z + cp.z * d2 / 2, 
					v2.x - cp.x * d2 / 2, v2.y - cp.y * d2 / 2, v2.z - cp.z * d2 / 2
				);
				vertexColorData.push(
					edge.color.fractionalRed, edge.color.fractionalGreen, edge.color.fractionalBlue, 
					edge.color.fractionalRed, edge.color.fractionalGreen, edge.color.fractionalBlue, 
					edge.color.fractionalRed, edge.color.fractionalGreen, edge.color.fractionalBlue, 
					edge.color.fractionalRed, edge.color.fractionalGreen, edge.color.fractionalBlue
				);
				indexData.push(
					currentVertexCount + 0, 
					currentVertexCount + 1, 
					currentVertexCount + 2, 
					currentVertexCount + 0, 
					currentVertexCount + 2, 
					currentVertexCount + 3
				);
			}
		}
		
		override public function render(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			if(!_geometry || !_mtl)
				return ;
			if(!_geometry.isUploaded)
				return ;
			
			if(Jehovah.renderMode == Jehovah.RENDER_ALL || Jehovah.renderMode == Jehovah.RENDER_AMBIENTANDREFLECTION)
				renderWF(context3D, context3DProperty);
		}
		
		public function renderWF(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			var no:String = LineRenderer.NAME;
			if(!rendererDict[no])
				rendererDict[no] = new LineRenderer(this);
			Renderer(rendererDict[no]).render(context3D, context3DProperty);
		}
		
		override public function mousePick(ray:Ray3D, mousePoint:Point = null):void
		{
			if(!mouseEnabled)
				return ;
			
			var rayCopy:Ray3D = ray.transform(Jehovah.camera.globalToLocalMatrix); //相机坐标系的射线
			mousePickVertices(rayCopy, mousePoint);
			mousePickEdges(rayCopy, mousePoint);
		}
		
		/**
		 * 判断Vertex
		 * @param rayCopy
		 * @param mousePoint
		 * 
		 */		
		private function mousePickVertices(rayCopy:Ray3D, mousePoint:Point = null):void
		{
			for each (var vertex:SUVertex in _vertices)
			{
				if (vertex.culled)
					continue;
				var p2:Point = Jehovah.camera.calculateProjection(Jehovah.camera, vertex.cameraSpacePositon, false);
				if (p2.subtract(mousePoint).length < Jehovah.vertexAndLinePickToleranceInPixels)
				{
					var mpd:MousePickData = new MousePickData(
						rayCopy.p0.subtract(vertex.cameraSpacePositon).length - DEFAULT_DIST_OFFSET_WHEN_SELECT_VERTEX, 
						Jehovah.camera.localToGlobalMatrix.transformVector(vertex.cameraSpacePositon)
					);
					mpd.attachVertex = vertex;
					MousePickManager.add(mpd);
				}
			}
			
		}
		
		/**
		 * 判断Edge
		 * @param rayCopy
		 * @param mousePoint
		 * 
		 */		
		private function mousePickEdges(rayCopy:Ray3D, mousePoint:Point = null):void
		{
			for each (var edge:SUEdge in _edges)
			{
				if (edge.culled)
					continue;
//				if (MyMath.isPoint3DEqueal(edge.cameraSpaceVertex0, new Vector3D()) || MyMath.isPoint3DEqueal(edge.cameraSpaceVertex1, new Vector3D()))
//					trace("zero!!!");
				var p0:Point = Jehovah.camera.calculateProjection(Jehovah.camera, edge.cameraSpaceVertex0, false);
				var p1:Point = Jehovah.camera.calculateProjection(Jehovah.camera, edge.cameraSpaceVertex1, false);
				if (!p0 || !p1)
					continue;
				var footPoint:Point = CGeometry.calculateFootPointOnSegment(p0, p1, mousePoint); //垂足
				if (footPoint) //若垂足在线段上
				{
					var dist:Number = footPoint.subtract(mousePoint).length; //垂距
					if (dist < Jehovah.vertexAndLinePickToleranceInPixels) //若垂距够小，吸附现有的点或者面
					{
						var v0:Vector3D = edge.vertex0.cameraSpacePositon;
						var v1:Vector3D = edge.vertex1.cameraSpacePositon;
						var intersection:Object = MyMath.raySegmentIntersection3D(rayCopy, v0, v1); //吸附的点坐标、相机到吸附的点的距离、吸附误差距离
						if (!intersection)
							continue;
						
						var mpd:MousePickData = new MousePickData(
							intersection.dist - DEFAULT_DIST_OFFSET_WHEN_SELECT_EDGE, 
							Jehovah.camera.localToGlobalMatrix.transformVector(intersection.position)
						);
						mpd.attachEdge = edge;
						MousePickManager.add(mpd);
					}
				}
			}
		}
		
		/**
		 * 实例化顶点
		 * @param v
		 * @return 
		 * 
		 */		
		protected function instantiateVertex(v:Vector3D):SUVertex
		{
			return new SUVertex(v);
		}
		
		/**
		 * 实例化边
		 * @param startVertex
		 * @param stopVertex
		 * @return 
		 * 
		 */		
		protected function instantiateEdge(startVertex:SUVertex, stopVertex:SUVertex):SUEdge
		{
			return new SUEdge(startVertex, stopVertex);
		}
		
		/**
		 * 真的添加一个顶点。返回是否添加成功。
		 * @param v
		 * @return 
		 * 
		 */		
		public function addFirstVertex(v:Vector3D):Boolean
		{
			var find:Boolean = (findVertexByPositon(v) != null);
			if (!find) //Real Add
			{
				var newVertex:SUVertex = instantiateVertex(v);
				newVertex.color = new HexColor(0);
				newVertex.parent = this;
				newVertex.update();
				_vertices.push(newVertex); //添加顶点
			}
			return !find;
		}
		
		/**
		 * 添加点和线。返回是否添加成功。
		 * @param v
		 * @return 
		 * 
		 */		
		public function addVertexAndLine(v:Vector3D, edgeColor:uint):Boolean
		{
			var startVertex:SUVertex = lastVertex;
			var stopVertex:SUVertex = findVertexByPositon(v);
			if (startVertex && stopVertex && startVertex == stopVertex) return false;
			
			if (!stopVertex) //Real Add
			{
				stopVertex = instantiateVertex(v);
				stopVertex.color = new HexColor(0);
				stopVertex.parent = this;
				stopVertex.update();
				_vertices.push(stopVertex);
			}
			var edge:SUEdge = instantiateEdge(startVertex, stopVertex);
			edge.color = new HexColor(edgeColor);
			edge.parent = this;
			edge.update();
			_edges.push(edge);
			return true;
		}
		
		public function doDeleteEdge(edge:SUEdge):void
		{
			var i:int;
//			trace(this);
			for (i = _edges.length - 1; i >= 0; i --)
			{
				if (_edges[i] == edge)
				{
					_edges[i].dispose();
					_edges.splice(i, 1);
					break;
				}
			}
			this.removeRedundantVertices();
			this.rebuild();
//			trace(this);
			if (this.isEmpty)
			{
				this.parent.removeChild(this);
				trace("删掉了一个空的LatticeMesh");
			}
		}
		
		/**
		 * 根据positon找到顶点
		 * @param v
		 * @return 
		 * 
		 */		
		protected function findVertexByPositon(v:Vector3D):SUVertex
		{
			for each (var vertex:SUVertex in _vertices)
			{
				if (MyMath.isPoint3DEqual(v, vertex.position, 0.1))
					return vertex;
			}
			return null;
		}
		
		/**
		 * 顶点的数量
		 * @return 
		 * 
		 */		
		public function get vertexCount():int
		{
			return _vertices.length;
		}
		
		/**
		 * 边的数量
		 * @return 
		 * 
		 */		
		public function get edgeCount():int
		{
			return _edges.length;
		}
		
		/**
		 * 是否为空
		 * @return 
		 * 
		 */		
		public function get isEmpty():Boolean
		{
			return (edgeCount == 0 || vertexCount == 0);
		}
		
		/**
		 * 根据顶点和边重新构建Mesh
		 * 水管需要override这个函数
		 * 
		 */		
		public function rebuild():void
		{
			
		}
		
		public function get vertices():Vector.<SUVertex>
		{
			return _vertices;
		}
		public function set vertices(value:Vector.<SUVertex>):void
		{
			_vertices = value;
		}
		public function get edges():Vector.<SUEdge>
		{
			return _edges;
		}
		public function set edges(value:Vector.<SUEdge>):void
		{
			_edges = value;
		}
		
		public function get lastVertex():SUVertex
		{
			if (vertexCount == 0) return null;
			return _vertices[vertexCount - 1];
		}
		
		public function get lastEdge():SUEdge
		{
			if (edgeCount == 0) return null;
			return _edges[edgeCount - 1];
		}
		
		public function getVertexIndex(vertex:SUVertex):int
		{
			for (var i:int = 0; i < vertexCount; i ++)
				if (_vertices[i] == vertex)
					return i;
			return -1;
		}
		public function getEdgeIndex(edge:SUEdge):int
		{
			for (var i:int = 0; i < edgeCount; i ++)
				if (edge == _edges[i])
					return i;
			return -1;
		}
		override public function dispose():void
		{
			disposeVerticesAndEdges();
			super.dispose();
		}
		public function disposeVerticesAndEdges():void
		{
			if (_vertices && _vertices.length > 0)
			{
				for each (var vertex:SUVertex in _vertices)
				{
					vertex.dispose();
				}
				_vertices.length = 0;
			}
			if (_edges && _edges.length > 0)
			{
				for each (var edge:SUEdge in _edges)
				{
					edge.dispose();
				}
				_edges.length = 0;
			}
			_vertices = null;
			_edges = null;
		}
		
		/**
		 * 根据点和索引初始化LatticeMesh
		 * @param vs
		 * @param indices
		 * 
		 */		
		public function initByVerticesAndIndices(vs:Vector.<Vector3D>, indices:Vector.<uint>):void
		{
			disposeVerticesAndEdges();
			
			_vertices = new Vector.<SUVertex>();
			for each (var v:Vector3D in vs)
			{
				var vertexTmp:SUVertex = instantiateVertex(v);
				_vertices.push(vertexTmp);
				vertexTmp.parent = this;
				vertexTmp.color = new HexColor(0);
			}
			_edges = new Vector.<SUEdge>();
			for (var i:int = 0; i < indices.length / 2; i ++)
			{
				var edgeTmp:SUEdge = instantiateEdge(_vertices[indices[i * 2]], _vertices[indices[i * 2 + 1]]);
				_edges.push(edgeTmp);
				edgeTmp.parent = this;
				edgeTmp.color = new HexColor(0);
			}
		}
		
		/**
		 * 初始化方法2！
		 * @param vs
		 * @param es
		 * 
		 */		
		public function initByVerticesAndEdge(vs:Vector.<SUVertex>, es:Vector.<SUEdge>):void
		{
			_vertices = vs;
			_edges = es;
			
			//移除冗余的顶点和边
//			trace("移除冗余前，顶点：" + vertexCount + "，边：" + edgeCount);
			this.removeRedundantVertices();
			this.removeRedundantEdges();
//			trace("移除冗余后，顶点：" + vertexCount + "，边：" + edgeCount);
			this.splitEdge();
		}
		
		/**
		 * 删除冗余的顶顶点。
		 * 
		 */		
		public function removeRedundantVertices():void
		{
			//标记重复的点
			var i:int;
			var j:int;
			var realIndex:Vector.<int> = new Vector.<int>(vertexCount);
			for (i = 0; i < vertexCount; i ++)
				realIndex[i] = i;
			for (i = 1; i < vertexCount; i ++)
			{
				for (j = 0; j < i; j ++)
				{
					if (MyMath.isPoint3DEqual(_vertices[i].position, _vertices[j].position, 0.1))
					{
						realIndex[i] = realIndex[j];
						break;
					}
				}
			}
			
			//更新边对顶点引用
			for each (var edge:SUEdge in _edges)
			{
				edge.vertex0 = _vertices[realIndex[getVertexIndex(edge.vertex0)]];
				edge.vertex1 = _vertices[realIndex[getVertexIndex(edge.vertex1)]];
			}
			
			//移除重复的顶点
			for (i = vertexCount - 1; i >= 0; i --)
				if (realIndex[i] != i)
				{
					_vertices[i].dispose();
					_vertices.splice(i, 1);
				}
		}
		
		/**
		 * 删除冗余的边。
		 * 
		 */		
		public function removeRedundantEdges():void
		{
			//标记重复的边
			var i:int;
			var j:int;
			var realIndex:Vector.<int> = new Vector.<int>(edgeCount);
			for (i = 0; i < edgeCount; i ++)
				realIndex[i] = i;
			for (i = 1; i < edgeCount; i ++)
			{
				for (j = 0; j < i; j ++)
				{
					if ((_edges[i].vertex0 == _edges[j].vertex0 && _edges[i].vertex1 == _edges[j].vertex1) || 
						(_edges[i].vertex0 == _edges[j].vertex1 && _edges[i].vertex1 == _edges[j].vertex0))
					{
						realIndex[i] = realIndex[j];
						break;
					}
				}
			}
			
			//移除重复的边
			for (i = edgeCount - 1; i >= 0; i --)
				if (realIndex[i] != i)
				{
					_edges[i].dispose();
					_edges.splice(i, 1);
				}
		}
		
		/**
		 * 若某条边上有顶点，切割这条边。
		 * 
		 */		
		public function splitEdge():void
		{
			var vertex:SUVertex;
			var edge:SUEdge;
			for each (vertex in _vertices) //更新顶点的度
			{
				vertex.updateDegree();
			}
			var i:int;
			
			for (i = edgeCount - 1; i >= 0; i --)
			{
				edge = _edges[i];
				for each (vertex in _vertices)
				{
					if (vertex.degree == 1) //只有度为1的顶点才可能分割别的边
					{
						if (LatticeMesh.isVertexOnEdge(vertex, edge))
						{
							var edge0:SUEdge = instantiateEdge(edge.vertex0, vertex);
							var edge1:SUEdge = instantiateEdge(edge.vertex1, vertex);
							edge0.copyAttributeFromAnotherEdge(edge);
							edge1.copyAttributeFromAnotherEdge(edge);
							edge.dispose();
							_edges.splice(i, 1);
							_edges.splice(i, 0, edge0, edge1);
							break;
						}
					}
				}
			}
		}
		
		/**
		 * 判断顶点是否在边上。
		 * @param vertex
		 * @param edge
		 * @return 
		 * 
		 */		
		public static function isVertexOnEdge(vertex:SUVertex, edge:SUEdge):Boolean
		{
			return MyMath.isPoint3DOnSegment3D(edge.vertex0.position, edge.vertex1.position, vertex.position);
		}
		
		/**
		 * 合并。
		 * @param latticeMeshArr
		 * @return 
		 * 
		 */		
		public function mergeSubs(latticeMeshArr:Vector.<LatticeMesh>):void
		{
			//合并顶点和边
			var vs:Vector.<SUVertex> = new Vector.<SUVertex>();
			var es:Vector.<SUEdge> = new Vector.<SUEdge>();
			for each (var lm:LatticeMesh in latticeMeshArr)
			{
				MyMath.mergeTwoArray(vs, lm.vertices, true);
				MyMath.mergeTwoArray(es, lm.edges, true);
				lm.vertices = null;
				lm.edges = null;
			}
			for each (var v:SUVertex in vs)
			{
				v.position.copyFrom(v.parent.localToGlobalMatrix.transformVector(v.position));
				v.parent = this;
			}
			for each (var e:SUEdge in es)
			{
				e.parent = this;
			}
			
			//根据顶点和边初始化
			this.initByVerticesAndEdge(vs, es);
		}
		
		override public function toString():String
		{
			return "[LatticeMesh:" + name + "]" + "vertexCount：" + vertexCount + "，edgeCount：" + edgeCount;
		}
		
		/**
		 * 保存为Object
		 * @return 
		 * 
		 */		
		public function toObject():Object
		{
			var ret:Object = {};
			ret.name = name;
			ret.funcName = funcName;
			
			var vertices:Array = [];
			var edges:Array = [];
			ret.vertices = vertices;
			ret.edges = edges;
			for each (var vertex:SUVertex in _vertices)
			{
				vertices.push(vertex.toObject());
			}
			for each (var edge:SUEdge in _edges)
			{
				edges.push(edge.toObject());
			}
			
			return ret;
		}
		
		public function fromObject(obj:Object):void
		{
			this.name = obj.name;
			this.funcName = obj.funcName;
			
			var tmp:Object;
			for each (tmp in obj.vertices)
			{
				var vertex:SUVertex = instantiateVertex(new Vector3D(tmp.x, tmp.y, tmp.z));
				vertex.parent = this;
				_vertices.push(vertex);
			}
			for each (tmp in obj.edges)
			{
				var edge:SUEdge = instantiateEdge(_vertices[tmp.startIndex], _vertices[tmp.stopIndex]);
				edge.color = new HexColor(tmp.color);
				edge.parent = this;
				_edges.push(edge);
			}
			rebuild();
		}
	}
}