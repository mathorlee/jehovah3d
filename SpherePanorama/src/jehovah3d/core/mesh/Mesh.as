package jehovah3d.core.mesh
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.Bounding;
	import jehovah3d.core.Context3DProperty;
	import jehovah3d.core.Object3D;
	import jehovah3d.core.light.FreeLight3D;
	import jehovah3d.core.material.DiffuseMtl;
	import jehovah3d.core.material.LightMtl;
	import jehovah3d.core.pick.MousePickData;
	import jehovah3d.core.pick.MousePickManager;
	import jehovah3d.core.pick.Ray;
	import jehovah3d.core.renderer.ARRenderer;
	import jehovah3d.core.renderer.AllRenderer;
	import jehovah3d.core.renderer.DSRendererFreeLight;
	import jehovah3d.core.renderer.DepthRenderer;
	import jehovah3d.core.renderer.NormalRenderer;
	import jehovah3d.core.renderer.Renderer;
	import jehovah3d.core.renderer.UniqueColorRenderer;
	import jehovah3d.core.resource.GeometryResource;
	import jehovah3d.util.HexColor;

	public class Mesh extends Object3D
	{
		//render type, affects render sequence
		public static const BG:uint = 0;
		public static const SKYBOX:uint = 1;
		public static const NORMAL_COMPARE_DEPTH:uint = 2;
		public static const LAST_ALWAYSE:uint = 3;
		public var renderType:uint = 2;
		public var uniqueColor:HexColor;
		public var renderPriority:int = 0; //渲染优先级. 小的先渲染, 大的后渲染
		
		protected var _geometry:GeometryResource;
		protected var _mtl:DiffuseMtl;
		protected var _useClamp:Boolean = false;
		
		protected var rendererDict:Dictionary = new Dictionary();
		
		public function Mesh()
		{
			
		}
		
		protected function renderAll(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			var no:String = AllRenderer.NAME;
			if(!rendererDict[no])
				rendererDict[no] = new AllRenderer(this);
			Renderer(rendererDict[no]).render(context3D, context3DProperty);
		}
		
		protected function renderDepth(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			var no:String = DepthRenderer.NAME;
			if(!rendererDict[no])
				rendererDict[no] = new DepthRenderer(this);
			Renderer(rendererDict[no]).render(context3D, context3DProperty);
		}
		
		protected function renderNormal(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			var no:String = NormalRenderer.NAME;
			if(!rendererDict[no])
				rendererDict[no] = new NormalRenderer(this);
			Renderer(rendererDict[no]).render(context3D, context3DProperty);
		}
		
		protected function renderAF(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			var no:String = ARRenderer.NAME;
			if(!rendererDict[no])
				rendererDict[no] = new ARRenderer(this);
			Renderer(rendererDict[no]).render(context3D, context3DProperty);
		}
		
		protected function renderDS(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			var no:String = "diffuseandspecular" + Jehovah.currentLight.name;
			if(!rendererDict[no])
			{
				if(Jehovah.currentLight is FreeLight3D)
					rendererDict[no] = new DSRendererFreeLight(this, FreeLight3D(Jehovah.currentLight));
			}
			Renderer(rendererDict[no]).render(context3D, context3DProperty);
		}
		
		protected function renderUniqueColor(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			var no:String = UniqueColorRenderer.NAME;
			if(!rendererDict[no])
				rendererDict[no] = new UniqueColorRenderer(this);
			Renderer(rendererDict[no]).render(context3D, context3DProperty);
		}
		
		public function render(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			if(!_geometry || !_mtl)
				return ;
			if(!_geometry.isUploaded)
				return ;
			
			if(Jehovah.renderMode == Jehovah.RENDER_ALL)
				renderAll(context3D, context3DProperty);
			else if(Jehovah.renderMode == Jehovah.RENDER_DEPTH)
				renderDepth(context3D, context3DProperty);
			else if(Jehovah.renderMode == Jehovah.RENDER_NORMAL)
				renderNormal(context3D, context3DProperty);
			else if(Jehovah.renderMode == Jehovah.RENDER_AMBIENTANDREFLECTION)
				renderAF(context3D, context3DProperty);
			else if(Jehovah.renderMode == Jehovah.RENDER_DIFFUSEANDSEPCULAR)
				renderDS(context3D, context3DProperty);
			else if(Jehovah.renderMode == Jehovah.RENDER_UNIQUE_COLOR)
				renderUniqueColor(context3D, context3DProperty);
		}
		
		/**
		 * re-upload mesh's resource to GPU. 
		 * @param context3D
		 * 
		 */		
		override public function uploadResource(context3D:Context3D):void
		{
			if(_geometry)
				_geometry.upload(context3D);
			
			if (_mtl)
			{
				if(_mtl.diffuseMapResource)
					_mtl.diffuseMapResource.upload(context3D);
				if(_mtl.reflectionMapResource)
					_mtl.reflectionMapResource.upload(context3D);
				if(_mtl.specularMapResource)
					_mtl.specularMapResource.upload(context3D);
				if(_mtl.bumpMapResource)
					_mtl.bumpMapResource.upload(context3D);
				if(_mtl.opacityMapResource)
					_mtl.opacityMapResource.upload(context3D);
				if (_mtl is LightMtl && LightMtl(_mtl).lightMapResource)
					LightMtl(_mtl).lightMapResource.upload(context3D);
			}
			
			for (var key:String in rendererDict)
			{
				var renderer:Renderer = rendererDict[key] as Renderer;
				renderer.disposeShader();
			}
			
			super.uploadResource(context3D);
		}
		
		override public function collectRenderList(opaqueRenderList:Vector.<Object3D>, transparentRenderList:Vector.<Object3D>):void
		{
			if(!visible)
				return ;
			if(_geometry && _mtl)
			{
				if(_mtl.alpha < 1.0 || _mtl.useOpacityMapChannel || _mtl.destinationFactor != Context3DBlendFactor.ZERO || (_mtl.diffuseColor && _mtl.diffuseColor.fractionalAlpha < 1))
					transparentRenderList.push(this);
				else
					opaqueRenderList.push(this);
			}
			super.collectChildrenRenderList(opaqueRenderList, transparentRenderList);
		}
		
		override public function mousePick(ray:Ray, mousePoint:Point = null):void
		{
			if(!mouseEnabled || !visible)
				return ;
			var rayCopy:Ray = new Ray(globalToLocalMatrix.transformVector(ray.p0), globalToLocalMatrix.deltaTransformVector(ray.dir));
			var dist:Number;
			if(_doppergangerGeometry)
				dist = _doppergangerGeometry.calculateIntersectionDist(rayCopy);
			else
				dist = _geometry.calculateIntersectionDist(rayCopy);
			if(dist)
			{
				var position:Vector3D = localToGlobalMatrix.transformVector(new Vector3D(rayCopy.p0.x + rayCopy.dir.x * dist, rayCopy.p0.y + rayCopy.dir.y * dist, rayCopy.p0.z + rayCopy.dir.z * dist));
				MousePickManager.add(new MousePickData(this, dist, position));
			}
			
			mousePickChildren(ray);
		}
		
		override public function routeBlocked(ray:Ray):Boolean
		{
			if(!participateInCollisionDetection || !visible)
				return false;
			var rayCopy:Ray = new Ray(globalToLocalMatrix.transformVector(ray.p0), globalToLocalMatrix.deltaTransformVector(ray.dir));
			var dist:Number = _geometry.calculateIntersectionDist(rayCopy);
			if(dist && dist < ray.length + Jehovah.camera.zNear)
				return true;
			if(routeBlockedByChildren(ray))
				return true;
			return false;
		}
		override public function dispose():void
		{
			super.dispose();
			if(_geometry)
			{
				_geometry.dispose();
				_geometry = null;
			}
			if(_mtl)
			{
				if(!_mtl.materialInAssetsManager)
					_mtl.dispose();
				_mtl = null;
			}
			disposeShader();
		}
		override public function getNumTriangle():int
		{
			if(_geometry)
				return _geometry.numTriangle;
			return 0;
		}
		override public function set useMip(value:Boolean):void
		{
			if(_useMip != value)
				disposeShader();
			super.useMip = value;
		}
		
		public function get useClamp():Boolean
		{
			return _useClamp;
		}
		public function set useClamp(value:Boolean):void
		{
			if (_useClamp != value)
				disposeShader();
			_useClamp = value;
		}
		
		public function get geometry():GeometryResource
		{
			return _geometry;
		}
		public function set geometry(val:GeometryResource):void
		{
			if(_geometry != val)
				_geometry = val;
		}
		override public function get bounding():Bounding
		{
			var bb:Bounding = childrenBounding;
			var geobb:Bounding = _geometry.bounding;
			bb.minX = Math.min(bb.minX, geobb.minX);
			bb.minY = Math.min(bb.minY, geobb.minY);
			bb.minZ = Math.min(bb.minZ, geobb.minZ);
			bb.maxX = Math.max(bb.maxX, geobb.maxX);
			bb.maxY = Math.max(bb.maxY, geobb.maxY);
			bb.maxZ = Math.max(bb.maxZ, geobb.maxZ);
			bb.calculateDimension();
			return bb;
		}
		
		public function get mtl():DiffuseMtl
		{
			return _mtl;
		}
		public function set mtl(value:DiffuseMtl):void
		{
			_mtl = value;
			disposeShader();
		}
		
		public function disposeShader():void
		{
			for (var key:* in rendererDict)
			{
				rendererDict[key].dispose();
				delete rendererDict[key];
			}
		}
		
		override public function toString():String
		{
			return "[Mesh:" + name + "]";
		}
	}
}