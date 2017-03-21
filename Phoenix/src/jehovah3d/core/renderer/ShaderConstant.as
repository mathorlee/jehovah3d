package jehovah3d.core.renderer
{
	public class ShaderConstant
	{
		public static const VERTEX_CONSTANT:int = 0;
		public static const FRAGMENT_CONSTANT:int = 1;
		
		private var _type:int;
		private var _index:int;
		private var _mask:String;
		public function ShaderConstant(type:int, index:int, mask:String)
		{
			_type = type;
			_index = index;
			_mask = mask;
			if(_type == VERTEX_CONSTANT && _index >= 100)
				throw new Error("vertex constant 的数量不得超过100");
			else if(_type == FRAGMENT_CONSTANT && _index >= 28)
				throw new Error("fragment constant 的数量不得超过28");
			if(_mask && _mask.length > 1)
				throw new Error("要么是一个数值，要么是一个或register");
		}
		
		/**
		 * assetsDict[C_ONE].toString("xxx") / assetsDict[C_ONE].toString()
		 * @param mask
		 * @return 
		 * 
		 */		
		public function toString(count:int = 0):String
		{
			var ret:String = (_type == VERTEX_CONSTANT ? "vc" : "fc") + String(_index);
			if(count)
			{
				if(_mask)
				{
					ret += ".";
					var i:int;
					for(i = 0; i < count; i ++)
						ret += _mask;
				}
				else
				{
					throw new Error("存储的是一个寄存器，而非常数，对其取mask操作不合适！");
				}
			}
			return ret;
		}
		
		public function next(step:int):String
		{
			if(_type == VERTEX_CONSTANT && (_index + step) >= 100)
				throw new Error("vertex constant 的数量不得超过100");
			else if(_type == FRAGMENT_CONSTANT && (_index + step) >= 28)
				throw new Error("fragment constant 的数量不得超过28");
			return (_type == VERTEX_CONSTANT ? "vc" : "fc") + String(_index + step);
		}
	}
}