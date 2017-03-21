package jehovah3d.core
{
	import flash.geom.Vector3D;

	public class Bounding
	{
		public var minX:Number = Number.MAX_VALUE;
		public var maxX:Number = -Number.MAX_VALUE;
		public var minY:Number = Number.MAX_VALUE;
		public var maxY:Number = -Number.MAX_VALUE;
		public var minZ:Number = Number.MAX_VALUE;
		public var maxZ:Number = -Number.MAX_VALUE;
		
		public var radius:Number = 0;
		public var width:Number = 0;
		public var length:Number = 0;
		public var height:Number = 0;
		
		public function Bounding()
		{
			
		}
		
		public function calculateDimension():void
		{
			width = maxX - minX;
			length = maxY - minY;
			height = maxZ - minZ;
			radius = Math.sqrt(width * width + length * length + height * height) * 0.5;
		}
		public function get eightPoint():Vector.<Vector3D>
		{
			var ret:Vector.<Vector3D> = new Vector.<Vector3D>();
			ret.push(
				new Vector3D(maxX, maxY, minZ), 
				new Vector3D(minX, maxY, minZ), 
				new Vector3D(minX, minY, minZ), 
				new Vector3D(maxX, minY, minZ), 
				
				new Vector3D(maxX, maxY, maxZ), 
				new Vector3D(minX, maxY, maxZ), 
				new Vector3D(minX, minY, maxZ), 
				new Vector3D(maxX, minY, maxZ)
			);
			return ret;
		}
		
		public function get selectWFPoints():Vector.<Vector3D>
		{
			var points:Vector.<Vector3D> = new Vector.<Vector3D>();
			points.push(
				new Vector3D(maxX, maxY, minZ), 
				new Vector3D(minX, maxY, minZ), 
				new Vector3D(minX, maxY, minZ), 
				new Vector3D(minX, minY, minZ), 
				new Vector3D(minX, minY, minZ), 
				new Vector3D(maxX, minY, minZ), 
				new Vector3D(maxX, minY, minZ), 
				new Vector3D(maxX, maxY, minZ), 
				
				new Vector3D(maxX, maxY, maxZ), 
				new Vector3D(minX, maxY, maxZ), 
				new Vector3D(minX, maxY, maxZ), 
				new Vector3D(minX, minY, maxZ), 
				new Vector3D(minX, minY, maxZ), 
				new Vector3D(maxX, minY, maxZ), 
				new Vector3D(maxX, minY, maxZ), 
				new Vector3D(maxX, maxY, maxZ), 
				
				new Vector3D(maxX, maxY, minZ), 
				new Vector3D(maxX, maxY, maxZ), 
				new Vector3D(minX, maxY, minZ), 
				new Vector3D(minX, maxY, maxZ), 
				new Vector3D(minX, minY, minZ), 
				new Vector3D(minX, minY, maxZ), 
				new Vector3D(maxX, minY, minZ), 
				new Vector3D(maxX, minY, maxZ)
			);
			return points;
		}
		
		public function get centerPoint():Vector3D
		{
			return new Vector3D((minX + maxX) * 0.5, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5);
		}
		
		public function toString():String
		{
			var ret:String = "Bounding\n";
			ret += String(minX) + ", " + String(maxX) + "\n";
			ret += String(minY) + ", " + String(maxY) + "\n";
			ret += String(minZ) + ", " + String(maxZ) + "\n";
			ret += String(width) + ", " + String(length) + ", " + String(height) + ", " + String(radius) + "\n";
			return ret;
		}
	}
}