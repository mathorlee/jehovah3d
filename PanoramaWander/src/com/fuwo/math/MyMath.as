package com.fuwo.math
{
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	public class MyMath
	{
		public function MyMath()
		{
			
		}
		
		public static function isNumberEqual(d1:Number, d2:Number):Boolean
		{
			return Math.abs(d1 - d2) < 0.00001;
		}
		public static function isNumberEqualLessAccuracy(d1:Number, d2:Number):Boolean
		{
			return Math.abs(d1 - d2) < 0.1;
		}
		public static function isNumberEqual2(d1:Number, d2:Number, tolerance:Number = NaN):Boolean
		{
			if(tolerance)
				return Math.abs(d1 - d2) < tolerance;
			return Math.abs(d1 - d2) < 0.00001;
		}
		public static function isTwoVector3DEqual(v1:Vector3D, v2:Vector3D):Boolean
		{
			return isNumberEqual(v1.x, v2.x) && isNumberEqual(v1.y, v2.y) && isNumberEqual(v1.z, v2.z);
		}
		public static function dotProduct(p1:Point, p2:Point):Number //点积 
		{
			return p1.x * p2.x + p1.y * p2.y;
		}
		public static function isOrthogonal(p1:Point, p2:Point):Boolean //判断两个向量是否垂直 
		{
			//if(p1 * p2 == 0) return true;
			return isNumberEqual(dotProduct(p1, p2), 0);
		}
		public static function isParallel(p1:Point, p2:Point):Boolean //判断两个向量是否平行 
		{
			//if(p1 * p2 == length(p1) * length(p2) || p1 * p2 == -length(p1) * length(p2)) return true;
			return isNumberEqual(dotProduct(p1, p2), p1.length * p2.length);
		}
		public static function crossProduct(p1:Point, p2:Point):Number //叉积，返回值为向量。
		{
			return p1.x * p2.y - p2.x * p1.y;
		}
		
		public static function rotateByZ(p1:Point, angle:Number):Point
		{
			/*
			cos(a) = x;
			sin(a) = y;
			
			cos(a+t) = cos(a)*cos(t) - sin(a) * sin(t)
			= x * cos(t) - y * sin(t);
			sin(a+t) = sin(a)*cos(t) + cos(a) * sin(t)
			= y * cos(t) + x * sin(t);
			*/
			var p1Copy:Point = new Point(p1.x, p1.y);
			p1Copy.normalize(1);
			var sin:Number = Math.sin(angle);
			var cos:Number = Math.cos(angle);
			var ret:Point = new Point();
			ret.x = p1Copy.x * cos - p1Copy.y * sin;
			ret.y = p1Copy.y * cos + p1Copy.x * sin;
			return ret;
		}
		
		public static function rotateByZNoScale(p1:Point, angle:Number):Point
		{
			var p1Copy:Point = new Point(p1.x, p1.y);
			var sin:Number = Math.sin(angle);
			var cos:Number = Math.cos(angle);
			var ret:Point = new Point();
			ret.x = p1Copy.x * cos - p1Copy.y * sin;
			ret.y = p1Copy.y * cos + p1Copy.x * sin;
			return ret;
		}
		
		public static function intersect(p0:Point, p1:Point, p2:Point, p3:Point):Boolean
		{
			//(p0p1 X p0p2) * (p0p1 X p0p3) < 0
			//(p2p3 X p2p0) * (p2p3 X p2p1) < 0
			var p0p1:Point = new Point(p1.x - p0.x, p1.y - p0.y);
			var p0p2:Point = new Point(p2.x - p0.x, p2.y - p0.y);
			var p0p3:Point = new Point(p3.x - p0.x, p3.y -p0.y);
			var n1:Number = crossProduct(p0p1, p0p2) * crossProduct(p0p1, p0p3);
			
			var p2p3:Point = new Point(p3.x - p2.x, p3.y - p2.y);
			var p2p0:Point = new Point(p0.x - p2.x, p0.y - p2.y);
			var p2p1:Point = new Point(p1.x - p2.x, p1.y - p2.y);
			var n2:Number = crossProduct(p2p3, p2p0) * crossProduct(p2p3, p2p1);
			if(n1 < 0 && !isNumberEqual(n1, 0) && n2 < 0 && !isNumberEqual(n2, 0)) return true;
			return false;
		}
		
		public static function isTwoWallIntersects(p0:Point, p1:Point, p2:Point, p3:Point):Boolean
		{
			var p0p1:Point = new Point(p1.x - p0.x, p1.y - p0.y);
			var p0p2:Point = new Point(p2.x - p0.x, p2.y - p0.y);
			var p0p3:Point = new Point(p3.x - p0.x, p3.y -p0.y);
			if(isNumberEqual(crossProduct(p0p1, p0p2), 0) && isNumberEqual(crossProduct(p0p1, p0p3), 0) && 
				(isPointOnSegment(p0, p1, p2) || isPointOnSegment(p0, p1, p3)))
				return true;
			var n1:Number = crossProduct(p0p1, p0p2) * crossProduct(p0p1, p0p3);
			
			var p2p3:Point = new Point(p3.x - p2.x, p3.y - p2.y);
			var p2p0:Point = new Point(p0.x - p2.x, p0.y - p2.y);
			var p2p1:Point = new Point(p1.x - p2.x, p1.y - p2.y);
			var n2:Number = crossProduct(p2p3, p2p0) * crossProduct(p2p3, p2p1);
			return false;
		}
		public static function isTwoSegmentIntersect(p0:Point, p1:Point, p2:Point, p3:Point):Boolean
		{
			var p0p1:Point = p1.subtract(p0);
			var n1:Number = crossProduct(p0p1, p2.subtract(p0)) * crossProduct(p0p1, p3.subtract(p0));
			var p2p3:Point = p3.subtract(p2);
			var n2:Number = crossProduct(p2p3, p0.subtract(p2)) * crossProduct(p2p3, p1.subtract(p2));
			
			if(n1 < 0 && n2 < 0 && !isNumberEqual(n1, 0) && !isNumberEqual(n2, 0))
				return true;
			return false;
		}
		public static function raySegmentIntersection(ray_p0:Point, ray_dir:Point, seg_p0:Point, seg_p1:Point):Object
		{
			var bc:Point = seg_p1.subtract(seg_p0);
			var ab:Point = seg_p0.subtract(ray_p0);
			var ac:Point = seg_p1.subtract(ray_p0);
			if(crossProduct(ray_dir, ab) * crossProduct(ray_dir, ac) > 0)
				return null;
			if(dotProduct(ray_dir, ab) < 0 || dotProduct(ray_dir, ab) < 0)
				return null;
			
			var h:Number = Math.abs(crossProduct(ab, ac) / bc.length * 0.5);
			var h_dir:Point = bc.clone();
			h_dir.normalize(1);
			h_dir = new Point(h_dir.y, -h_dir.x);
			var d:Number = h / Math.abs(dotProduct(ray_dir, h_dir));
			var pt:Point = ray_dir.clone();
			pt.normalize(d);
			pt = ray_p0.add(pt);
			
			var ret:Object = new Object();
			ret.point = pt;
			ret.dist = d;
			return ret;
		}
		public static function nextIndex(currentIndex:int, listLength:int):int
		{
			return (currentIndex + 1) % listLength;
		}
		public static function preIndex(currentIndex:int, listLength:int):int
		{
			return (currentIndex - 1 + listLength) % listLength;
		}
		
		/**
		 * 逆时针方向3个点组成的拐点，是否是凸多边形拐点。 
		 * @param p0
		 * @param p1
		 * @param p2
		 * 
		 */		
		public static function isConvex(p1:Point, p2:Point, p3:Point):Boolean
		{
			var v12:Vector3D = new Vector3D(p2.x - p1.x, p2.y - p1.y, 0);
			var v13:Vector3D = new Vector3D(p3.x - p1.x, p3.y - p1.y, 0);
			var cross:Vector3D = v12.crossProduct(v13); //cross = v12 * v13.
//			if(cross.z > 0) return true;
//			if(cross.z < 0) return false;
//			if(isNumberEqual(cross.z, 0))
//				throw new Error("相邻的3个点不许共线。请合并点后重新计算。");
//			return null;
//			if(isNumberEqual(cross.z, 0))
//				throw new Error("相邻的3个点不许共线。请合并点后重新计算。");
			return cross.z > 0;
		}
		
		/**
		 * 墙向量p1，沿p2向量方向拖动墙体，求墙沿着垂直方向移动的向量。 
		 * @param p1
		 * @param p2
		 * 
		 */		
		public static function dragWall(p1:Point, p2:Point):Point
		{
			var dir:Point; //垂直移动墙体方向。
			var cross:Number = crossProduct(p1, p2);
			if(isNumberEqual(cross, 0)) //p1,p2平行
				return new Point(0, 0);
			else if(cross > 0) //p2在p1左侧
				dir = rotateByZ(p1, Math.PI / 2);
			else if(cross < 0) //p2在p1右侧
				dir = rotateByZ(p1, -Math.PI / 2);
			
			dir.normalize(1);
			var cos:Number = Math.abs(dotProduct(p2, dir) / p2.length /dir.length); //dir.length =1;
			var length:Number = p2.length * cos;
			return new Point(dir.x * length, dir.y * length);
		}
		
		/**
		 * 水平移动门。
		 * @param p1 墙向量。
		 * @param p2 拖动向量。
		 * 
		 */		
		public static function dragDoor(p1:Point, p2:Point):Point
		{
			var dot:Number = dotProduct(p2, p1);
			var cross:Number = crossProduct(p2, p1);
			var cos:Number = Math.abs(dot / p1.length / p2.length);
			var length:Number = Math.abs(dot / p1.length);
			p2.normalize(1);
			var ret:Point;
			
			if(isNumberEqual(dot, 0))
				return new Point(0, 0);
			else if(dot > 0)
			{
				if(cross > 0)
					ret = rotateByZ(p2, Math.acos(cos));
				else if(cross < 0)
					ret = rotateByZ(p2, -Math.acos(cos));
			}
			else if(dot < 0)
			{
				if(cross > 0)
					ret = rotateByZ(p2, -Math.acos(cos));
				else if(cross < 0)
					ret = rotateByZ(p2, Math.acos(cos));
			}
			return new Point(ret.x * length, ret.y * length);
		}
		
		/**
		 * 点P是否在三角形ABC内部。若P在边上，返回true。
		 * @param p
		 * @param a
		 * @param b
		 * @param c
		 * @return 
		 * 
		 */		
		public static function isPointInTriangle(p:Point, a:Point, b:Point, c:Point):Boolean
		{
			var ap:Point = p.subtract(a);
			var ab:Point = b.subtract(a);
			var ac:Point = c.subtract(a);
			var n1:Number = crossProduct(ap, ab) * crossProduct(ap, ac);
			if(n1 > 0 && !isNumberEqual(n1, 0)) return false;
			
			var bp:Point = p.subtract(b);
			var ba:Point = a.subtract(b);
			var bc:Point = c.subtract(b);
			var n2:Number = crossProduct(bp, ba) * crossProduct(bp, bc);
			if(n2 > 0 && !isNumberEqual(n2, 0)) return false;
			
			var cp:Point = p.subtract(c);
			var ca:Point = a.subtract(c);
			var cb:Point = b.subtract(c);
			var n3:Number = crossProduct(cp, ca) * crossProduct(cp, cb);
			if(n3 > 0 && !isNumberEqual(n3, 0)) return false;
			
			return true;
		}
		
		public static function deleteTranslationOfMatrix3D(mat:Matrix3D):Matrix3D
		{
			var v:Vector.<Vector3D> = mat.decompose();
			var t:Vector3D = v[0]; //translation
			var r:Vector3D = v[1]; //rotation
			var s:Vector3D = v[2]; //scaling
			var ret:Matrix3D = new Matrix3D();
			ret.prependScale(s.x, s.y, s.z);
			ret.prependRotation(r.x / Math.PI * 180, new Vector3D(1, 0, 0));
			ret.prependRotation(r.y / Math.PI * 180, new Vector3D(0, 1, 0));
			ret.prependRotation(r.z / Math.PI * 180, new Vector3D(0, 0, 1));
			return ret;
		}
		
		public static function isTwoPointEqual(p1:Point, p2:Point):Boolean
		{
			return isNumberEqual(p1.x, p2.x) && isNumberEqual(p1.y, p2.y);
		}
		
		/**
		 * segment(p1, p2), test if p3 is on seg. 
		 * @param p1
		 * @param p2
		 * @param p3
		 * 
		 */		
		public static function isPointOnSegment(p1:Point, p2:Point, p3:Point):Boolean
		{
			var p3p1:Point = p1.subtract(p3);
			var p3p2:Point = p2.subtract(p3);
			var cross:Number = crossProduct(p3p1, p3p2);
			var dot:Number = dotProduct(p3p1, p3p2);
			if(isNumberEqual(cross, 0) && (dot < 0 || isNumberEqual(dot, 0)))
				return true;
			return false;
		}
		
		public static function isPoint3DOnSegment(p1:Vector3D, p2:Vector3D, p3:Vector3D):Boolean
		{
//			var p3p1:Point = p1.subtract(p3);
//			var p3p2:Point = p2.subtract(p3);
			var p3p1:Point = new Point(p1.x - p3.x, p1.y - p3.y);
			var p3p2:Point = new Point(p2.x - p3.x, p2.y - p3.y);
			var cross:Number = crossProduct(p3p1, p3p2);
			var dot:Number = dotProduct(p3p1, p3p2);
			if(isNumberEqual(cross, 0) && (dot < 0 || isNumberEqual(dot, 0)))
				return true;
			return false;
		}
		
		public static function compareDepthOfIntersection(v1:Vector3D, v2:Vector3D, v3:Vector3D, v4:Vector3D, v5:Vector3D, v6:Vector3D, v7:Vector3D, v8:Vector3D, globalToCamera:Matrix3D):int
		{
			/*
			p1, p2, p3, p4
			pa = p1 + ua * (p2 - p1) //points on p1p2
			pb = p3 + ub * (p4 - p3) //points on p3p4
			pa = pb
			*/
			var denominator:Number = (v8.y - v7.y) * (v6.x - v5.x) - (v8.x - v7.x) * (v6.y - v5.y);
			if(isNumberEqual(0, denominator)) return -1; //they do not intersects with each other.
			var ua:Number = ((v8.x - v7.x) * (v5.y - v7.y) - (v8.y - v7.y) * (v5.x - v7.x)) / denominator;
			var ub:Number = ((v6.x - v5.x) * (v5.y - v7.y) - (v6.y - v5.y) * (v5.x - v7.x)) / denominator;
			
			var intersect1:Vector3D;
			var intersect2:Vector3D;
			if(ua > 0 && ua < 1 && ub > 0 && ub < 1)
			{
				var v1v2:Vector3D = v2.subtract(v1);
				var v3v4:Vector3D = v4.subtract(v3);
				intersect1 = v1.add(new Vector3D(v1v2.x * ua, v1v2.y * ua, v1v2.z * ua));
				intersect2 = v3.add(new Vector3D(v3v4.x * ub, v3v4.y * ub, v3v4.z * ub));
				var camIntersect1:Vector3D = globalToCamera.transformVector(intersect1);
				var camIntersect2:Vector3D = globalToCamera.transformVector(intersect2);
				if(camIntersect1.z > camIntersect2.z) return 1; //v1v2 overlap v3v4.(v1v2 > v3v4)
				else if(camIntersect1.z < camIntersect2.z) return 0; //v3v4 overlap v1v2.(v1v2 < v3v4)
			}
			return -1; //they do not intersects with each other.
		}
		
		/**
		 * transform vector. Matrix3D.transformVector() transform a point, not a vector. So weak.
		 * @param matrix
		 * @param vec
		 * @return 
		 * 
		 */		
		public static function matrixTransformVector(matrix:Matrix3D, vec:Vector3D):Vector3D
		{
			var ret:Vector3D = new Vector3D();
			ret.x = matrix.rawData[0] * vec.x + matrix.rawData[4] * vec.y + matrix.rawData[8] * vec.z;
			ret.y = matrix.rawData[1] * vec.x + matrix.rawData[5] * vec.y + matrix.rawData[9] * vec.z;
			ret.z = matrix.rawData[2] * vec.x + matrix.rawData[6] * vec.y + matrix.rawData[10] * vec.z;
			return ret;
		}
		
		public static function isPoint3DInPolygon(point:Vector3D, polygonPoints:Vector.<Vector3D>):Boolean
		{
			var status:Boolean = false;
			var i:uint;
			var j:uint;
			
			for (i=0; i<polygonPoints.length; i++)
			{
				if (isPoint3DOnSegment(polygonPoints[i], polygonPoints[(i+1)%polygonPoints.length], point)) return true;
			}
			
			for (i=0,j=polygonPoints.length-1; i<polygonPoints.length; j=i++) {
				if ((((polygonPoints[i].y<=point.y) && (point.y<polygonPoints[j].y)) || ((polygonPoints[j].y<=point.y) && (point.y<polygonPoints[i].y))) && (point.x < (polygonPoints[j].x - polygonPoints[i].x) * (point.y - polygonPoints[i].y) / (polygonPoints[j].y - polygonPoints[i].y) + polygonPoints[i].x))
					status = !status;
			}
			return status;
		}
		
		public static function rotateByArbitraryAxis(axis:Vector3D, angle:Number):Matrix3D
		{
			var C:Number = Math.cos(angle);
			var S:Number = Math.sin(angle);
			var t:Number = 1 - C;
			//axis = (Ux, Uy, Uz)
			var ux:Number = axis.x;
			var uy:Number = axis.y;
			var uz:Number = axis.z;
			
			return new Matrix3D(Vector.<Number>([
				t * ux * ux + C, t * ux * uy + S * uz, t * ux * uz - S * uy, 0, 
				t * ux * uy - S * uz, t * uy * uy + C, t * uy * uz + S * ux, 0, 
				t * ux * uz + S * uy, t * uy * uz - S * ux, t * uz * uz + C, 0, 
				0, 0, 0, 1
			]));
		}
		
		/**
		 * clone object. 
		 * @param source
		 * @return 
		 * 
		 */		
		public static function cloneObject(source:Object):*
		{
			var byteArray:ByteArray = new ByteArray();
			byteArray.writeObject(source);
			byteArray.position = 0;
			return(byteArray.readObject());
		}
		
		public static function toPrecision(n:Number, precision:int):String
		{
			var s:String = n.toString(10);
			var t:int = s.indexOf(".");
			var i:int;
			if(t == -1)
			{
				s += ".";
				for(i = 0; i < precision; i ++)
					s += "0";
			}
			else if(t + precision + 1 < s.length)
				s = s.substr(0, t + 3);
			else if(t + precision + 1 > s.length)
			{
				for(i = 0; i < t + precision + 1 - s.length; i ++)
					s += "0";
			}
			return s;
		}
		
		public static function generateRandomIntegerInRange(lowRange:int, highRange:int):int
		{
			if(highRange > 1000)
				throw new Error("range error!");
			return lowRange + int(Math.random() * 1000) % (highRange - lowRange + 1);
		}
		
		public static function generateRandomNumberInRange(lowRange:Number, highRange:Number):Number
		{
			return (highRange - lowRange) * Math.random() + lowRange;
		}
		
		public static function getParameterFromURL(url:String):Dictionary
		{
			var dict:Dictionary = new Dictionary();
			if(url.indexOf("?") != -1)
			{
				var arr:Array = url.split("?")[1].split("&");
				var i:int;
				var arr2:Array;
				for(i = 0; i < arr.length; i ++)
				{
					arr2 = arr[i].split("=");
					if(arr2.length == 2)
						dict[arr2[0]] = arr2[1];
				}
			}
			return dict;
		}
		
		/**
		 * 从url中解析得到文件拓展名。 
		 * @param url
		 * @return 
		 * 
		 */		
		public static function analysisFileExtentionFromURL(url:String):String
		{
			var realURL:String;
			var realFileName:String;
			var fileExtention:String;
			var arr:Array;
			var paramURL:String;
			
			realURL = url;
			if(realURL.indexOf("?") != -1) //剔除url中的参数。
			{
				arr = realURL.split("?");
				realURL = arr[0];
				paramURL = arr[1];
			}
			if(realURL.indexOf("#") != -1)
				realURL = realURL.split("#")[0];
			
			if(realURL.indexOf("/") != -1) //得到真实的文件名。
			{
				arr = realURL.split("/");
				realFileName = arr[arr.length - 1];
			}
			else
				realFileName = realURL;
			
			if(realFileName.indexOf(".") == -1) //若文件不存在后缀名，返回空。
				return null;
			arr = realFileName.split(".");
			fileExtention = arr[arr.length - 1];
			if(fileExtention == "")
				fileExtention = null;
			if(paramURL)
			{
				var obj:Object = analysisParameters(paramURL);
				if(obj.name && obj.name != "")
					return obj.name;
			}
			return fileExtention;
		}
		
		/**
		 * 输入"name=1.jpg&id=3", 返回{"name": "1.jpg", "id": "3"}
		 * @param paramURL
		 * @return 
		 * 
		 */		
		public static function analysisParameters(paramURL:String):Object
		{
			var ret:Object = {};
			var arr:Array = paramURL.split("&");
			var arr2:Array;
			var i:int;
			for(i = 0; i < arr.length; i ++)
			{
				arr2 = arr[i].split("=");
				ret[arr2[0]] = arr2[1];
			}
			return ret;
		}
		
		/**
		 * 输入1.jpg, 返回jpg
		 * @param fileName
		 * @return 
		 * 
		 */		
		public static function getExtensionFromFileName(fileName:String):String
		{
			var arr:Array = fileName.split(".");
			var ret:String = arr[arr.length - 1];
			if(ret == "")
				ret = null;
			return ret;
		}
		
		public static function analysisFileExtentionFromURL2(url:String):String
		{
			var str0:String = url;
			var str1:String;
			var arr:Array;
			
			if(str0.indexOf("?") != -1)
			{
				arr = str0.split("?");
				str0 = arr[0];
				str1 = arr[1];
			}
			if(str0.indexOf("#") != -1)
				str0 = str0.split("#")[0];
			if(str0.indexOf("/") != -1) //得到真实的文件名。
			{
				arr = str0.split("/");
				str0 = arr[arr.length - 1];
			}
			str0 = getExtensionFromFileName(str0);
			
			if(str1)
			{
				str1 = analysisParameters(str1).name;
				if(str1)
					str1 = getExtensionFromFileName(str1);
			}
			if(str1)
				return str1;
			return str0;
		}
			
		
		public static function getRandomColor():uint
		{
			return int(16777215 * Math.random());
		}
		
		public static function degreeToRadius(degree:Number):Number
		{
			return degree / 180 * Math.PI;
		}
		public static function radiusToDegree(radius:Number):Number
		{
			return radius / Math.PI * 180;
		}
		
		/**
		 * 矩阵转换一组点/向量，返回转换后的值。 
		 * @param vector3DList
		 * @param matrix
		 * @param transformVector 若为true，deltaTransformVector；若为false，transformVector。默认为false。
		 * @return 
		 * 
		 */		
		public static function transformVector3DList(vector3DList:Vector.<Vector3D>, matrix:Matrix3D, transformVector:Boolean = false):Vector.<Vector3D>
		{
			var ret:Vector.<Vector3D> = new Vector.<Vector3D>();
			var i:int;
			for(i = 0; i < vector3DList.length; i ++)
			{
				if(transformVector)
					ret.push(matrix.deltaTransformVector(vector3DList[i]));
				else
					ret.push(matrix.transformVector(vector3DList[i]));
			}
			return ret;
		}
		
		public static function convertIntToString(n:int, strWidth:int):String
		{
			var ret:String = String(n);
			if(ret.length < strWidth)
			{
				var tmp:String = "";
				var i:int;
				for(i = 0; i < strWidth - ret.length; i ++)
					tmp += "0";
				ret = tmp + ret;
			}
			return ret;
		}
		
		public static function outputIntArray(arr:Object):void
		{
			var str:String = "";
			var i:int;
			for(i = 0; i < arr.length; i ++)
				str += arr[i] + " ";
			trace(str);
		}
		public static function outputMatrix3D(matrix:Matrix3D):void
		{
			var str:String = "Matrix3D:\n";
			str += matrix.rawData[0] + ", " + matrix.rawData[4] + ", " + ", " + matrix.rawData[8] + ", " + ", " + matrix.rawData[12] + "\n";
			str += matrix.rawData[1] + ", " + matrix.rawData[5] + ", " + ", " + matrix.rawData[9] + ", " + ", " + matrix.rawData[13] + "\n";
			str +=  matrix.rawData[2] + ", " + matrix.rawData[6] + ", " + ", " + matrix.rawData[10] + ", " + ", " + matrix.rawData[14] + "\n";
			str += matrix.rawData[3] + ", " + matrix.rawData[7] + ", " + ", " + matrix.rawData[11] + ", " + ", " + matrix.rawData[15] + "\n";
			trace(str);
		}
		
		public static function arrayToString(arr:Object):String
		{
			var str:String = "";
			var i:int;
			for(i = 0; i < arr.length; i ++)
				str += arr[i] + " ";
			return str;
		}
		
		/**
		 * 线性差值。linear interpolation. 
		 * @param from mim value
		 * @param to max value
		 * @param t 0到1之间。t为0时返回from，t为1时返回to
		 * 
		 */		
		public static function lerp(from:Number, to:Number, t:Number):Number
		{
			return from + (to - from) * t;
		}
		
		public static function multiplyTwoMatrix3D(m0:Matrix3D, m1:Matrix3D):Matrix3D
		{
//			var matrix:Matrix3D = new Matrix3D(Vector.<Number>([
//				m0.rawData[0] * m1.rawData[0] + m0.rawData[4] * m1.rawData[1] + m0.rawData[8] * m1.rawData[2] + m0.rawData[12] * m1.rawData[3], 
//				m0.rawData[0] * m1.rawData[4] + m0.rawData[4] * m1.rawData[5] + m0.rawData[8] * m1.rawData[6] + m0.rawData[12] * m1.rawData[7], 
//				m0.rawData[0] * m1.rawData[8] + m0.rawData[4] * m1.rawData[9] + m0.rawData[8] * m1.rawData[2] + m0.rawData[12] * m1.rawData[3], 
//				m0.rawData[0] * m1.rawData[0] + m0.rawData[4] * m1.rawData[1] + m0.rawData[8] * m1.rawData[2] + m0.rawData[12] * m1.rawData[3], 
//				
//			]));
			var matrix:Matrix3D = new Matrix3D();
			matrix.copyFrom(m0);
			matrix.append(m1);
			return matrix;
		}
		
		public static function mergeTwoNumberVector(v0:Vector.<Number>, v1:Vector.<Number>, mergeToFirstVector:Boolean):Vector.<Number>
		{
			var i:int;
			if(mergeToFirstVector)
			{
				for(i = 0; i < v1.length; i ++)
					v0.push(v1[i]);
			}
			else
			{
				var ret:Vector.<Number> = v0.slice();
				for(i = 0; i < v1.length; i ++)
					ret.push(v1[i]);
				return ret;
			}
			return null;
		}
		
		public static function matrix3DToProgram3DConstants(matrix:Matrix3D):Vector.<Number>
		{
			return Vector.<Number>([
				matrix.rawData[0], matrix.rawData[4], matrix.rawData[8], matrix.rawData[12], 
				matrix.rawData[1], matrix.rawData[5], matrix.rawData[9], matrix.rawData[13], 
				matrix.rawData[2], matrix.rawData[6], matrix.rawData[10], matrix.rawData[14], 
				matrix.rawData[3], matrix.rawData[7], matrix.rawData[11], matrix.rawData[15]
			]);
		}
		
		public static function isTwoMatrix3DEqual(m0:Matrix3D, m1:Matrix3D):Boolean
		{
			var i:int;
			for(i = 0; i < 16; i ++)
				if(!MyMath.isNumberEqual(m0.rawData[i], m1.rawData[i]))
					return false;
			return true;
		}
		
		public static function numberArrayToNumberVector(arr:Array):Vector.<Number>
		{
			var ret:Vector.<Number> = new Vector.<Number>();
			var i:int;
			for(i = 0; i < arr.length; i ++)
				ret.push(arr[i]);
			return ret;
		}
		public static function numberVectorToArray(vec:Vector.<Number>):Array
		{
			var ret:Array = new Array();
			var i:int;
			for(i = 0; i < vec.length; i ++)
				ret.push(vec[i]);
			return ret;
		}
	}
}