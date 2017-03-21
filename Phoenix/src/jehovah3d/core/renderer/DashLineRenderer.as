package jehovah3d.core.renderer
{
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Matrix3D;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.ShaderResource;
	
	/**
	 * 虚线Renderer
	 * @author lisongsong
	 * 
	 */	
	public class DashLineRenderer extends Renderer
	{
		public static const NAME:String = "DashLineRenderer";
		
		public var depthOffset:Number = 1;
		public var useDepthOffset:Boolean = true;
		
		public function DashLineRenderer(mesh:Mesh)
		{
			super(mesh);
		}
		
		override public function collectResource():void
		{
			vertexConstants.length = 0;
			fragmentConstants.length = 0;
			
			vertexBuffers.length = 0;
			vertexBufferIndices.length = 0;
			vertexBufferFormats.length = 0;
			
			textures.length = 0;
			textureSamplers.length = 0;
			
			var assetsDict:Dictionary = new Dictionary();
			var index:int;
			assetsDict[C_FINALMATRIX] = currentVC();
			var pm:Matrix3D = Jehovah.camera.pm;
			Renderer.dunkM44(pm, vertexConstants);
			index = currentVCIndex();
			assetsDict[C_LINE_DEPTH_OFFSET] = new ShaderConstant(ShaderConstant.VERTEX_CONSTANT, index, "x");
			vertexConstants.push(depthOffset, 0, 0, 0);
			
			//push coordinate buffer
			if(mesh.geometry.coordinateBuffer)
			{
				vertexBuffers.push(mesh.geometry.coordinateBuffer);
				vertexBufferIndices.push(0);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
				assetsDict[V_COORDINATE] = "v0"; //va0/v0: coordinate buffer.
				assetsDict[VA_COORDINATE] = "va0";
			}
			if (mesh.geometry.vertexColorBuffer)
			{
				vertexBuffers.push(mesh.geometry.vertexColorBuffer);
				vertexBufferIndices.push(1);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
				assetsDict[V_COLOR] = "v1"; //va1/v1: vertexColor buffer.
				assetsDict[VA_COLOR] = "va1";
			}
			if (mesh.geometry.normalBuffer) //线的coordinate，不考虑厚度！
			{
				vertexBuffers.push(mesh.geometry.normalBuffer);
				vertexBufferIndices.push(2);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
				assetsDict[V_NORMAL] = "v2";
				assetsDict[VA_NORMAL] = "va2";
			}
			if (mesh.geometry.tangentBuffer) //线起点的屏幕投影坐标
			{
				vertexBuffers.push(mesh.geometry.tangentBuffer);
				vertexBufferIndices.push(3);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
				assetsDict[V_TANGENT] = "v3";
				assetsDict[VA_TANGENT] = "va3";
			}
			
			//投影矩阵
			assetsDict[C_PROJECTION_MATRIX] = currentFC();
			Renderer.dunkM44(pm, fragmentConstants);
			
			//屏幕尺寸
			assetsDict[C_SCREEN_SIZE] = currentFC();
			fragmentConstants.push(Jehovah.camera.viewWidth, Jehovah.camera.viewHeight, 0, 0);
			
			//几个常数：2, 0, 0.5
			index = currentFCIndex();
			assetsDict[C_TWO] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "x");
			assetsDict[C_ZERO] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "y");
			assetsDict[C_HALF] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "z");
			fragmentConstants.push(20, 0, 0.5, 0);
			
			if(!_shader)
			{
				_shader = new ShaderResource();
				_shader.vertexShaderString = generateVertexShader(assetsDict);
				_shader.fragmentShaderString = generateFragmentShader(assetsDict);
//				trace(_shader.vertexShaderString);
//				trace(_shader.fragmentShaderString);
				_shader.upload(Jehovah.context3D);
			}
		}
		
		override public function generateVertexShader(assetsDict:Dictionary):String
		{
			var ret:String = "";
			
			if (useDepthOffset)
			{
				ret += agal("mov", "vt0", null, assetsDict[VA_COORDINATE], null);
				ret += agal("nrm", "vt1", "xyz", "vt0", "xyz");
				ret += agal("mul", "vt1", "xyz", "vt1", "xyz", assetsDict[C_LINE_DEPTH_OFFSET].toString(3), null);
				ret += agal("sub", "vt0", "xyz", "vt0", "xyz", "vt1", "xyz");
				ret += agal("m44", "op", null, "vt0", null, assetsDict[C_FINALMATRIX], null);
			}
			else
				ret += agal("m44", "op", null, assetsDict[VA_COORDINATE], null, assetsDict[C_FINALMATRIX], null);
			
			ret += agal("mov", assetsDict[V_COLOR], null, assetsDict[VA_COLOR], null);
			ret += agal("mov", assetsDict[V_TANGENT], null, assetsDict[VA_TANGENT], null); //
			ret += agal("mov", assetsDict[V_NORMAL], null, assetsDict[VA_NORMAL], null);
			
			return ret;
		}
		
		/**
		 * 线段起点为v0，线段上任意一点为v1<br>
		 * v0 v1 屏幕坐标分别为p0 p1，单位为像素<br>
		 * 虚实线单位长度为L个像素<br>
		 * t0 = frc(p1.sub(p0).length / L)<br>
		 * t0 > 0.5：实线<br>
		 * t0 <= 0.5：虚线<br>
		 * @param assetsDict
		 * @return 
		 * 
		 */		
		override public function generateFragmentShader(assetsDict:Dictionary):String
		{
			var ret:String = "";
			
			ret += agal("m44", "ft0", null, assetsDict[V_NORMAL], null, assetsDict[C_PROJECTION_MATRIX], null);
			ret += agal("div", "ft0", "xyzw", "ft0", "xyzw", "ft0", "wwww");
			ret += agal("mul", "ft0", "xy", "ft0", "xy", assetsDict[C_SCREEN_SIZE], "xy"); //v1
			ret += agal("sub", "ft0", "xy", "ft0", "xy", assetsDict[V_TANGENT], "xy"); //v0v1
			
			//计算v0v0的长度
			ret += agal("mov", "ft0", "z", assetsDict[C_ZERO].toString(1), null);
			ret += agal("dp3", "ft0", "w", "ft0", "xyz", "ft0", "xyz");
			ret += agal("sqt", "ft0", "w", "ft0", "w");
			
			//计算t0
			ret += agal("div", "ft0", "w", "ft0", "w", assetsDict[C_TWO].toString(1), null);
			ret += agal("frc", "ft0", "w", "ft0", "w");
			
			//比较t0和0.5
			ret += agal("mov", "ft0", "xyz", assetsDict[V_COLOR], "xyz");
			ret += agal("sge", "ft0", "w", "ft0", "w", assetsDict[C_HALF].toString(1), null);
			ret += agal("mov", "oc", null, "ft0", null);
			
			return ret;
		}
	}
}