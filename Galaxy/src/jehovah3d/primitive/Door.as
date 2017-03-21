package jehovah3d.primitive
{
	import flash.geom.Vector3D;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.Object3D;
	import jehovah3d.core.material.DiffuseMtl;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.GeometryResource;
	import jehovah3d.util.HexColor;
	
	public class Door extends Object3D
	{
		//1. 内嵌式门，门+门框=门洞。
		//2. 包裹式门。
		private var _frameWidth:Number;
		private var _frameLength:Number;
		private var _frameHeight:Number;
		private var _frameThickness:Number;
		private var _leafWidth:Number;
		private var _leafLength:Number;
		private var _leafHeight:Number;
		private var _leafThickness:Number;
		
		private var _flipHinge:Boolean;
		private var _frame:Mesh;
		private var _leaf:Mesh;
		
		public function Door(frameWidth:Number, frameLength:Number, frameHeight:Number, frameThickness:Number, leafWidth:Number, leafLength:Number, leafHeight:Number, leafThickness:Number, flipHinge:Boolean)
		{
			_frameWidth = frameWidth;
			_frameLength = frameLength;
			_frameHeight = frameHeight;
			_leafWidth = leafWidth;
			_frameThickness = frameThickness;
			_leafLength = leafLength;
			_leafHeight = leafHeight;
			_leafThickness = leafThickness;
			_flipHinge = flipHinge;
			addFrame();
			addLeaf();
		}
		private function addLeaf():void
		{
			var i:int;
			var points1:Vector.<Vector3D> = new Vector.<Vector3D>();
			points1.push(new Vector3D(0, 0, 0));
			points1.push(new Vector3D(-_leafWidth, 0, 0));
			points1.push(new Vector3D(-_leafWidth, -_leafLength, 0));
			points1.push(new Vector3D(0, -_leafLength, 0));
			points1.push(new Vector3D(0, 0, _leafHeight));
			points1.push(new Vector3D(-_leafWidth, 0, _leafHeight));
			points1.push(new Vector3D(-_leafWidth, -_leafLength, _leafHeight));
			points1.push(new Vector3D(0, -_leafLength, _leafHeight));
			
			_leaf = new Mesh();
			_leaf.geometry = new GeometryResource();
			var coordinateData:Vector.<Number> = new Vector.<Number>();
			var indexData:Vector.<uint> = new Vector.<uint>();
			var lists:Vector.<uint> = Vector.<uint>([1, 0, 3, 2, 4, 5, 6, 7, 4, 7, 3, 0, 6, 5, 1, 2, 7, 6, 2, 3, 5, 4, 0, 1]);
			for(i = 0; i < lists.length; i ++)
				coordinateData.push(points1[lists[i]].x, points1[lists[i]].y, points1[lists[i]].z);
			for(i = 0; i < lists.length / 4; i ++)
				indexData.push(0 + 4 * i, 1 + 4 * i, 2 + 4 * i, 0 + 4 * i, 2 + 4 * i, 3 + 4 * i);
			_leaf.geometry.coordinateData = coordinateData;
			_leaf.geometry.indexData = indexData;
			_leaf.geometry.calculateNormal();
			_leaf.geometry.upload(Jehovah.context3D);
			
			
			var mtl:DiffuseMtl = new DiffuseMtl();
			mtl.diffuseColor = new HexColor(0xEEEEEE, 1);
			_leaf.mtl = mtl;
			addChild(_leaf);
			_leaf.x = _leafWidth * 0.5;
			_leaf.y = _leafLength * 0.5;
			_leaf.z = 0;
			_leaf.name = "leaf";
		}
		private function addFrame():void
		{
			var i:int;
			var frameP1:Vector.<Vector3D> = new Vector.<Vector3D>();
			frameP1.push(new Vector3D(_frameWidth * 0.5, _frameLength * 0.5, 0));
			frameP1.push(new Vector3D(-_frameWidth * 0.5, _frameLength * 0.5, 0));
			frameP1.push(new Vector3D(-_frameWidth * 0.5, -_frameLength * 0.5, 0));
			frameP1.push(new Vector3D(_frameWidth * 0.5, -_frameLength * 0.5, 0));
			frameP1.push(new Vector3D(_frameWidth * 0.5, _frameLength * 0.5, _frameHeight));
			frameP1.push(new Vector3D(-_frameWidth * 0.5, _frameLength * 0.5, _frameHeight));
			frameP1.push(new Vector3D(-_frameWidth * 0.5, -_frameLength * 0.5, _frameHeight));
			frameP1.push(new Vector3D(_frameWidth * 0.5, -_frameLength * 0.5, _frameHeight));
			var frameP2:Vector.<Vector3D> = new Vector.<Vector3D>();
			frameP2.push(new Vector3D((_frameWidth * 0.5 - _frameThickness), _frameLength * 0.5, 0));
			frameP2.push(new Vector3D(-(_frameWidth * 0.5 - _frameThickness), _frameLength * 0.5, 0));
			frameP2.push(new Vector3D(-(_frameWidth * 0.5 - _frameThickness), -_frameLength * 0.5, 0));
			frameP2.push(new Vector3D((_frameWidth * 0.5 - _frameThickness), -_frameLength * 0.5, 0));
			frameP2.push(new Vector3D((_frameWidth * 0.5 - _frameThickness), _frameLength * 0.5, _frameHeight - _frameThickness));
			frameP2.push(new Vector3D(-(_frameWidth * 0.5 - _frameThickness), _frameLength * 0.5, _frameHeight - _frameThickness));
			frameP2.push(new Vector3D(-(_frameWidth * 0.5 - _frameThickness), -_frameLength * 0.5, _frameHeight - _frameThickness));
			frameP2.push(new Vector3D((_frameWidth * 0.5 - _frameThickness), -_frameLength * 0.5, _frameHeight - _frameThickness));
			
			_frame = new Mesh();
			_frame.geometry = new GeometryResource();
			var coordinateData:Vector.<Number> = new Vector.<Number>();
			var indexData:Vector.<uint> = new Vector.<uint>();
			//out_top
			coordinateData.push(frameP1[4].x, frameP1[4].y, frameP1[4].z);
			coordinateData.push(frameP1[5].x, frameP1[5].y, frameP1[5].z);
			coordinateData.push(frameP1[6].x, frameP1[6].y, frameP1[6].z);
			coordinateData.push(frameP1[7].x, frameP1[7].y, frameP1[7].z);
			//out_right
			coordinateData.push(frameP1[4].x, frameP1[4].y, frameP1[4].z);
			coordinateData.push(frameP1[7].x, frameP1[7].y, frameP1[7].z);
			coordinateData.push(frameP1[3].x, frameP1[3].y, frameP1[3].z);
			coordinateData.push(frameP1[0].x, frameP1[0].y, frameP1[0].z);
			//out_left
			coordinateData.push(frameP1[6].x, frameP1[6].y, frameP1[6].z);
			coordinateData.push(frameP1[5].x, frameP1[5].y, frameP1[5].z);
			coordinateData.push(frameP1[1].x, frameP1[1].y, frameP1[1].z);
			coordinateData.push(frameP1[2].x, frameP1[2].y, frameP1[2].z);
			//front
			coordinateData.push(frameP1[7].x, frameP1[7].y, frameP1[7].z);
			coordinateData.push(frameP1[6].x, frameP1[6].y, frameP1[6].z);
			coordinateData.push(frameP1[6].x, frameP1[6].y, frameP1[6].z - _frameThickness);
			coordinateData.push(frameP1[7].x, frameP1[7].y, frameP1[7].z - _frameThickness);
			
			coordinateData.push(frameP2[6].x, frameP2[6].y, frameP2[6].z);
			coordinateData.push(frameP1[6].x, frameP1[6].y, frameP1[6].z - _frameThickness);
			coordinateData.push(frameP1[2].x, frameP1[2].y, frameP1[2].z);
			coordinateData.push(frameP2[2].x, frameP2[2].y, frameP2[2].z);
			
			coordinateData.push(frameP1[7].x, frameP1[7].y, frameP1[7].z - _frameThickness);
			coordinateData.push(frameP2[7].x, frameP2[7].y, frameP2[7].z);
			coordinateData.push(frameP2[3].x, frameP2[3].y, frameP2[3].z);
			coordinateData.push(frameP1[3].x, frameP1[3].y, frameP1[3].z);
			//back
			coordinateData.push(frameP1[5].x, frameP1[5].y, frameP1[5].z);
			coordinateData.push(frameP1[4].x, frameP1[4].y, frameP1[4].z);
			coordinateData.push(frameP1[4].x, frameP1[4].y, frameP1[4].z - _frameThickness);
			coordinateData.push(frameP1[5].x, frameP1[5].y, frameP1[5].z - _frameThickness);
			
			coordinateData.push(frameP2[4].x, frameP2[4].y, frameP2[4].z);
			coordinateData.push(frameP1[4].x, frameP1[4].y, frameP1[4].z - _frameThickness);
			coordinateData.push(frameP1[0].x, frameP1[0].y, frameP1[0].z);
			coordinateData.push(frameP2[0].x, frameP2[0].y, frameP2[0].z);
			
			coordinateData.push(frameP1[5].x, frameP1[5].y, frameP1[5].z - _frameThickness);
			coordinateData.push(frameP2[5].x, frameP2[5].y, frameP2[5].z);
			coordinateData.push(frameP2[1].x, frameP2[1].y, frameP2[1].z);
			coordinateData.push(frameP1[1].x, frameP1[1].y, frameP1[1].z);
			
			//in_top
			coordinateData.push(frameP2[5].x, frameP2[5].y, frameP2[5].z);
			coordinateData.push(frameP2[4].x, frameP2[4].y, frameP2[4].z);
			coordinateData.push(frameP2[7].x, frameP2[7].y, frameP2[7].z);
			coordinateData.push(frameP2[6].x, frameP2[6].y, frameP2[6].z);
			//in_right
			coordinateData.push(frameP2[7].x, frameP2[7].y, frameP2[7].z);
			coordinateData.push(frameP2[4].x, frameP2[4].y, frameP2[4].z);
			coordinateData.push(frameP2[0].x, frameP2[0].y, frameP2[0].z);
			coordinateData.push(frameP2[3].x, frameP2[3].y, frameP2[3].z);
			//in_left
			coordinateData.push(frameP2[5].x, frameP2[5].y, frameP2[5].z);
			coordinateData.push(frameP2[6].x, frameP2[6].y, frameP2[6].z);
			coordinateData.push(frameP2[2].x, frameP2[2].y, frameP2[2].z);
			coordinateData.push(frameP2[1].x, frameP2[1].y, frameP2[1].z);
			
			for(i = 0; i < coordinateData.length / 12; i ++)
				indexData.push(0 + 4 * i, 1 + 4 * i, 2 + 4 * i, 0 + 4 * i, 2 + 4 * i, 3 + 4 * i);
			_frame.geometry.coordinateData = coordinateData;
			_frame.geometry.indexData = indexData;
			_frame.geometry.calculateNormal();
			_frame.geometry.upload(Jehovah.context3D);
			var mtl:DiffuseMtl = new DiffuseMtl();
			mtl.diffuseColor = new HexColor(0xEEEEEE, 1);
			_frame.mtl = mtl;
			addChild(_frame);
		}
	}
}