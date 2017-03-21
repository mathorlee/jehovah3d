package jehovah3d.core.renderer
{
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Matrix3D;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.ShaderResource;
	import jehovah3d.core.shader.ShaderConstant;
	
	public class WireFrameRenderer extends Renderer
	{
		public static const NAME:String = "WireFrameRenderer";
		
		public function WireFrameRenderer(mesh:Mesh)
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
			assetsDict[C_PROJECTION_MATRIX] = currentVC();
//			var pm:Matrix3D = Jehovah.currentLight ? Jehovah.currentLight.projectionMatrix : Jehovah.camera.pm;
			var pm:Matrix3D = Jehovah.camera.pm;
			vertexConstants.push(pm.rawData[0], pm.rawData[4], pm.rawData[8], pm.rawData[12]);
			vertexConstants.push(pm.rawData[1], pm.rawData[5], pm.rawData[9], pm.rawData[13]);
			vertexConstants.push(pm.rawData[2], pm.rawData[6], pm.rawData[10], pm.rawData[14]);
			vertexConstants.push(pm.rawData[3], pm.rawData[7], pm.rawData[11], pm.rawData[15]);
			
			//WireFrame的偏移
			index = currentVCIndex();
			assetsDict[C_WIREFRAME_DEPTH_OFFSET] = new ShaderConstant(ShaderConstant.VERTEX_CONSTANT, index, "x");
			vertexConstants.push(0.00001, 0, 0, 0);
			
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
			if(mesh.mtl.diffuseColor)
			{
				assetsDict[DIFFUSE_COLOR] = currentFC(); //diffuseColor
				fragmentConstants.push(mesh.mtl.diffuseColor.fractionalRed, mesh.mtl.diffuseColor.fractionalGreen, mesh.mtl.diffuseColor.fractionalBlue, mesh.mtl.diffuseColor.fractionalAlpha); //diffuse color
			}
			
			if(!_shader)
			{
				_shader = new ShaderResource();
				_shader.vertexShaderString = generateVertexShader(assetsDict);
				_shader.fragmentShaderString = generateFragmentShader(assetsDict);
				_shader.upload(Jehovah.context3D);
//				if (assetsDict[VA_COLOR])
//					_shader.outputShader();
			}
		}
		
		override public function generateVertexShader(assetsDict:Dictionary):String
		{
//			var ret:String = "";
//			ret += agal("m44", "vt0", null, assetsDict[VA_COORDINATE], null, assetsDict[C_PROJECTION_MATRIX], null);
//			ret += agal("div", "vt0", "xyzw", "vt0", "xyzw", "vt0", "wwww");
//			ret += agal("sub", "vt0", "z", "vt0", "z", assetsDict[C_WIREFRAME_DEPTH_OFFSET].toString(1), null);
//			ret += agal("mov", "op", null, "vt0", null);
//			return ret;
			
			var ret:String = "";
			ret += agal("m44", "vt0", null, assetsDict[VA_COORDINATE], null, assetsDict[C_PROJECTION_MATRIX], null);
			if (assetsDict[VA_COLOR])
				ret += agal("mov", assetsDict[V_COLOR], null, assetsDict[VA_COLOR], null);
			ret += agal("div", "vt0", "xyzw", "vt0", "xyzw", "vt0", "wwww");
			ret += agal("mov", "vt1", "x", assetsDict[C_WIREFRAME_DEPTH_OFFSET].toString(1), null);
			ret += agal("div", "vt1", "x", "vt1", "x", "vt0", "z");
			ret += agal("min", "vt1", "x", "vt1", "x", assetsDict[C_WIREFRAME_DEPTH_OFFSET].toString(1), null);
			ret += agal("sub", "vt0", "z", "vt0", "z", "vt1", "x");
			ret += agal("mov", "op", null, "vt0", null);
			return ret;
			
//			return agal("m44", "op", null, assetsDict[VA_COORDINATE], null, assetsDict[C_PROJECTION_MATRIX], null);
		}
		
		override public function generateFragmentShader(assetsDict:Dictionary):String
		{
			if (assetsDict[VA_COLOR])
				return agal("mov", "oc", null, assetsDict[V_COLOR], null);
			else
				return agal("mov", "oc", null, assetsDict[DIFFUSE_COLOR], null);
		}
	}
}