package jehovah3d.core.pick
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	/**
	 * 矩形面。 
	 * @author lisongsong
	 * 
	 */
	public class RectFace
	{
		public var p0:Vector3D;
		public var p1:Vector3D;
		public var p2:Vector3D;
		
		/**
		 * ABC，p0-B, p1-A, p2-C。注意顺序。 
		 * @param p0
		 * @param p1
		 * @param p2
		 * 
		 */		
		public function RectFace(p0:Vector3D, p1:Vector3D, p2:Vector3D) //I feel bad right now.
		{
			this.p0 = p0;
			this.p1 = p1;
			this.p2 = p2;
		}
		
		public function transform(matrix:Matrix3D):RectFace
		{
			return new RectFace(matrix.transformVector(p0), matrix.transformVector(p1), matrix.transformVector(p2));
		}
	}
}