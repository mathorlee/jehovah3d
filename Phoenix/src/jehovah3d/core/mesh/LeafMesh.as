package jehovah3d.core.mesh
{
	import flash.display3D.Context3D;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.Context3DProperty;
	import jehovah3d.core.renderer.LeafRenderer;
	import jehovah3d.core.renderer.Renderer;
	
	/**
	 * 树叶Mesh。杀死透明像素
	 * @author lisongsong
	 * 
	 */	
	public class LeafMesh extends Mesh
	{
		override public function render(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			if(!_geometry || !_mtl)
				return ;
			if(!_geometry.isUploaded)
				return ;
			
			if(Jehovah.renderMode == Jehovah.RENDER_ALL || Jehovah.renderMode == Jehovah.RENDER_AMBIENTANDREFLECTION)
				renderOpaquePixels(context3D, context3DProperty);
		}
		
		private function renderOpaquePixels(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			var no:String = LeafRenderer.NAME;
			if(!rendererDict[no])
				rendererDict[no] = new LeafRenderer(this);
			Renderer(rendererDict[no]).render(context3D, context3DProperty);
		}
	}
}