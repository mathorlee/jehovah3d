package jehovah3d.parser
{
	import flash.utils.Dictionary;

	public class ParserDAE
	{
		public function ParserDAE()
		{
			
		}
		
		/**
		 * dict[name] = {"name": String, "doppelganger": String, "frameCount": int, "startFrameIndex": int, "stopFrameIndex": int, "matrices": []}
		 * @param obj
		 * @return 
		 * 
		 */		
		public function parse(obj:Object):Object
		{
			var dict:Dictionary = new Dictionary();
			var i:int;
			var j:int;
			var tmpName:String;
			var str:String;
			var arr:Array;
			var reg:RegExp = new RegExp(" |\n"); //正则表达式，拆分成数字数组
			
			var geometryArr:Array = obj.COLLADA.library_geometries.geometry is Array ?  obj.COLLADA.library_geometries.geometry : [obj.COLLADA.library_geometries.geometry];
			for(i = 0; i < geometryArr.length; i ++)
				dict[geometryArr[i].name.substr(0, geometryArr[i].name.length - 4)] = {"name": geometryArr[i].name.substr(0, geometryArr[i].name.length - 4)}; //如果name为空？
			
			var frameRate:int = obj.COLLADA.library_visual_scenes.visual_scene.extra.technique[0].frame_rate; //帧速
			var upAxis:String = obj.COLLADA.asset.up_axis; //"Y_UP" or "Z_UP"
			
			var animationArr:Array = obj.COLLADA.library_animations.animation is Array ? obj.COLLADA.library_animations.animation : [obj.COLLADA.library_animations.animation];
			for(i = 0; i < animationArr.length; i ++)
			{
				tmpName = animationArr[i].name;
				dict[tmpName].frameCount = animationArr[i].animation.source[0].float_array.count;
				if(dict[tmpName].frameCount == 0)
					continue;
				str = animationArr[i].animation.source[0].float_array.value;
				for(j = 0; j < str.length; j ++)
					if(str.charAt(j) != "\n")
					{
						str = str.substr(j, str.length - j);
						break;
					}
				
				arr = str.split(reg);
				dict[tmpName].startFrameIndex = int(Number(arr[0]) * frameRate + 0.1);
				dict[tmpName].stopFrameIndex = int(Number(arr[dict[tmpName].frameCount - 1]) * frameRate + 0.1);
				
				//动画
				dict[tmpName].matrices = [];
				str = animationArr[i].animation.source[1].float_array.value;
				for(j = 0; j < str.length; j ++)
					if(str.charAt(j) != "\n")
					{
						str = str.substr(j, str.length - j);
						break;
					}
				arr = str.split(reg);
				for(j = 0; j < dict[tmpName].frameCount; j ++)
				{
					if(upAxis == "Z_UP")
					{
						dict[tmpName].matrices.push({"rawData": [
							Number(arr[16 * j + 0]), Number(arr[16 * j + 4]), Number(arr[16 * j + 8]), Number(arr[16 * j + 12]), 
							Number(arr[16 * j + 1]), Number(arr[16 * j + 5]), Number(arr[16 * j + 9]), Number(arr[16 * j + 13]), 
							Number(arr[16 * j + 2]), Number(arr[16 * j + 6]), Number(arr[16 * j + 10]), Number(arr[16 * j + 14]), 
							Number(arr[16 * j + 3]), Number(arr[16 * j + 7]), Number(arr[16 * j + 11]), Number(arr[16 * j + 15])
						]});
					}
					else if(upAxis == "Y_UP")
					{
						dict[tmpName].matrices.push({"rawData": [
							Number(arr[16 * j + 0]), -Number(arr[16 * j + 8]), Number(arr[16 * j + 4]), Number(arr[16 * j + 12]), 
							Number(arr[16 * j + 1]), -Number(arr[16 * j + 9]), Number(arr[16 * j + 5]), Number(arr[16 * j + 13]), 
							Number(arr[16 * j + 2]), -Number(arr[16 * j + 10]), Number(arr[16 * j + 6]), Number(arr[16 * j + 14]), 
							Number(arr[16 * j + 3]), -Number(arr[16 * j + 11]), Number(arr[16 * j + 7]), Number(arr[16 * j + 15])
						]});
					}
				}
			}
			return dict;
		}
	}
}