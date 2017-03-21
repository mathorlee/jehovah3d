package jehovah3d.util
{
	import com.fuwo.math.MyMath;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.GeometryResource;

	/**
	 * Mesh生成器。
	 * @author lisongsong
	 * 
	 */	
	public class MeshMaker
	{
		public function MeshMaker()
		{
			
		}
		
		/**
		 * 生成球体Mesh。不切割uv。全景图的球体需要切割uv。
		 * @param coordinateData
		 * @param indexData
		 * @param radius
		 * @param sectionSubdivision
		 * @param matrix
		 * 
		 */		
		public static function generateSphereGeometryDoNotSplitUV(coordinateData:Vector.<Number>, indexData:Vector.<uint>, radius:Number, sectionSubdivision:int, matrix:Matrix3D):void
		{
			var n:int = sectionSubdivision;
			var m:int = n / 2;
			
			var i:int;
			var j:int;
			var oldNumV:int = coordinateData.length / 3;
			
			//添加n*(m-1)+2个顶点
			for (i = 0; i < n; i ++)
			{
				var alpha:Number = Math.PI * 2 * i / n;
				for (j = 0; j < m - 1; j ++)
				{
					var beta:Number = -Math.PI / 2 + Math.PI / m * (j + 1);
					coordinateData.push(Math.cos(beta) * Math.cos(alpha) * radius, Math.cos(beta) * Math.sin(alpha) * radius, Math.sin(beta) * radius);
				}
			}
			coordinateData.push(0, 0, -radius, 0, 0, radius);
			
			//添加n*(m-2)*2+n*2个三角形
			for (i = 0; i < n; i ++)
			{
				var t0:int = (m - 1) * i + oldNumV;
				var t1:int = (m - 1) * MyMath.nextIndex(i, n) + oldNumV;
				for (j = 0; j < m - 2; j ++)
				{
					indexData.push(
						t0 + j, t1 + j, t1 + j + 1, 
						t0 + j, t1 + j + 1, t0 + j + 1
					);
				}
				
				indexData.push(n * (m - 1) + oldNumV, t1, t0);
				indexData.push(n * (m - 1) + 1 + oldNumV, t0 + m - 2, t1 + m - 2);
			}
			
			//矩阵置换
			if (matrix)
			{
				var tmpV:Vector3D;
				for (i = oldNumV; i < coordinateData.length / 3; i ++)
				{
					tmpV = matrix.transformVector(new Vector3D(coordinateData[i * 3], coordinateData[i * 3 + 1], coordinateData[i * 3 + 2]));
					coordinateData[i * 3] = tmpV.x;
					coordinateData[i * 3 + 1] = tmpV.y;
					coordinateData[i * 3 + 2] = tmpV.z;
				}
			}
		}
		
		/**
		 * 生成圆柱Mesh
		 * @param coordinateData
		 * @param indexData
		 * @param radius
		 * @param sectionSubdivision
		 * @param cylinderHeight
		 * @param matrix
		 * 
		 */		
		public static function generateCylinderGeometry(coordinateData:Vector.<Number>, indexData:Vector.<uint>, radius:Number, sectionSubdivision:int, cylinderHeight:Number, matrix:Matrix3D):void
		{
			var i:int;
			var sins:Vector.<Number> = new Vector.<Number>();
			var coss:Vector.<Number> = new Vector.<Number>();
			for (i = 0; i < sectionSubdivision; i ++)
			{
				sins.push(Math.sin(Math.PI * 2 * i / sectionSubdivision));
				coss.push(Math.cos(Math.PI * 2 * i / sectionSubdivision));
			}
			
			var tmp:int;
			var tmpNext:int;
			var oldNumV:int = coordinateData.length / 3;
			
			//下圆面
			var t:int = oldNumV;
			coordinateData.push(0, 0, 0);
			for (i = 0; i < sectionSubdivision; i ++)
			{
				coordinateData.push(coss[i] * radius, sins[i] * radius, 0);
				indexData.push(t, t + MyMath.nextIndex(i, sectionSubdivision) + 1, t + i + 1);
			}
			
			//上圆面
			t = coordinateData.length / 3;
			coordinateData.push(0, 0, cylinderHeight);
			for (i = 0; i < sectionSubdivision; i ++)
			{
				coordinateData.push(coss[i] * radius, sins[i] * radius, cylinderHeight);
				indexData.push(t, t + i + 1, t + MyMath.nextIndex(i, sectionSubdivision) + 1);
			}
			
			//侧面
			t = coordinateData.length / 3;
			for (i = 0; i < sectionSubdivision; i ++)
			{
				tmp = t + 2 * i;
				tmpNext = t + 2 * (MyMath.nextIndex(i, sectionSubdivision));
				coordinateData.push(
					coss[i] * radius, sins[i] * radius, 0, 
					coss[i] * radius, sins[i] * radius, cylinderHeight
				);
				indexData.push(tmpNext + 1, tmp + 1, tmp , tmpNext + 1, tmp , tmpNext);
			}
			
			//矩阵置换
			if (matrix)
			{
				var tmpV:Vector3D;
				for (i = oldNumV; i < coordinateData.length / 3; i ++)
				{
					tmpV = matrix.transformVector(new Vector3D(coordinateData[i * 3], coordinateData[i * 3 + 1], coordinateData[i * 3 + 2]));
					coordinateData[i * 3] = tmpV.x;
					coordinateData[i * 3 + 1] = tmpV.y;
					coordinateData[i * 3 + 2] = tmpV.z;
				}
			}
		}
		
		/**
		 * 生成管道Mesh
		 * @param coordinateData
		 * @param indexData
		 * @param insideRadius
		 * @param outsideRadius
		 * @param sectionSubdivision
		 * @param pipeLength
		 * @param matrix
		 * 
		 */		
		public static function generatePipeGeometry(coordinateData:Vector.<Number>, indexData:Vector.<uint>, insideRadius:Number, outsideRadius:Number, sectionSubdivision:int, pipeLength:Number, matrix:Matrix3D):void
		{
			var i:int;
			var sins:Vector.<Number> = new Vector.<Number>();
			var coss:Vector.<Number> = new Vector.<Number>();
			for (i = 0; i < sectionSubdivision; i ++)
			{
				sins.push(Math.sin(Math.PI * 2 * i / sectionSubdivision));
				coss.push(Math.cos(Math.PI * 2 * i / sectionSubdivision));
			}
			
			var tmp:int;
			var tmpNext:int;
			var oldNumV:int = coordinateData.length / 3;
			var t:int = oldNumV;
			for (i = 0; i < sectionSubdivision; i ++)
			{
				tmp = t + 2 * i;
				tmpNext = t + 2 * (MyMath.nextIndex(i, sectionSubdivision));
				coordinateData.push(
					coss[i] * insideRadius, sins[i] * insideRadius, 0, 
					coss[i] * outsideRadius, sins[i] * outsideRadius, 0
				);
				indexData.push(tmp + 1, tmp, tmpNext, tmp + 1, tmpNext, tmpNext + 1);
			}
			
			t = coordinateData.length / 3;
			for (i = 0; i < sectionSubdivision; i ++)
			{
				tmp = t + 2 * i;
				tmpNext = t + 2 * (MyMath.nextIndex(i, sectionSubdivision));
				coordinateData.push(
					coss[i] * insideRadius, sins[i] * insideRadius, pipeLength, 
					coss[i] * outsideRadius, sins[i] * outsideRadius, pipeLength
				);
				indexData.push(tmp + 1, tmpNext + 1, tmpNext, tmp + 1, tmpNext, tmp );
			}
			
			t = coordinateData.length / 3;
			for (i = 0; i < sectionSubdivision; i ++)
			{
				tmp = t + 2 * i;
				tmpNext = t + 2 * (MyMath.nextIndex(i, sectionSubdivision));
				coordinateData.push(
					coss[i] * insideRadius, sins[i] * insideRadius, 0, 
					coss[i] * insideRadius, sins[i] * insideRadius, pipeLength
				);
				indexData.push(tmp + 1, tmpNext + 1, tmpNext, tmp + 1, tmpNext, tmp );
			}
			
			t = coordinateData.length / 3;
			for (i = 0; i < sectionSubdivision; i ++)
			{
				tmp = t + 2 * i;
				tmpNext = t + 2 * (MyMath.nextIndex(i, sectionSubdivision));
				coordinateData.push(
					coss[i] * outsideRadius, sins[i] * outsideRadius, 0, 
					coss[i] * outsideRadius, sins[i] * outsideRadius, pipeLength
				);
				indexData.push(tmpNext + 1, tmp + 1, tmp , tmpNext + 1, tmp , tmpNext);
			}
			
			if (matrix) //矩阵置换一下
			{
				var tmpV:Vector3D;
				for (i = oldNumV; i < coordinateData.length / 3; i ++)
				{
					tmpV = matrix.transformVector(new Vector3D(coordinateData[i * 3], coordinateData[i * 3 + 1], coordinateData[i * 3 + 2]));
					coordinateData[i * 3] = tmpV.x;
					coordinateData[i * 3 + 1] = tmpV.y;
					coordinateData[i * 3 + 2] = tmpV.z;
				}
			}
		}
		
		public static function generateMesh(coordinateData:Vector.<Number>, diffuseUVData:Vector.<Number>, lightUVData:Vector.<Number>, indexData:Vector.<uint>, name:String):Mesh
		{
			var ret:Mesh = new Mesh();
			ret.geometry = new GeometryResource();
			if(coordinateData)
				ret.geometry.coordinateData = coordinateData;
			if(diffuseUVData)
				ret.geometry.diffuseUVData = diffuseUVData;
			if(lightUVData)
				ret.geometry.lightUVData = lightUVData;
			if(indexData)
				ret.geometry.indexData = indexData;
			if(name)
				ret.name = name;
			return ret;
		}
		
		
		public static function fillMesh(mesh:Mesh, coordinateData:Vector.<Number>, diffuseUVData:Vector.<Number>, lightUVData:Vector.<Number>, indexData:Vector.<uint>, name:String):void
		{
			mesh.geometry = new GeometryResource();
			if(coordinateData)
				mesh.geometry.coordinateData = coordinateData;
			if(diffuseUVData)
				mesh.geometry.diffuseUVData = diffuseUVData;
			if(lightUVData)
				mesh.geometry.lightUVData = lightUVData;
			if(indexData)
				mesh.geometry.indexData = indexData;
			if(name)
				mesh.name = name;
		}
		
		public static function generateQuadGeometryIndicesByNumVertices(numVertices:int):Vector.<uint>
		{
			var ret:Vector.<uint> = new Vector.<uint>();
			var i:int;
			for(i = 0; i < numVertices / 4; i ++)
				ret.push(0 + 4 * i, 1 + 4 * i, 2 + 4 * i, 0 + 4 * i, 2 + 4 * i, 3 + 4 * i);
			return ret;
		}
		
		/**
		 * 根据长宽高生成立方体的8个顶点。轴心点是地面中心点。
		 * @param width
		 * @param length
		 * @param height
		 * 
		 */		
		public static function generateEightPointsOfBox(width:Number, length:Number, height:Number):Vector.<Vector3D>
		{
			var ret:Vector.<Vector3D> = new Vector.<Vector3D>();
			ret.push(new Vector3D(width / 2, length / 2, 0));
			ret.push(new Vector3D(-width / 2, length / 2, 0));
			ret.push(new Vector3D(-width / 2, -length / 2, 0));
			ret.push(new Vector3D(width / 2, -length / 2, 0));
			ret.push(new Vector3D(width / 2, length / 2, height));
			ret.push(new Vector3D(-width / 2, length / 2, height));
			ret.push(new Vector3D(-width / 2, -length / 2, height));
			ret.push(new Vector3D(width / 2, -length / 2, height));
			return ret;
		}
	}
}