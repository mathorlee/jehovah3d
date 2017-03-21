package panorama.culling
{
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import panorama.geometry.Triangle;
	import panorama.geometry.Vertex;

	public class CalculateCulling
	{
		public function CalculateCulling()
		{
		}
		
		/**
		 * calcualte line plane intersection. return an object. 
		 * @param line
		 * @param plane
		 * @return 
		 * 
		 */		
		public static function linePlaneIntersection(line:Line, plane:Plane):Object
		{
			var ret:Object = new Object();
			
			/*
			plane: (x - plane.p0) * plane.dir = 0;
			line:  line.p0 + line.dir * t;
			
			(line.p0 - plane.p0 + line.dir * t) * plane.dir = 0;
			t * (line.dir * plane.dir) = (plane.p0 - line.p0) * plane.dir
			*/
			
			var t:Number = plane.p0.subtract(line.p0).dotProduct(plane.dir) / line.dir.dotProduct(plane.dir);
			ret.t = t;
			ret.point = line.p0.add(new Vector3D(line.dir.x * t, line.dir.y * t, line.dir.z * t));
			return ret;
		}
		
		
		/**
		 * plane cut triangle into pieces. 
		 * @param triangle
		 * @param plane
		 * @return 
		 * 
		 */		
		public static function planeCutTriangle(triangle:Triangle, plane:Plane):Vector.<Triangle>
		{
			var ret:Vector.<Triangle> = new Vector.<Triangle>();
			var s1:Boolean = plane.whichSideIsPointAt(triangle.va.position);
			var s2:Boolean = plane.whichSideIsPointAt(triangle.vb.position);
			var s3:Boolean = plane.whichSideIsPointAt(triangle.vc.position);
			
			var intersect1:Object;
			var intersect2:Object;
			var vertex1:Vertex;
			var vertex2:Vertex;
			
			if(s1)
			{
				if(s2)
				{
					if(s3) //111
					{
						ret.push(triangle);
					}
					else //110
					{
						intersect1 = linePlaneIntersection(new Line(triangle.vc.position, triangle.va.position), plane);
						intersect2 = linePlaneIntersection(new Line(triangle.vb.position, triangle.vc.position), plane);
						vertex1 = new Vertex(
							intersect1.point as Vector3D, 
							triangle.vc.uv.add(new Point(intersect1.t / triangle.lengthCA * triangle.uvCA.x, intersect1.t / triangle.lengthCA * triangle.uvCA.y))
						);
						vertex2 = new Vertex(
							intersect2.point as Vector3D, 
							triangle.vb.uv.add(new Point(intersect2.t / triangle.lengthBC * triangle.uvBC.x, intersect2.t / triangle.lengthBC * triangle.uvBC.y))
						);
						ret.push(new Triangle(triangle.va, triangle.vb, vertex2));
						ret.push(new Triangle(triangle.va, vertex2, vertex1));
					}
				}
				else
				{
					if(s3) //101
					{
						intersect1 = linePlaneIntersection(new Line(triangle.va.position, triangle.vb.position), plane);
						intersect2 = linePlaneIntersection(new Line(triangle.vb.position, triangle.vc.position), plane);
						vertex1 = new Vertex(
							intersect1.point as Vector3D, 
							triangle.va.uv.add(new Point(intersect1.t / triangle.lengthAB * triangle.uvAB.x, intersect1.t / triangle.lengthAB * triangle.uvAB.y))
						);
						vertex2 = new Vertex(
							intersect2.point as Vector3D, 
							triangle.vb.uv.add(new Point(intersect2.t / triangle.lengthBC * triangle.uvBC.x, intersect2.t / triangle.lengthBC * triangle.uvBC.y))
						);
						ret.push(new Triangle(triangle.va, vertex1, vertex2));
						ret.push(new Triangle(triangle.va, vertex2, triangle.vc));
					}
					else //100
					{
						intersect1 = linePlaneIntersection(new Line(triangle.va.position, triangle.vb.position), plane);
						intersect2 = linePlaneIntersection(new Line(triangle.vc.position, triangle.va.position), plane);
						vertex1 = new Vertex(
							intersect1.point as Vector3D, 
							triangle.va.uv.add(new Point(intersect1.t / triangle.lengthAB * triangle.uvAB.x, intersect1.t / triangle.lengthAB * triangle.uvAB.y))
						);
						vertex2 = new Vertex(
							intersect2.point as Vector3D, 
							triangle.vc.uv.add(new Point(intersect2.t / triangle.lengthCA * triangle.uvCA.x, intersect2.t / triangle.lengthCA * triangle.uvCA.y))
						);
						ret.push(new Triangle(triangle.va, vertex1, vertex2));
					}
				}
			}
			else
			{
				if(s2)
				{
					if(s3) //011
					{
						intersect1 = linePlaneIntersection(new Line(triangle.va.position, triangle.vb.position), plane);
						intersect2 = linePlaneIntersection(new Line(triangle.vc.position, triangle.va.position), plane);
						vertex1 = new Vertex(
							intersect1.point as Vector3D, 
							triangle.va.uv.add(new Point(intersect1.t / triangle.lengthAB * triangle.uvAB.x, intersect1.t / triangle.lengthAB * triangle.uvAB.y))
						);
						vertex2 = new Vertex(
							intersect2.point as Vector3D, 
							triangle.vc.uv.add(new Point(intersect2.t / triangle.lengthCA * triangle.uvCA.x, intersect2.t / triangle.lengthCA * triangle.uvCA.y))
						);
						ret.push(new Triangle(triangle.vb, triangle.vc, vertex2));
						ret.push(new Triangle(triangle.vb, vertex2, vertex1));
					}
					else //010
					{
						intersect1 = linePlaneIntersection(new Line(triangle.va.position, triangle.vb.position), plane);
						intersect2 = linePlaneIntersection(new Line(triangle.vb.position, triangle.vc.position), plane);
						vertex1 = new Vertex(
							intersect1.point as Vector3D, 
							triangle.va.uv.add(new Point(intersect1.t / triangle.lengthAB * triangle.uvAB.x, intersect1.t / triangle.lengthAB * triangle.uvAB.y))
						);
						vertex2 = new Vertex(
							intersect2.point as Vector3D, 
							triangle.vb.uv.add(new Point(intersect2.t / triangle.lengthBC * triangle.uvBC.x, intersect2.t / triangle.lengthBC * triangle.uvBC.y))
						);
						ret.push(new Triangle(triangle.vb, vertex2, vertex1));
					}
				}
				else
				{
					if(s3) //001
					{
						intersect1 = linePlaneIntersection(new Line(triangle.vc.position, triangle.va.position), plane);
						intersect2 = linePlaneIntersection(new Line(triangle.vb.position, triangle.vc.position), plane);
						vertex1 = new Vertex(
							intersect1.point as Vector3D, 
							triangle.vc.uv.add(new Point(intersect1.t / triangle.lengthCA * triangle.uvCA.x, intersect1.t / triangle.lengthCA * triangle.uvCA.y))
						);
						vertex2 = new Vertex(
							intersect2.point as Vector3D, 
							triangle.vb.uv.add(new Point(intersect2.t / triangle.lengthBC * triangle.uvBC.x, intersect2.t / triangle.lengthBC * triangle.uvBC.y))
						);
						ret.push(new Triangle(triangle.vc, vertex1, vertex2));
					}
					else //000
					{
						
					}
				}
			}
			return ret;
		}
		
		
		/**
		 * frustum cut triangles. 
		 * @param frustum
		 * @param inputTriangles
		 * @return 
		 * 
		 */		
		public static function frustumCutTriangles(frustum:Frustum, inputTriangles:Vector.<Triangle>):Vector.<Triangle>
		{
			var i:int;
			var j:int;
			var arr1:Vector.<Triangle>;
			var arr2:Vector.<Triangle>;
			var tmp:Vector.<Triangle>;
			
			arr1 = inputTriangles;
			arr2 = new Vector.<Triangle>();
			for(i = 0; i < arr1.length; i ++)
			{
				//arr2 += top.cut(arr1[i]);
				tmp = planeCutTriangle(arr1[i], frustum.top);
				for(j = 0; j < tmp.length; j ++)
					arr2.push(tmp[j]);
			}
			
			arr1 = arr2;
			arr2 = new Vector.<Triangle>();
			for(i = 0; i < arr1.length; i ++)
			{
				//arr2 += bottom.cut(arr1[i]);
				tmp = planeCutTriangle(arr1[i], frustum.bottom);
				for(j = 0; j < tmp.length; j ++)
					arr2.push(tmp[j]);
			}
			
			arr1 = arr2;
			arr2 = new Vector.<Triangle>();
			for(i = 0; i < arr1.length; i ++)
			{
				//arr2 += left.cut(arr1[i]);
				tmp = planeCutTriangle(arr1[i], frustum.left);
				for(j = 0; j < tmp.length; j ++)
					arr2.push(tmp[j]);
			}
			
			arr1 = arr2;
			arr2 = new Vector.<Triangle>();
			for(i = 0; i < arr1.length; i ++)
			{
				//arr2 += right.cut(arr1[i]);
				tmp = planeCutTriangle(arr1[i], frustum.right);
				for(j = 0; j < tmp.length; j ++)
					arr2.push(tmp[j]);
			}
			
			arr1 = arr2;
			arr2 = new Vector.<Triangle>();
			for(i = 0; i < arr1.length; i ++)
			{
				//arr2 += front.cut(arr1[i]);
				tmp = planeCutTriangle(arr1[i], frustum.front);
				for(j = 0; j < tmp.length; j ++)
					arr2.push(tmp[j]);
			}
//			
//			arr1 = arr2;
//			arr2 = new Vector.<Triangle>();
//			for(i = 0; i < arr1.length; i ++)
//			{
//				//arr2 += back.cut(arr1[i]);
//				tmp = planeCutTriangle(arr1[i], frustum.back);
//				for(j = 0; j < tmp.length; j ++)
//					arr2.push(tmp[j]);
//			}
//			
			return arr2;
		}
	}
}