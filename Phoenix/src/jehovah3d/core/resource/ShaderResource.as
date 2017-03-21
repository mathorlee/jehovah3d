package jehovah3d.core.resource
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.utils.ByteArray;
	
	import jehovah3d.util.AGALMiniAssembler;

	public class ShaderResource extends Resource
	{
		private var _vertex:ByteArray;
		private var _vertexShaderString:String;
		private var _fragment:ByteArray;
		private var _fragmentShaderString:String;
		private var _program3D:Program3D;
		
		public function ShaderResource()
		{
			
		}
		
		/**
		 * upload shader to GPU. 
		 * @param context3D
		 * 
		 */		
		override public function upload(context3D:Context3D):void
		{
			if(isUploaded && cachedContext3D == context3D) //if shader is uploaded and cached context3d equals current context3d, no need to continue.
				return ;
			else //else, update cached context3d and upload. the can handle context3d loss.
				cachedContext3D = context3D;
			
//			trace("shader upload");
			if(_program3D)
			{
				_program3D.dispose();
				_program3D = null;
			}
			if(!_program3D)
				_program3D = context3D.createProgram();
			_program3D.upload(_vertex, _fragment);
		}
		
		/**
		 * dispose shader. 
		 * 
		 */		
		override public function dispose():void
		{
			super.dispose();
			if(_vertex)
			{
				_vertex.clear();
				_vertex = null;
			}
			if(_fragment)
			{
				_fragment.clear();
				_fragment = null;
			}
			if(_vertexShaderString)
				_vertexShaderString = null;
			if(_fragmentShaderString)
				_fragmentShaderString = null;
			if(_program3D)
			{
				_program3D.dispose();
				_program3D = null;
			}
		}
		
		override public function get isUploaded():Boolean
		{
			return _program3D != null;
		}
		
		public function set vertex(val:ByteArray):void
		{
			if(_vertex != val)
				_vertex = val;
		}
		public function set fragment(val:ByteArray):void
		{
			if(_fragment != val)
				_fragment = val;
		}
		
		public function get vertexShaderString():String
		{
			return _vertexShaderString;
		}
		public function set vertexShaderString(val:String):void
		{
			if(_vertexShaderString != val)
			{
				_vertexShaderString = val;
				var agal:AGALMiniAssembler = new AGALMiniAssembler();
				agal.assemble(Context3DProgramType.VERTEX, _vertexShaderString, false);
				_vertex = agal.agalcode;
			}
		}
		
		public function get fragmentShaderString():String
		{
			return _fragmentShaderString;
		}
		public function set fragmentShaderString(val:String):void
		{
			if(_fragmentShaderString != val)
			{
				_fragmentShaderString = val;
				var agal:AGALMiniAssembler = new AGALMiniAssembler();
				agal.assemble(Context3DProgramType.FRAGMENT, _fragmentShaderString, false);
				_fragment = agal.agalcode;
			}
		}
		
		/**
		 * program3D. 
		 * @return 
		 * 
		 */		
		public function get program3D():Program3D
		{
			return _program3D;
		}
		
		public function outputShader():void
		{
			trace("vertex");
			trace(_vertexShaderString);
			trace("fragment:");
			trace(_fragmentShaderString);
		}
	}
}