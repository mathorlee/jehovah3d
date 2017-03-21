package flashas3.flvplay
{   
	/**
	 * 电视位置 
	 */	
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.text.TextField;
	
	import panorama.geometry.Triangle;
	import panorama.geometry.Vertex;

	public class TvPosition
	{
		/**
		 * 电视四个点point 
		 */		
		private var _tvPoints:Vector.<Point>;
		/**
		 * 电视方位 
		 */		
		private var position:String;
		/**
		 * 画电视三角形 
		 */		
		private var _tvInputTriangles:Vector.<Triangle>;
		private var tv3D0:Vector3D = new Vector3D();
		private var tv3D1:Vector3D = new Vector3D();
		private var tv3D2:Vector3D = new Vector3D();
		private var tv3D3:Vector3D = new Vector3D();
		
		public function TvPosition(tvPoints:Vector.<Point>)
		{
			this._tvPoints = tvPoints;
			this._tvInputTriangles = new Vector.<Triangle>();
			calculateTvPosition();		
		}
		
		//电视三角形
		private function initTVScene():void
		{
			var u0:Number = 0;
			var u1:Number = 1;
			var v0:Number = 0;
			var v1:Number = 1;

			this._tvInputTriangles.push(new Triangle(
				new Vertex(tv3D0,new Point(u1,v0)),
				new Vertex(tv3D1,new Point(u0,v0)),
				new Vertex(tv3D2,new Point(u0,v1))
			));
			
			this._tvInputTriangles.push(new Triangle(
				new Vertex(tv3D0,new Point(u1,v0)),
				new Vertex(tv3D2,new Point(u0,v1)),
				new Vertex(tv3D3,new Point(u1,v1))
			));
		}
		
		//电视3D位置
		private function calculateTvPosition():void
		{
			/*
			三维球体的半径为r,水平转动角度为h（[-PI，PI]），上下转动角度为p（[-PI/2，PI/2]）
			所以球面上一点的三维坐标sphere(x,y,z)=(r*cosp*cosh,r*cosp*sinh,r*sinp)
			反向变换有p=arcsin(z/r) ，h=arctan(y/x)
			当把p对应到纹理的V方向，把H对应到纹理的U方向，UV的范围都是[0,1]
			在知道球面坐标x、y，z和半径r以后，球面点对应的纹理坐标就是
			V=arcsin(z/r)/PI+0.5，U=arctan(y/x)/2/PI
			*/
			var width:Number = 6000;
			var height:Number = 3000;
			var R:int = 100;
			//经度
			var longitude:Number;
			//纬度
			var latitude:Number;
			var PI:Number = Math.PI;
			var zeroLongitudePercent:Number = 0.25;
			
			var i:int;
			for(i = 0;i<this._tvPoints.length;i++)
			{
				if (_tvPoints[i].x < width * zeroLongitudePercent)
					longitude = (zeroLongitudePercent * width - _tvPoints[i].x) / width * PI * 2;
				else
					longitude = (width - _tvPoints[i].x) / width * PI * 2 + zeroLongitudePercent * PI * 2;
				
				latitude = (height * 0.5 - this._tvPoints[i].y) / (height / 2) * (PI / 2);
						
				this["tv3D"+i].x = R * Math.cos(latitude) * Math.cos(longitude);
				this["tv3D"+i].z = R * Math.cos(latitude) * Math.sin(longitude);
				this["tv3D"+i].y = -R * Math.sin(latitude);
			}

			initTVScene();
		}
		
		public function get tvInputTriangles():Vector.<Triangle>
		{
			return this._tvInputTriangles;
		}
	}
}