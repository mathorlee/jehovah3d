package jehovah3d.core.wireframe
{
	import flash.display3D.Context3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.Bounding;
	import jehovah3d.core.Context3DProperty;
	import jehovah3d.core.Object3D;
	import jehovah3d.core.material.DiffuseMtl;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.pick.MousePickData;
	import jehovah3d.core.pick.MousePickManager;
	import jehovah3d.core.pick.Plane;
	import jehovah3d.core.pick.Ray;
	import jehovah3d.core.pick.RectFace;
	import jehovah3d.core.renderer.Renderer;
	import jehovah3d.core.renderer.WireFrameRenderer;
	import jehovah3d.core.resource.GeometryResource;
	import jehovah3d.util.HexColor;
	
	public class WireFrame extends Mesh
	{
		protected var _vertexList:Vector.<Vector3D>;
		private var _lineCount:uint;
		private var _thickness:Number;
		private var cameraSpaceVertices:Vector.<Vector3D> = new Vector.<Vector3D>();
		
		public function WireFrame(vertexList:Vector.<Vector3D>, color:uint, thickness:Number)
		{
			_geometry = new GeometryResource();
			_vertexList = vertexList.slice();
			_lineCount = _vertexList.length / 2;
			_mtl = new DiffuseMtl();
			_mtl.diffuseColor = new HexColor(color, 1);
			_thickness = thickness;
			mouseEnabled = false;
		}
		
		override public function updateHierarchyMatrix_CameraFinal():void
		{
			if(!visible)
				return ;
			cameraSpaceVertices.length = 0;
			var i:int;
			for(i = 0; i < _vertexList.length; i ++)
				cameraSpaceVertices.push(localToCameraMatrix.transformVector(_vertexList[i]));
			var plane:Plane = new Plane(new Vector3D(0, 0, -Jehovah.camera.zNear), new Vector3D(0, 0, -1));
			var s1:Number;
			var s2:Number;
			var intersect:Object;
			var ray:Ray;
			var dir:Vector3D;
			var v1:Vector3D;
			var v2:Vector3D;
			for(i = 0; i < _lineCount; i ++) //线的起点终点，如果有一个在视椎外（nearClipping），则砍断它。
			{
				v1 = cameraSpaceVertices[i * 2];
				v2 = cameraSpaceVertices[i * 2 + 1];
				s1 = plane.whichSideIsPointAt(v1);
				s2 = plane.whichSideIsPointAt(v2);
				if(s1 * s2 < 0)
				{
					dir = v2.subtract(v1);
					dir.normalize();
					ray = new Ray(v1, dir);
					intersect = MousePickManager.rayPlaneIntersect(ray, plane);
					if(s1 > 0)
						v2.copyFrom(intersect.point);
					else if(s2 > 0)
						v1.copyFrom(intersect.point);
				}
			}
			
			var coordinateData:Vector.<Number> = new Vector.<Number>();
			var indexData:Vector.<uint> = new Vector.<uint>();
			for(i = 0; i < _lineCount; i ++)
			{
				v1 = cameraSpaceVertices[i * 2];
				v2 = cameraSpaceVertices[i * 2 + 1];
				var currentVertexCount:uint = coordinateData.length / 3;
				var cp:Vector3D;
				var d1:Number;
				var d2:Number;
				if(Jehovah.camera.orthographic)
				{
					cp = new Vector3D(0, 0, -1).crossProduct(v2.subtract(v1));
					d1 = d2 = _thickness;
				}
				else
				{
					cp = v1.crossProduct(v2);
					d1 = -v1.z / Jehovah.camera.focalLength * _thickness;
					d2 = -v2.z / Jehovah.camera.focalLength * _thickness;
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
				indexData.push(
					currentVertexCount + 0, 
					currentVertexCount + 1, 
					currentVertexCount + 2, 
					currentVertexCount + 0, 
					currentVertexCount + 2, 
					currentVertexCount + 3
				);
			}
			_geometry.coordinateData = coordinateData;
			_geometry.indexData = indexData;
			_geometry.upload(Jehovah.context3D);
		}
		
		override public function mousePick(ray:Ray, mousePoint:Point = null):void
		{
			if(!mouseEnabled || !visible || !Jehovah.camera.wfPickable)
				return ;
			
			var rayCopy:Ray = new Ray(Jehovah.camera.inverseMatrix.transformVector(ray.p0), Jehovah.camera.inverseMatrix.deltaTransformVector(ray.dir));
			var i:int;
			var dist:Number;
			var tmpDist:Number;
			var rectface:RectFace;
			var intersect:Vector3D;
			
			var pickThickness:Number = Jehovah.camera.wfPickTolerance; //厚度为0的线是无法被鼠标拾取的。把线变厚，有容差的存在。
			for(i = 0; i < _lineCount; i ++)
			{
				var v1:Vector3D = cameraSpaceVertices[i * 2];
				var v2:Vector3D = cameraSpaceVertices[i * 2 + 1];
				var cp:Vector3D;
				var d1:Number;
				var d2:Number;
				
				if(Jehovah.camera.orthographic)
				{
					cp = new Vector3D(0, 0, -1).crossProduct(v2.subtract(v1));
					d1 = d2 = pickThickness;
				}
				else
				{
					cp = v1.crossProduct(v2);
					d1 = -v1.z / Jehovah.camera.focalLength * pickThickness;
					d2 = -v2.z / Jehovah.camera.focalLength * pickThickness;
					if(d1 < 0)
						d1 = 0;
					if(d2 < 0)
						d2 = 0;
				}
				cp.normalize();
				rectface = new RectFace(
					new Vector3D(v1.x - cp.x * d1 / 2, v1.y - cp.y * d1 / 2, v1.z - cp.z * d1 / 2), 
					new Vector3D(v1.x + cp.x * d1 / 2, v1.y + cp.y * d1 / 2, v1.z + cp.z * d1 / 2), 
					new Vector3D(v2.x - cp.x * d2 / 2, v2.y - cp.y * d2 / 2, v2.z - cp.z * d2 / 2)
				);
				intersect = MousePickManager.rayRectFaceIntersect(rayCopy, rectface, false, false);
				if(intersect)
				{
					tmpDist = intersect.subtract(rayCopy.p0).length;
					if((dist && tmpDist < dist) || !dist)
						dist = tmpDist;
				}
			}
			if(dist)
				MousePickManager.add(new MousePickData(this, dist));
		}
		
		override public function get bounding():Bounding
		{
			var i:int;
			var bb:Bounding = childrenBounding;
			var geobb:Bounding = new Bounding();
			for(i = 0; i < _vertexList.length; i ++)
			{
				geobb.minX = Math.min(geobb.minX, _vertexList[i].x);
				geobb.maxX = Math.max(geobb.maxX, _vertexList[i].x);
				geobb.minY = Math.min(geobb.minY, _vertexList[i].y);
				geobb.maxY = Math.max(geobb.maxY, _vertexList[i].y);
				geobb.minZ = Math.min(geobb.minZ, _vertexList[i].z);
				geobb.maxZ = Math.max(geobb.maxZ, _vertexList[i].z);
			}
			bb.minX = Math.min(bb.minX, geobb.minX);
			bb.minY = Math.min(bb.minY, geobb.minY);
			bb.minZ = Math.min(bb.minZ, geobb.minZ);
			bb.maxX = Math.max(bb.maxX, geobb.maxX);
			bb.maxY = Math.max(bb.maxY, geobb.maxY);
			bb.maxZ = Math.max(bb.maxZ, geobb.maxZ);
			bb.calculateDimension();
			return bb;
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
		
		private function renderWF(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			var no:String = WireFrameRenderer.NAME;
			if(!rendererDict[no])
				rendererDict[no] = new WireFrameRenderer(this);
			Renderer(rendererDict[no]).render(context3D, context3DProperty);
		}
		
		override public function collectRenderList(opaqueRenderList:Vector.<Object3D>, transparentRenderList:Vector.<Object3D>):void
		{
			if(!visible)
				return ;
			opaqueRenderList.push(this);
			super.collectChildrenRenderList(opaqueRenderList, transparentRenderList);
		}
		
		override public function dispose():void
		{
			super.dispose();
			if(_vertexList)
				_vertexList.length = 0;
		}
		public function get vertexList():Vector.<Vector3D>
		{
			return _vertexList;
		}
		public function set vertexList(value:Vector.<Vector3D>):void
		{
			_vertexList = value.slice();
			_lineCount = _vertexList.length / 2;
		}
		public function set halfVertexList(value:Vector.<Vector3D>):void
		{
			if(value.length < 2)
				return ;
			_vertexList.length = 0;
			_vertexList.push(value[0]);
			var i:int;
			for(i = 1; i < value.length - 1; i ++)
				_vertexList.push(value[i], value[i]);
			_vertexList.push(value[value.length - 1]);
			_lineCount = _vertexList.length / 2;
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
		}
		
		public static function generateBoxVertexList(width:Number, length:Number, height:Number):Vector.<Vector3D>
		{
			var ret:Vector.<Vector3D> = new Vector.<Vector3D>();
			
			var x0:Number = width * 0.5;
			var y0:Number = length * 0.5;
			
			ret.push(
				new Vector3D(x0, y0, 0), 
				new Vector3D(-x0, y0, 0), 
				new Vector3D(-x0, y0, 0), 
				new Vector3D(-x0, -y0, 0), 
				new Vector3D(-x0, -y0, 0), 
				new Vector3D(x0, -y0, 0),  
				new Vector3D(x0, -y0, 0), 
				new Vector3D(x0, y0, 0), 
				
				new Vector3D(x0, y0, height), 
				new Vector3D(-x0, y0, height), 
				new Vector3D(-x0, y0, height), 
				new Vector3D(-x0, -y0, height), 
				new Vector3D(-x0, -y0, height), 
				new Vector3D(x0, -y0, height),  
				new Vector3D(x0, -y0, height), 
				new Vector3D(x0, y0, height), 
				
				new Vector3D(x0, y0, 0), 
				new Vector3D(x0, y0, height), 
				new Vector3D(-x0, y0, 0), 
				new Vector3D(-x0, y0, height),
				new Vector3D(-x0, -y0, 0), 
				new Vector3D(-x0, -y0, height), 
				new Vector3D(x0, -y0, 0),  
				new Vector3D(x0, -y0, height)
			);
			
			return ret;
		}
		
		override public function toString():String
		{
			return "[WireFrame:" + name + "]";
		}
	}
}