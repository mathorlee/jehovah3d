package jehovah3d.core
{
	import com.fuwo.math.MyMath;
	
	import flash.display3D.Context3D;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.pick.MousePickData;
	import jehovah3d.core.pick.MousePickManager;
	import jehovah3d.core.pick.Ray;
	import jehovah3d.core.resource.GeometryResource;
	import jehovah3d.core.wireframe.WireFrame;

	public class Object3D extends EventDispatcher
	{
		public static const FOCUS_BORDER_COLOR:uint = 0xFFFFFF;
		
		private var _name:String = "";
		private var _mouseEnabled:Boolean = true;
		protected var _doppergangerGeometry:GeometryResource;
		private var _participateInCollisionDetection:Boolean = true;
		private var _visible:Boolean = true;
		protected var _useMip:Boolean = true;
		protected var _x:Number = 0;
		protected var _y:Number = 0;
		protected var _z:Number = 0;
		protected var _rotationX:Number = 0;
		protected var _rotationY:Number = 0;
		protected var _rotationZ:Number = 0;
		protected var _scaleX:Number = 1;
		protected var _scaleY:Number = 1;
		protected var _scaleZ:Number = 1;
		protected var _transformChanged:Boolean = false;
		protected var _isSelected:Boolean = false;
		private var _selectWF:WireFrame;
		
		public var actAsGroup:Boolean = false;
		
		private var childs:Vector.<Object3D> = new Vector.<Object3D>();
		private var _parent:Object3D = null;
		
		protected var _matrix:Matrix3D = new Matrix3D();
		protected var _inverseMatrix:Matrix3D = new Matrix3D();
		public var localToGlobalMatrix:Matrix3D = new Matrix3D();
		public var globalToLocalMatrix:Matrix3D = new Matrix3D();
		public var localToCameraMatrix:Matrix3D = new Matrix3D();
		public var finalMatrix:Matrix3D = new Matrix3D();
		
		/**
		 * base class for object in 3D world. 
		 * 
		 */		
		public function Object3D(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		/**
		 * update matrix. 
		 * 
		 */		
		public function updateMatrix():void
		{
			updateAnimation();
			if(_transformChanged)
				composeTransform();
		}
		
		/**
		 * update hierarchy matrix. 
		 * 
		 */		
		public function updateHierarchyMatrix():void
		{
			var i:int;
			var child:Object3D;
			for(i = numChildren - 1; i >= 0; i --)
			{
				child = getChildAt(i);
				child.updateMatrix();
				child.localToGlobalMatrix.copyFrom(child.matrix);
				child.localToGlobalMatrix.append(localToGlobalMatrix);
				child.globalToLocalMatrix.copyFrom(globalToLocalMatrix)
				child.globalToLocalMatrix.append(child.inverseMatrix);
				child.localToCameraMatrix.copyFrom(child.matrix);
				child.localToCameraMatrix.append(localToCameraMatrix);
				child.finalMatrix.copyFrom(child.matrix);
				child.finalMatrix.append(finalMatrix);
				child.updateHierarchyMatrix();
			}
			updateDefer();
		}
		
		/**
		 * update hierarchy visibility. 
		 * 
		 */		
		public function updateChildVisibility():void
		{
			var i:int;
			var child:Object3D;
			for(i = numChildren - 1; i >= 0; i --)
			{
				child = getChildAt(i);
				child.visible = _visible;
			}
		}
		
		/**
		 * re-upload object3d's resource to GPU, include the descendants'. this is to handle Context3D loss. 
		 * @param context3D
		 * 
		 */		
		public function uploadResource(context3D:Context3D):void
		{
			uploadChildrenResourcee(context3D);
		}
		
		/**
		 * re-upload children's resource to GPU. this is to handle Context3D loss.
		 * @param context3D
		 * 
		 */		
		public function uploadChildrenResourcee(context3D:Context3D):void
		{
			var i:int;
			var child:Object3D;
			for(i = numChildren - 1; i >= 0; i --)
			{
				child = getChildAt(i);
				child.uploadResource(context3D);
			}
		}
		
		/**
		 * mousePick. 
		 * @param ray: ray in world space.
		 * 
		 */		
		public function mousePick(ray:Ray):void
		{
			if(!_mouseEnabled || !_visible)
				return ;
			
			var rayCopy:Ray = new Ray(globalToLocalMatrix.transformVector(ray.p0), globalToLocalMatrix.deltaTransformVector(ray.dir));
			var dist:Number;
			if(_doppergangerGeometry)
			{
				dist = _doppergangerGeometry.calculateIntersectionDist(rayCopy);
				if(dist)
					MousePickManager.add(new MousePickData(this.groupAncestor, this, dist));
			}
			else
				mousePickChildren(ray);
		}
		
		/**
		 * mouse pick children. 
		 * @param ray: ray in world space.
		 * 
		 */		
		public function mousePickChildren(ray:Ray):void
		{
			var i:int;
			var child:Object3D;
			for(i = numChildren - 1; i >= 0; i --)
			{
				child = getChildAt(i);
				child.mousePick(ray);
			}
		}
		
		/**
		 * check if route is blocked by this. 
		 * @param ray
		 * @return 
		 * 
		 */		
		public function routeBlocked(ray:Ray):Boolean
		{
			if(!_participateInCollisionDetection || !_visible)
				return false;
			return routeBlockedByChildren(ray);
		}
		
		/**
		 * check if route is blocked by children. 
		 * @param ray
		 * @return 
		 * 
		 */		
		public function routeBlockedByChildren(ray:Ray):Boolean
		{
			var i:int;
			var child:Object3D;
			for(i = numChildren - 1; i >= 0; i --)
			{
				child = getChildAt(i);
				if(child.routeBlocked(ray))
					return true;
			}
			return false;
		}
		
		/**
		 * collect render list. 
		 * @param renderList
		 * 
		 */		
		public function collectRenderList(opaqueRenderList:Vector.<Object3D>, transparentRenderList:Vector.<Object3D>):void
		{
			if(!_visible)
				return ;
			collectChildrenRenderList(opaqueRenderList, transparentRenderList);
		}
		public function collectChildrenRenderList(opaqueRenderList:Vector.<Object3D>, transparentRenderList:Vector.<Object3D>):void
		{
			var i:int;
			var child:Object3D;
			for(i = numChildren - 1; i >=0; i --)
			{
				child = getChildAt(i);
				child.collectRenderList(opaqueRenderList, transparentRenderList);
			}
		}
		
		/**
		 * add child. 
		 * @param child
		 * 
		 */		
		public function addChild(child:Object3D):void
		{
			if(isChildAddable(child))
			{
				childs.push(child);
				child._parent = this;
			}
		}
		
		/**
		 * add child at. 
		 * @param child
		 * @param index
		 * 
		 */		
		public function addChildAt(child:Object3D, index:int):void
		{
			if(index > numChildren)
				return ;
			if(isChildAddable(child))
			{
				childs.splice(index, 0, child);
				child._parent = this;
			}
		}
		
		/**
		 * remove child.
		 * @param child
		 * 
		 */		
		public function removeChild(child:Object3D):void
		{
			if(child._parent != this)
				throw new Error("");
			if(child == null)
				throw new Error("");
			if(child == this)
				throw new Error("");
			var i:int;
			for(i = 0; i < numChildren; i ++)
				if(getChildAt(i) == child)
				{
					child._parent = null;
					child.removeAllChild();
					child.dispose();
					childs.splice(i, 1);
				}
		}
		
		/**
		 * remove child at. 
		 * @param index
		 * 
		 */		
		public function removeChildAt(index:int):void
		{
			if(index < 0 || index >= numChildren)
				throw new Error("index error.");
			var child:Object3D = getChildAt(index);
			if(child != null)
			{
				child._parent = null;
				child.removeAllChild();
				child.dispose();
				childs.splice(index, 1);
			}
		}
		
		/**
		 * remove all child. 
		 * 
		 */		
		public function removeAllChild():void
		{
			var i:int;
			for(i = numChildren - 1; i >= 0; i --)
				removeChildAt(i);
		}
		
		/**
		 * get child at.
		 * @param index
		 * @return 
		 * 
		 */		
		public function getChildAt(index:int):Object3D
		{
			if(index < 0 || index >= numChildren)
				return null;
			return childs[index];
		}
		
		public function getChildByName(childName:String):Object3D
		{
			var i:int;
			for(i = numChildren - 1; i >= 0; i --)
				if(childs[i].name == childName)
					return childs[i];
			return null;
		}
		
		public function getChildByName_DeepDown(childName:String):Object3D
		{
			var obj3d:Object3D = getChildByName(childName);
			if(obj3d)
				return obj3d;
			var i:int;
			for(i = numChildren - 1; i >= 0; i --)
			{
				obj3d = childs[i].getChildByName_DeepDown(childName);
				if(obj3d)
					return obj3d;
			}
			return null;
		}
		
		/**
		 * is child addable. 
		 * @param child
		 * @return 
		 * 
		 */		
		private function isChildAddable(child:Object3D):Boolean
		{
			if(child.parent != null)
				return false;
			if(child == null)
				return false;
			if(child == this)
				return false;
			for(var obj:Object3D = _parent; obj != null; obj = obj.parent)
				if(obj == child)
					return false;
			return true;
		}
		
		/**
		 * number of children. 
		 * @return 
		 * 
		 */		
		public function get numChildren():int
		{
			return childs.length;
		}
		
		public function composeTransform():void
		{
//			trace(this + "composeTransform");
			_matrix.identity();
			_matrix.appendScale(scaleX, scaleY, scaleZ);
			_matrix.appendRotation(rotationX * 180 / Math.PI, Vector3D.X_AXIS);
			_matrix.appendRotation(rotationY * 180 / Math.PI, Vector3D.Y_AXIS);
			_matrix.appendRotation(rotationZ * 180 / Math.PI, Vector3D.Z_AXIS);
			_matrix.appendTranslation(x, y, z);
			
			_inverseMatrix.identity();
			_inverseMatrix.appendTranslation(-x, -y, -z);
			_inverseMatrix.appendRotation(-rotationZ * 180 / Math.PI, Vector3D.Z_AXIS);
			_inverseMatrix.appendRotation(-rotationY * 180 / Math.PI, Vector3D.Y_AXIS);
			_inverseMatrix.appendRotation(-rotationX * 180 / Math.PI, Vector3D.X_AXIS);
			_inverseMatrix.appendScale(1 / scaleX, 1 / scaleY, 1 / scaleZ);
			_transformChanged = false;
		}
		
		public function get rotateMatrix():Matrix3D
		{
			var ret:Matrix3D = new Matrix3D();
			ret.appendRotation(rotationX * 180 / Math.PI, Vector3D.X_AXIS);
			ret.appendRotation(rotationY * 180 / Math.PI, Vector3D.Y_AXIS);
			ret.appendRotation(rotationZ * 180 / Math.PI, Vector3D.Z_AXIS);
			return ret;
		}
		
		/**
		 * dispose memory. 
		 * 
		 */		
		public function dispose():void
		{
			if(_matrix)
				_matrix = null;
			if(_inverseMatrix)
				_inverseMatrix = null;
			if(localToGlobalMatrix)
				localToGlobalMatrix = null;
			if(globalToLocalMatrix)
				globalToLocalMatrix = null;
			if(localToCameraMatrix)
				localToCameraMatrix = null;
			if(finalMatrix)
				finalMatrix = null;
			removeDeferredFunction();
			if(_doppergangerGeometry)
			{
				_doppergangerGeometry.dispose();
				_doppergangerGeometry = null;
			}
		}
		
		
		
		
		/**
		 * 根据name显示/隐藏后代。 
		 * @param nameToHide: 影响名字里有这个字符串后代。
		 * @param visibility: 可见/不可见。
		 * @param affectDescendant: 影响一代还是后代。
		 * 
		 */		
		public function setChildrenVisibilityByName(nameToHide:String, visibility:Boolean, affectDescendant:Boolean):void
		{
			var i:int;
			for(i = 0; i < childs.length; i ++)
			{
				if(childs[i].name != null && childs[i].name.indexOf(nameToHide) != -1)
					childs[i].visible = visibility;
				else if(affectDescendant)
					childs[i].setChildrenVisibilityByName(nameToHide, visibility, affectDescendant);
			}
		}
		
		/**
		 * 根据Class类型显示/隐藏后代。 
		 * @param classToHide
		 * @param visibility
		 * @param affectDescendant: 影响一代还是后代。
		 * 
		 */		
		public function setChildrenVisibilityByClass(classToHide:Class, visibility:Boolean, affectDescendant:Boolean):void
		{
			var i:int;
			for(i = 0; i < childs.length; i ++)
			{
				if(childs[i] is classToHide)
					childs[i].visible = visibility;
				else if(affectDescendant)
					childs[i].setChildrenVisibilityByClass(classToHide, visibility, affectDescendant);
			}
		}
		
		public function convertMovementToAnotherObject3D(movement:Vector3D, anotherObj:Object3D):Vector3D
		{
			return anotherObj.globalToLocalMatrix.deltaTransformVector(localToGlobalMatrix.deltaTransformVector(movement));
		}
		
		
		/**
		 * {"doppelganger": String, "frameCount": int, "startFrameIndex": int, "stopFrameIndex": int, "matrices": [], "instruction": String}
		 * 
		 */		
		public var animation:Object;
		public var frameIndex:int;
		public var totalAnimationFrame:int; //整体动画的长度
		public var inverseAnimation:Boolean = false;
		public static const START_ANIMATION:String = "StartAnimation";
		public static const STOP_ANIMATION:String = "StopAnimation";
		public function addAnimation(animationArg:Object, totalAnimationFrameArg:int):void
		{
			animation = animationArg;
			frameIndex = 0;
			totalAnimationFrame = totalAnimationFrameArg;
			matrix = new Matrix3D(MyMath.numberArrayToNumberVector(animation.matrices[0].rawData));
			inverseAnimation = false;
		}
		public function updateAnimation():void
		{
			if(!animation)
				return ;
			if(frameIndex > animation.startFrameIndex && frameIndex < animation.stopFrameIndex)
				matrix = new Matrix3D(MyMath.numberArrayToNumberVector(animation.matrices[frameIndex - animation.startFrameIndex].rawData));
			else if(frameIndex <= animation.startFrameIndex && frameIndex >= 0)
				matrix = new Matrix3D(MyMath.numberArrayToNumberVector(animation.matrices[animation.startFrameIndex - animation.startFrameIndex].rawData));
			else if(frameIndex >= animation.stopFrameIndex && frameIndex <= totalAnimationFrame)
				matrix = new Matrix3D(MyMath.numberArrayToNumberVector(animation.matrices[animation.stopFrameIndex - animation.startFrameIndex].rawData));
			
			if(!inverseAnimation && frameIndex <= totalAnimationFrame)
			{
				if(frameIndex == animation.startFrameIndex)
					dispatchEvent(new Event(START_ANIMATION, false, false));
				else if(frameIndex == animation.stopFrameIndex)
					dispatchEvent(new Event(STOP_ANIMATION, false, false));
				frameIndex ++;
			}
			if(inverseAnimation && frameIndex >= animation.startFrameIndex)
				frameIndex --;
		}
		public function get instruction():String
		{
			if(animation)
				return animation.instruction;
			return null;
		}
		
		
		
		private var _deferredFrameCount:int = 0;
		private var _deferredFrameTicked:int = 0;
		private var _deferredFunctions:Vector.<Function>;
		public function addDeferredFunction(deferredFrameCount:int, deferredFunctionList:Vector.<Function>):void
		{
			_deferredFrameCount = deferredFrameCount;
			_deferredFrameTicked = 0;
			_deferredFunctions = deferredFunctionList.slice();
		}
		public function removeDeferredFunction():void
		{
			_deferredFrameCount = _deferredFrameTicked = 0;
			if(_deferredFunctions)
			{
				_deferredFunctions.length = 0;
				_deferredFunctions = null;
			}
		}
		public function updateDefer():void
		{
			if(_deferredFrameTicked < _deferredFrameCount)
			{
				_deferredFrameTicked ++;
				if(_deferredFrameTicked == _deferredFrameCount)
				{
					for each(var func:Function in _deferredFunctions)
						func.apply(null);
				}
			}
		}
		
		public function setPositionByVector3D(position:Vector3D):void
		{
			x = position.x;
			y = position.y;
			z = position.z;
		}
		
		
		public function get name():String
		{
			return _name;
		}
		public function set name(val:String):void
		{
			if(_name != val)
				_name = val;
		}
		
		/**
		 * mouse enabled. if true, participate in mouse pick event. 
		 * @return 
		 * 
		 */		
		public function get mouseEnabled():Boolean
		{
			return _mouseEnabled;
		}
		public function set mouseEnabled(val:Boolean):void
		{
			_mouseEnabled = val;
			var i:int;
			var child:Object3D;
			for(i = numChildren - 1; i >= 0; i --)
			{
				child = getChildAt(i);
				child.mouseEnabled = val;
			}
		}
		/**
		 * participate in collision detection. if false, camera can move "through" the object, otherwise can't. 
		 * @return 
		 * 
		 */		
		public function get participateInCollisionDetection():Boolean
		{
			return _participateInCollisionDetection;
		}
		public function set participateInCollisionDetection(val:Boolean):void
		{
			_participateInCollisionDetection = val;
			var i:int;
			var child:Object3D;
			for(i = numChildren - 1; i >= 0; i --)
			{
				child = getChildAt(i);
				child.participateInCollisionDetection = val;
			}
		}
		
		public function get visible():Boolean
		{
			return _visible;
		}
		public function set visible(val:Boolean):void
		{
			if(_visible != val)
			{
				_visible = val;
				updateChildVisibility();
			}
		}
		
		public function get x():Number
		{
			return _x;
		}
		public function set x(val:Number):void
		{
			if(_x != val)
			{
				_x = val;
				_transformChanged = true;
			}
		}
		public function get y():Number
		{
			return _y;
		}
		public function set y(val:Number):void
		{
			if(_y != val)
			{
				_y = val;
				_transformChanged = true;
			}
		}
		public function get z():Number
		{
			return _z;
		}
		public function set z(val:Number):void
		{
			if(_z != val)
			{
				_z = val;
				_transformChanged = true;
			}
		}
		public function get rotationX():Number
		{
			return _rotationX;
		}
		public function set rotationX(val:Number):void
		{
			//[-PI, PI]
			_rotationX = val;
			if(_rotationX > Math.PI)
				_rotationX -= Math.PI * 2;
			if(_rotationX < -Math.PI)
				_rotationX += Math.PI * 2;
			_transformChanged = true;
		}
		public function get rotationY():Number
		{
			return _rotationY;
		}
		public function set rotationY(val:Number):void
		{
			//[-PI, PI]
			_rotationY = val;
			if(_rotationY > Math.PI)
				_rotationY -= Math.PI * 2;
			if(_rotationY < -Math.PI)
				_rotationY += Math.PI * 2;
			_transformChanged = true;
		}
		public function get rotationZ():Number
		{
			return _rotationZ;
		}
		public function set rotationZ(val:Number):void
		{
			//[-PI, PI]
			_rotationZ = val;
			if(_rotationZ > Math.PI)
				_rotationZ -= Math.PI * 2;
			if(_rotationZ < -Math.PI)
				_rotationZ += Math.PI * 2;
			_transformChanged = true;
		}
		public function get scaleX():Number
		{
			return _scaleX;
		}
		public function set scaleX(val:Number):void
		{
			if(_scaleX != val)
			{
				_scaleX = val;
				_transformChanged = true;
			}
		}
		public function get scaleY():Number
		{
			return _scaleY;
		}
		public function set scaleY(val:Number):void
		{
			if(_scaleY != val)
			{
				_scaleY = val;
				_transformChanged = true;
			}
		}
		public function get scaleZ():Number
		{
			return _scaleZ;
		}
		public function set scaleZ(val:Number):void
		{
			if(_scaleZ != val)
			{
				_scaleZ = val;
				_transformChanged = true;
			}
		}
		public function get position():Vector3D
		{
			return new Vector3D(_x, _y, _z);
		}
		public function set position(value:Vector3D):void
		{
			_x = value.x;
			_y = value.y;
			_z = value.z;
			_transformChanged = true;
		}
		
		/**
		 * global position。 
		 * @return 
		 * 
		 */		
		public function get globalPosition():Vector3D
		{
			return localToGlobalMatrix.transformVector(new Vector3D(0, 0, 0));
		}
		
		public function get transformChanged():Boolean
		{
			return _transformChanged;
		}
		public function get isSelected():Boolean
		{
			return _isSelected;
		}
		public function set isSelected(value:Boolean):void
		{
			if(_isSelected != value)
			{
				_isSelected = value;
				if(_isSelected)
				{
					if(!_selectWF)
					{
//						_selectWF = new WireFrame(bounding.selectWFPoints, 0xFCFCFC, 1);
						_selectWF = new WireFrame(bounding.selectWFPoints, 0xFFFFFF,2);
						_selectWF.mouseEnabled = false;
						addChild(_selectWF);
					}
				}
				else
				{
					if(_selectWF)
					{
						removeChild(_selectWF);
						_selectWF = null;
					}
				}
			}
		}
		public function get parent():Object3D
		{
			return _parent;
		}
		
		/**
		 * group ancestor. 
		 * @return 
		 * 
		 */		
		public function get groupAncestor():Object3D
		{
			var groups:Vector.<Object3D> = new Vector.<Object3D>();
			groups.push(this); //
			var p:Object3D = parent;
			while(p)
			{
				if(p.actAsGroup)
					groups.push(p);
				p = p.parent;
			}
			return groups[groups.length - 1];
		}
		
		public function get matrix():Matrix3D
		{
			return _matrix;
		}
		public function set matrix(val:Matrix3D):void
		{
			_matrix.copyFrom(val);
			var v:Vector.<Vector3D> = _matrix.decompose();
			var t:Vector3D = v[0];
			var r:Vector3D = v[1];
			var s:Vector3D = v[2];
			_x = t.x;
			_y = t.y;
			_z = t.z;
			_rotationX = r.x;
			_rotationY = r.y;
			_rotationZ = r.z;
			_scaleX = s.x;
			_scaleY = s.y;
			_scaleZ = s.z;
			_inverseMatrix.copyFrom(val);
			_inverseMatrix.invert();
			_transformChanged = false;
		}
		public function get noScaleMatrix():Matrix3D
		{
			var ret:Matrix3D = new Matrix3D();
			ret.appendRotation(rotationX * 180 / Math.PI, Vector3D.X_AXIS);
			ret.appendRotation(rotationY * 180 / Math.PI, Vector3D.Y_AXIS);
			ret.appendRotation(rotationZ * 180 / Math.PI, Vector3D.Z_AXIS);
			ret.appendTranslation(x, y, z);
			return ret;
		}
		public function get noScaleInverseMatrix():Matrix3D
		{
			var ret:Matrix3D = new Matrix3D();
			ret.appendTranslation(-x, -y, -z);
			ret.appendRotation(-rotationZ * 180 / Math.PI, Vector3D.Z_AXIS);
			ret.appendRotation(-rotationY * 180 / Math.PI, Vector3D.Y_AXIS);
			ret.appendRotation(-rotationX * 180 / Math.PI, Vector3D.X_AXIS);
			return ret;
		}
		
		public function get inverseMatrix():Matrix3D
		{
			return _inverseMatrix;
		}
		
		
		public function get bounding():Bounding
		{
			return childrenBounding;
		}
		
		public function get childrenBounding():Bounding
		{
			var bb:Bounding = new Bounding();
			
			var i:int;
			var j:int;
			var child:Object3D;
			for(i = numChildren - 1; i >=0; i --)
			{
				child = getChildAt(i);
				if(child is WireFrame)
					continue;
				var bbc:Bounding = child.bounding;
				var localPoints:Vector.<Vector3D> = bbc.eightPoint;
				var parentPoints:Vector.<Vector3D> = new Vector.<Vector3D>();
				for(j = 0; j < localPoints.length; j ++)
				{
					parentPoints.push(child.matrix.transformVector(localPoints[j]));
					bb.minX = Math.min(bb.minX, parentPoints[j].x);
					bb.minY = Math.min(bb.minY, parentPoints[j].y);
					bb.minZ = Math.min(bb.minZ, parentPoints[j].z);
					bb.maxX = Math.max(bb.maxX, parentPoints[j].x);
					bb.maxY = Math.max(bb.maxY, parentPoints[j].y);
					bb.maxZ = Math.max(bb.maxZ, parentPoints[j].z);
				}
			}
			if(numChildren > 0)
				bb.calculateDimension();
//			trace(this, this.name, bb.toString());
			return bb;
		}
		
		/**
		 * 计算多个物体的bounding。bounding中数值是全局坐标系下的。 
		 * @param objs
		 * @return 
		 * 
		 */		
		public static function calculateBoundingOfMultiObject(objs:Vector.<Object3D>):Bounding
		{
			var ret:Bounding = new Bounding();
			var i:int;
			var j:int;
			for(i = 0; i < objs.length; i ++)
			{
				var b0:Bounding = objs[i].bounding;
				var globalPoints:Vector.<Vector3D> = MyMath.transformVector3DList(b0.eightPoint, objs[i].localToGlobalMatrix, false);
				for(j = 0; j < globalPoints.length; j ++)
				{
					ret.minX = Math.min(ret.minX, globalPoints[j].x);
					ret.minY = Math.min(ret.minY, globalPoints[j].y);
					ret.minZ = Math.min(ret.minZ, globalPoints[j].z);
					ret.maxX = Math.max(ret.maxX, globalPoints[j].x);
					ret.maxY = Math.max(ret.maxY, globalPoints[j].y);
					ret.maxZ = Math.max(ret.maxZ, globalPoints[j].z);
				}
			}
			ret.calculateDimension();
			return ret;
		}
		
		/**
		 * 返回子孙中Mesh的个数。 
		 * @return 
		 * 
		 */		
		public function get meshNumInDescendants():int
		{
			var ret:int = 0;
			if(this is Mesh)
				ret ++;
			var i:int;
			var child:Object3D;
			for(i = 0; i < numChildren; i ++)
			{
				child = getChildAt(i);
				ret += child.meshNumInDescendants;
			}
			return ret;
		}
		public function set doppergangerGeometry(value:GeometryResource):void
		{
			if(_doppergangerGeometry != value)
				_doppergangerGeometry = value;
		}
		
		public function get useMip():Boolean
		{
			return _useMip;
		}
		public function set useMip(value:Boolean):void
		{
			_useMip = value;
			var i:int;
			var child:Object3D;
			for(i = numChildren - 1; i >= 0; i --)
			{
				child = getChildAt(i);
				child.useMip = value;
			}
		}
		
		override public function toString():String
		{
			return "[Object3D:" + name + "]";
		}
	}
}