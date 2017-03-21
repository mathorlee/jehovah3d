package utils
{
	import com.fuwo.math.MyMath;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class HexToDecimal
	{
		public static var INT32:int = 1; //2^0
		public static var FLOAT32:int = 2; //2^1
		
		public static function hexVRSceneToDecimalVRScene(source:String):String
		{
			source = source.split("Hex(").join("(");
			var arr:Array = source.split("\r\n");
			var line:String;
			
			//0: hexInt, 1: hexFloat
			var hasIntOrFloat:Vector.<int> = new Vector.<int>(arr.length);
			
			var i:int;
			for(i = 0; i < arr.length; i ++)
			{
				line = arr[i];
				if(line.indexOf("ListInt") != -1)
					hasIntOrFloat[i] |= INT32;
				else if(line.indexOf("ListVector") != -1)
					hasIntOrFloat[i] |= FLOAT32;
			}
			for(i = 1; i < arr.length; i ++)
			{
				if(hasIntOrFloat[i] > 0 && arr[i].charAt(arr[i].length - 1) != "(")
					arr[i] = parseHexString(arr[i], hasIntOrFloat[i]);
				else if(hasIntOrFloat[i - 1] > 0 && arr[i - 1].charAt(arr[i - 1].length - 1) == "(")
					arr[i] = parseHexString(arr[i], hasIntOrFloat[i - 1]);
			}
			
			var ret:String = "";
			for(i = 0; i < arr.length; i ++)
			{
				ret += arr[i];
				if(i < arr.length - 1)
					ret += "\n";
			}
			return ret;
		}
		
		private static function parseHexString(str:String, type:int):String
		{
			var i0:int = str.indexOf("\"");
			var i1:int = str.indexOf("\"", i0 + 1);
			var s0:String = str.substr(i0 + 1, i1 - i0 - 1);
			var arr:Object = hexStringToFloatArray(s0, type);
			if(type == INT32)
				s0 = arrayToString(arr);
			else
			{
				s0 = "";
				var i:int;
				for(i = 0; i < arr.length / 3; i ++)
				{
					s0 = s0 + "Vector(" + String(arr[i * 3]) + "," + String(arr[i * 3 + 1]) + "," + String(arr[i * 3 + 2]) + ")";
					if(i < arr.length / 3 - 1)
						s0 += ",";
				}
			}
			
			var ret:String = "";
			if(i0 > 0)
				ret += str.substr(0, i0);
			ret += s0;
			if(str.length - i1 - 1 > 0)
				ret += str.substr(i1 + 1, str.length - i1 - 1);
			return ret;
		}
		
		private static function hexStringToFloatArray(str:String, type:int):Object
		{
			var ret:Array = [];
			
			var bt:ByteArray = new ByteArray();
			bt.endian = Endian.LITTLE_ENDIAN;
			var i:int;
			for(i = 0; i < str.length / 2; i ++)
				bt.writeByte(parseInt(str.substr(i * 2, 2), 16));
			
			bt.position = 0;
			for(i = 0; i < bt.length / 4; i ++)
			{
				if(type == INT32)
					ret.push(bt.readInt());
				else if(type == FLOAT32)
					ret.push(bt.readFloat());
			}
			for(i = 0; i < ret.length; i ++)
				if(MyMath.isNumberEqual(ret[i], 0))
					ret[i] = 0;
			
			return ret;
		}
		
		/**
		 * 数组toString
		 * @param arr[1.0, 2.0]
		 * @return 1.0 2.0
		 * 
		 */		
		private static function arrayToString(arr:Object):String
		{
			var ret:String = "";
			var i:int;
			for(i = 0; i < arr.length; i ++)
			{
				if(i > 0)
					ret += ",";
				ret += String(arr[i]);
			}
			return ret;
		}
	}
}