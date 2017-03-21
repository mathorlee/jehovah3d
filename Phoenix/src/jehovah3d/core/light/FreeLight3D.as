package jehovah3d.core.light
{
	import com.fuwo.math.MyMath;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.mesh.wireframe.WireFrame;

	public class FreeLight3D extends Light3D
	{
		public static const TYPE_SPOT_LIGHT:String = "TypeSportLight";
		public static const TYPE_DIRECTIONAL_LIGHT:String = "TypeDirectionalLight";
		public static const CONE_RECTANGLE:String = "ConeRectangle"; //矩形椎体
		public static const CONE_CIRCLE:String = "ConeCircle"; //圆形椎体
		private var _lightType:String;
		private var _lightCone:String;
		
		private var _hFov:Number;
		private var _vFov:Number;
		private var _fov:Number;
		
		private var _viewWidth:Number;
		private var _viewHeight:Number;
		private var _viewRadius:Number;
		private var _depthCompareTolerance:Number = 0.0001;
		
		public function FreeLight3D(color:uint, zNear:Number, zFar:Number, lightType:String, lightCone:String, viewRadius:Number = NaN, viewWidth:Number = NaN, viewHeight:Number = NaN, fov:Number = NaN, hFov:Number = NaN, vFov:Number = NaN)
		{
			_lightType = lightType;
			_lightCone = lightCone;
			_viewRadius = viewRadius;
			_viewWidth = viewWidth;
			_viewHeight = viewHeight;
			_fov = fov;
			_hFov = hFov;
			_vFov = vFov;
			super(color, zNear, zFar);
			_depthCompareTolerance = 6 / _zFar; //初始化depthCompareTorlerance
			updateLightHead();
			updateLightBody();
			if(_lightHead)
			{
				_lightHead.mouseEnabled = true;
				_lightHead.name = "lightHead";
			}
			if(_lightBody)
				_lightBody.name = "lightBody";
			actAsGroup = true; //灯光作为可选中单位存在。
			isSelected = false; //默认没被选中
		}
		
		public function get hFov():Number
		{
			return _hFov;
		}
		public function set hFov(value:Number):void
		{
			if(_hFov != value)
				_hFov = value;
		}
		public function get vFov():Number
		{
			return _vFov;
		}
		public function set vFov(value:Number):void
		{
			if(_vFov != value)
				_vFov = value;
		}
		public function get fov():Number
		{
			return _fov;
		}
		public function set fov(value:Number):void
		{
			if(_fov != value)
				_fov = value;
		}
		public function get viewWidth():Number
		{
			return _viewWidth;
		}
		public function set viewWidth(value:Number):void
		{
			if(_viewWidth != value)
				_viewWidth = value;
		}
		public function get viewHeight():Number
		{
			return _viewHeight;
		}
		public function set viewHeight(value:Number):void
		{
			if(_viewHeight != value)
				_viewHeight = value;
		}
		public function get viewRadius():Number
		{
			return _viewRadius;
		}
		public function set viewRadius(value:Number):void
		{
			if(_viewRadius != value)
				_viewRadius = value;
		}
		public function get depthCompareTolerance():Number
		{
			return _depthCompareTolerance;
		}
		public function set depthCompareTolerance(value:Number):void
		{
			_depthCompareTolerance = value;
		}
		public function get lightType():String
		{
			return _lightType;
		}
		public function set lightType(value:String):void
		{
			if(_lightType == value)
				return ;
			_lightType = value;
			
			if(_lightType == TYPE_SPOT_LIGHT) //平行光->聚光灯
			{
				if(_lightCone == CONE_RECTANGLE)
				{
					_hFov = Math.atan(_viewWidth / 2 / _zFar) * 2;
					_vFov = Math.atan(_viewHeight / 2 / _zFar) * 2;
				}
				else if(_lightCone == CONE_CIRCLE)
				{
					_fov = Math.atan(_viewRadius / _zFar) * 2;
				}
			}
			else if(_lightType == TYPE_DIRECTIONAL_LIGHT) //聚光灯->平行光
			{
				if(_lightCone == CONE_RECTANGLE)
				{
					_viewWidth = Math.tan(_hFov / 2) * _zFar * 2;
					_viewHeight = Math.tan(_vFov / 2) * _zFar * 2;
				}
				else if(_lightCone == CONE_CIRCLE)
				{
					_viewRadius = Math.tan(_fov / 2) * _zFar;
				}
			}
			
			//更新light body
			updateLightBody();
		}
		public function get lightCone():String
		{
			return _lightCone;
		}
		public function set lightCone(value:String):void
		{
			if(_lightCone == value)
				return ;
			_lightCone = value;
			if(_lightCone == CONE_RECTANGLE) //圆锥->方锥
			{
				if(_lightType == TYPE_SPOT_LIGHT)
				{
					_hFov = _vFov = _fov;
				}
				else if(_lightType == TYPE_DIRECTIONAL_LIGHT)
				{
					_viewWidth = _viewHeight = _viewRadius * Math.SQRT2;
				}
			}
			else if(_lightCone == CONE_CIRCLE) //方锥->圆锥
			{
				if(_lightType == TYPE_SPOT_LIGHT)
				{
					_fov = Math.max(_hFov, _vFov);
				}
				else if(_lightType == TYPE_DIRECTIONAL_LIGHT)
				{
					_viewRadius = Math.sqrt(_viewWidth * _viewWidth + _viewHeight * _viewHeight) / 2;
				}
			}
			
			//更新light body
			updateLightBody();
		}
		
		override public function calculateProjectionMatrix():void
		{
			if(!projectionMatrix)
				projectionMatrix = new Matrix3D();
			
			if(_lightType == TYPE_SPOT_LIGHT)
			{
				if(_lightCone == CONE_RECTANGLE) //聚光灯，矩形椎体
				{
					projectionMatrix.copyRawDataFrom(Vector.<Number>([
						1.0 / Math.tan(_hFov / 2.0), 0.0, 0.0, 0.0, 
						0.0, 1.0 / Math.tan(_vFov / 2.0), 0.0, 0.0, 
						0.0, 0.0, _zFar / (_zNear - _zFar), -1.0, 
						0.0, 0.0, (_zNear * _zFar) / (_zNear - _zFar), 0.0
					]));
				}
				else if(_lightCone == CONE_CIRCLE) //聚光灯，圆形椎体
				{
					projectionMatrix.copyRawDataFrom(Vector.<Number>([
						1.0 / Math.tan(_fov / 2.0), 0.0, 0.0, 0.0, 
						0.0, 1.0 / Math.tan(_fov / 2.0), 0.0, 0.0, 
						0.0, 0.0, _zFar / (_zNear - _zFar), -1.0, 
						0.0, 0.0, (_zNear * _zFar) / (_zNear - _zFar), 0.0
					]));
				}
			}
			else if(_lightType == TYPE_DIRECTIONAL_LIGHT)
			{
				if(_lightCone == CONE_RECTANGLE) //平行光，矩形椎体
				{
					projectionMatrix.copyRawDataFrom(Vector.<Number>([
						2.0 / _viewWidth, 0.0, 0.0, 0.0, 
						0.0, 2.0 / _viewHeight, 0.0, 0.0, 
						0.0, 0.0, 1.0 / (_zNear - _zFar), 0.0, 
						0.0, 0.0, _zNear / (_zNear - _zFar), 1.0
					]));
				}
				else if(_lightCone == CONE_CIRCLE) //平行光，圆形椎体
				{
					projectionMatrix.copyRawDataFrom(Vector.<Number>([
						1.0 / _viewRadius, 0.0, 0.0, 0.0, 
						0.0, 1.0 / _viewRadius, 0.0, 0.0, 
						0.0, 0.0, 1.0 / (_zNear - _zFar), 0.0, 
						0.0, 0.0, _zNear / (_zNear - _zFar), 1.0
					]));
				}
			}
		}
		
		public function updateLightHead():void
		{
			var screenSize:Number = 10;
			var v0:Vector3D = localToCameraMatrix.transformVector(new Vector3D());
			var halfA:Number = Math.abs(v0.z) / Jehovah.camera.focalLength * screenSize;
//			var halfA:Number = 10;
			var vertexList:Vector.<Vector3D> = new Vector.<Vector3D>();
			vertexList.push(
				new Vector3D(halfA, halfA, 0), 
				new Vector3D(-halfA, halfA, 0), 
				new Vector3D(-halfA, halfA, 0), 
				new Vector3D(-halfA, -halfA, 0), 
				new Vector3D(-halfA, -halfA, 0), 
				new Vector3D(halfA, -halfA, 0), 
				new Vector3D(halfA, -halfA, 0), 
				new Vector3D(halfA, halfA, 0), 
				
				new Vector3D(halfA, halfA, -halfA * 4), 
				new Vector3D(-halfA, halfA, -halfA * 4), 
				new Vector3D(-halfA, halfA, -halfA * 4), 
				new Vector3D(-halfA, -halfA, -halfA * 4), 
				new Vector3D(-halfA, -halfA, -halfA * 4), 
				new Vector3D(halfA, -halfA, -halfA * 4), 
				new Vector3D(halfA, -halfA, -halfA * 4), 
				new Vector3D(halfA, halfA, -halfA * 4), 
				
				new Vector3D(halfA, halfA, 0), 
				new Vector3D(halfA, halfA, -halfA * 4), 
				new Vector3D(-halfA, halfA, 0), 
				new Vector3D(-halfA, halfA, -halfA * 4), 
				new Vector3D(-halfA, -halfA, 0), 
				new Vector3D(-halfA, -halfA, -halfA * 4), 
				new Vector3D(halfA, -halfA, 0), 
				new Vector3D(halfA, -halfA, -halfA * 4)
			);
			vertexList.push(
				new Vector3D(halfA * 2, halfA * 2, -halfA * 4), 
				new Vector3D(-halfA * 2, halfA * 2, -halfA * 4), 
				new Vector3D(-halfA * 2, halfA * 2, -halfA * 4), 
				new Vector3D(-halfA * 2, -halfA * 2, -halfA * 4), 
				new Vector3D(-halfA * 2, -halfA * 2, -halfA * 4), 
				new Vector3D(halfA * 2, -halfA * 2, -halfA * 4), 
				new Vector3D(halfA * 2, -halfA * 2, -halfA * 4), 
				new Vector3D(halfA * 2, halfA * 2, -halfA * 4), 
				
				new Vector3D(halfA * 2, halfA * 2, -halfA * 4), 
				new Vector3D(0, 0, -halfA * 6), 
				new Vector3D(-halfA * 2, halfA * 2, -halfA * 4), 
				new Vector3D(0, 0, -halfA * 6), 
				new Vector3D(-halfA * 2, -halfA * 2, -halfA * 4), 
				new Vector3D(0, 0, -halfA * 6), 
				new Vector3D(halfA * 2, -halfA * 2, -halfA * 4), 
				new Vector3D(0, 0, -halfA * 6)
			);
			
			if(!_lightHead)
			{
				_lightHead = new WireFrame(vertexList, 0xFFFFFF, 2);
				addChild(_lightHead);
			}
			else
				_lightHead.vertexList = vertexList;
		}
		
		private function updateLightBody_Directional_Rect():void
		{
			var vertexList:Vector.<Vector3D> = WireFrame.generateBoxVertexList(_viewWidth, _viewHeight, -_zFar);
			var i:int;
			for(i = 0; i < 8; i ++)
				vertexList.push(new Vector3D(vertexList[i].x, vertexList[i].y, -_zNear));
			
			if(!_lightBody)
			{
				_lightBody = new WireFrame(vertexList, 0xFFFFFF, 2);
				addChild(_lightBody);
			}
			else
				_lightBody.vertexList = vertexList;
		}
		
		private function updateLightBody_Directional_Circle():void
		{
			var vertexList:Vector.<Vector3D> = new Vector.<Vector3D>();
			var i:int;
			var segCount:int = 18;
			var circlePoints:Array = generateCirclePoints(segCount, _viewRadius);
			for(i = 0; i < segCount; i ++)
				vertexList.push(
					new Vector3D(circlePoints[i].x, circlePoints[i].y, 0), 
					new Vector3D(circlePoints[MyMath.nextIndex(i, segCount)].x, circlePoints[MyMath.nextIndex(i, segCount)].y, 0), 
					new Vector3D(circlePoints[i].x, circlePoints[i].y, -_zNear), 
					new Vector3D(circlePoints[MyMath.nextIndex(i, segCount)].x, circlePoints[MyMath.nextIndex(i, segCount)].y, -_zNear), 
					new Vector3D(circlePoints[i].x, circlePoints[i].y, -_zFar), 
					new Vector3D(circlePoints[MyMath.nextIndex(i, segCount)].x, circlePoints[MyMath.nextIndex(i, segCount)].y, -_zFar), 
					
					new Vector3D(circlePoints[i].x, circlePoints[i].y, 0), 
					new Vector3D(circlePoints[i].x, circlePoints[i].y, -_zFar)
				);
			
			if(!_lightBody)
			{
				_lightBody = new WireFrame(vertexList, 0xFFFFFF, 2);
				addChild(_lightBody);
			}
			else
				_lightBody.vertexList = vertexList;
		}
		
		private function updateLightBody_Spot_Rect():void
		{
			var vertexList:Vector.<Vector3D> = new Vector.<Vector3D>();
			var x0:Number = _zFar * Math.tan(_hFov / 2);
			var y0:Number = _zFar * Math.tan(_vFov / 2);
			vertexList.push(
				new Vector3D(), 
				new Vector3D(x0, y0, -_zFar), 
				new Vector3D(), 
				new Vector3D(-x0, y0, -_zFar), 
				new Vector3D(), 
				new Vector3D(-x0, -y0, -_zFar), 
				new Vector3D(), 
				new Vector3D(x0, -y0, -_zFar), 
				
				new Vector3D(x0, y0, -_zFar), 
				new Vector3D(-x0, y0, -_zFar), 
				new Vector3D(-x0, y0, -_zFar), 
				new Vector3D(-x0, -y0, -_zFar), 
				new Vector3D(-x0, -y0, -_zFar), 
				new Vector3D(x0, -y0, -_zFar), 
				new Vector3D(x0, -y0, -_zFar), 
				new Vector3D(x0, y0, -_zFar)
			);
			x0 = _zNear * Math.tan(_hFov / 2);
			y0 = _zNear * Math.tan(_vFov / 2);
			vertexList.push(
				new Vector3D(x0, y0, -_zNear), 
				new Vector3D(-x0, y0, -_zNear), 
				new Vector3D(-x0, y0, -_zNear), 
				new Vector3D(-x0, -y0, -_zNear), 
				new Vector3D(-x0, -y0, -_zNear), 
				new Vector3D(x0, -y0, -_zNear), 
				new Vector3D(x0, -y0, -_zNear), 
				new Vector3D(x0, y0, -_zNear)
			);
			
			if(!_lightBody)
			{
				_lightBody = new WireFrame(vertexList, 0xFFFFFF, 2);
				addChild(_lightBody);
			}
			else
				_lightBody.vertexList = vertexList;
		}
		private function updateLightBody_Spot_Circle():void
		{
			var vertexList:Vector.<Vector3D> = new Vector.<Vector3D>();
			var i:int;
			var segCount:int = 18;
			var circlePoints:Array = generateCirclePoints(segCount, 1);
			for(i = 0; i < segCount; i ++)
				vertexList.push(
					new Vector3D(circlePoints[i].x * _zNear * Math.tan(_fov / 2), circlePoints[i].y * _zNear * Math.tan(_fov / 2), -_zNear), 
					new Vector3D(circlePoints[MyMath.nextIndex(i, segCount)].x * _zNear * Math.tan(_fov / 2), circlePoints[MyMath.nextIndex(i, segCount)].y * _zNear * Math.tan(_fov / 2), -_zNear), 
					new Vector3D(circlePoints[i].x * _zFar * Math.tan(_fov / 2), circlePoints[i].y * _zFar * Math.tan(_fov / 2), -_zFar), 
					new Vector3D(circlePoints[MyMath.nextIndex(i, segCount)].x * _zFar * Math.tan(_fov / 2), circlePoints[MyMath.nextIndex(i, segCount)].y * _zFar * Math.tan(_fov / 2), -_zFar), 
					
					new Vector3D(), 
					new Vector3D(circlePoints[i].x * _zFar * Math.tan(_fov / 2), circlePoints[i].y * _zFar * Math.tan(_fov / 2), -_zFar)
				);
			
			if(!_lightBody)
			{
				_lightBody = new WireFrame(vertexList, 0xFFFFFF, 2);
				addChild(_lightBody);
			}
			else
				_lightBody.vertexList = vertexList;
		}
		private function generateCirclePoints(segCount:int, radius:Number):Array
		{
			var ret:Array = new Array();
			var i:int;
			var angle:Number = 2 * Math.PI / segCount;
			for(i = 0; i < segCount; i ++)
				ret.push({
					"x": Math.cos(i * angle) * radius, 
					"y": Math.sin(i * angle) * radius
				});
			return ret;
		}
		public function updateLightBody():void
		{
			if(_lightType == TYPE_SPOT_LIGHT)
			{
				if(_lightCone == CONE_RECTANGLE) //聚光灯，矩形椎体
					updateLightBody_Spot_Rect();
				else if(_lightCone == CONE_CIRCLE) //聚光灯，圆形椎体
					updateLightBody_Spot_Circle();
			}
			else if(_lightType == TYPE_DIRECTIONAL_LIGHT)
			{
				if(_lightCone == CONE_RECTANGLE) //平行光，矩形椎体
					updateLightBody_Directional_Rect();
				else if(_lightCone == CONE_CIRCLE) //平行光，圆形椎体
					updateLightBody_Directional_Circle();
			}
		}
		
		override public function set isSelected(value:Boolean):void
		{
			_isSelected = value;
			_lightBody.visible = _isSelected;
		}
		
		public static function fromObject(obj:Object):FreeLight3D
		{
			var light:FreeLight3D;
			if(obj.lightType == TYPE_DIRECTIONAL_LIGHT)
			{
				if(obj.lightCone == CONE_CIRCLE)
				{
					light = new FreeLight3D(obj.color, obj.zNear, obj.zFar, obj.lightType, obj.lightCone, obj.viewRadius);
				}
				else if(obj.lightCone == CONE_RECTANGLE)
				{
					light = new FreeLight3D(obj.color, obj.zNear, obj.zFar, obj.lightType, obj.lightCone, NaN, obj.viewWidth, obj.viewHeight);
				}
			}
			else if(obj.lightType == TYPE_SPOT_LIGHT)
			{
				if(obj.lightCone == CONE_CIRCLE)
				{
					light = new FreeLight3D(obj.color, obj.zNear, obj.zFar, obj.lightType, obj.lightCone, NaN, NaN, NaN, obj.fov);
				}
				else if(obj.lightCone == CONE_RECTANGLE)
				{
					light = new FreeLight3D(obj.color, obj.zNear, obj.zFar, obj.lightType, obj.lightCone, NaN, NaN, NaN, NaN, obj.hFov, obj.vFov);
				}
			}
			light.depthCompareTolerance = obj.depthCompareTolerance;
			light.useShadow = obj.useShadow;
			light.shadowmappingsize = obj.shadowmappingsize;
			light.matrix = new Matrix3D(MyMath.numberArrayToNumberVector(obj.matrix));
			
			return light;
		}
		/**
		 * 保存灯光为一个Object
		 * @return 
		 * 
		 */		
		public function toObject():Object
		{
			var ret:Object = {};
			
			ret.color = color.hexColor;
			ret.depthCompareTolerance = depthCompareTolerance;
			ret.zNear = zNear;
			ret.zFar = zFar;
			ret.lightType = lightType;
			ret.lightCone = lightCone;
			ret.useShadow = useShadow;
			ret.shadowmappingsize = shadowmappingsize;
			ret.matrix = MyMath.arrayOrVectorToObjectArray(matrix.rawData);
			if(lightType == TYPE_DIRECTIONAL_LIGHT)
			{
				if(lightCone == CONE_CIRCLE)
				{
					ret.viewRadius = viewRadius;
				}
				else if(lightCone == CONE_RECTANGLE)
				{
					ret.viewWidth = viewWidth;
					ret.viewHeight = viewHeight;
				}
			}
			else if(lightType == TYPE_SPOT_LIGHT)
			{
				if(lightCone == CONE_CIRCLE)
				{
					ret.fov = fov;
				}
				else if(lightCone == CONE_RECTANGLE)
				{
					ret.hFov = hFov;
					ret.vFov = vFov;
				}
			}
			
			return ret;
		}
		
		override public function toString():String
		{
			return "[FreeLight3D(截头方椎):" + name + "]";
		}
	}
}