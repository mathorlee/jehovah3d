package flashas3.flvplay
{   
	/**
	 * 电视位置 
	 */	
	import flash.geom.Point;
	import flash.geom.Vector3D;
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
			checkPosition();		
		}
		
		//电视方位
		private function checkPosition():void
		{
			if(_tvPoints[0].x>=2&&_tvPoints[0].x<=514&&_tvPoints[1].x<=514)
			{
				this.position = "left";
			}
			else if(_tvPoints[0].x>=1026&&_tvPoints[0].x<=1538&&_tvPoints[1].x>=1026)
			{
				this.position = "right";
			}
			else if(_tvPoints[0].x>=514&&_tvPoints[0].x<=1026)
			{
				if(_tvPoints[0].y>=0&&_tvPoints[0].y<=512&&_tvPoints[2].y<=512)
				{
					this.position = "top";
				}
				else if(_tvPoints[0].y>=512&&_tvPoints[0].y<=1024&&_tvPoints[2].y<=1024)
				{
					this.position = "front";
				}
				else if(this._tvPoints[0].y>=1024&&this._tvPoints[0].y<=1536&&_tvPoints[2].y<=1536)
				{
					this.position = "bottom";
				}
				else if(this._tvPoints[0].y>=1536&&this._tvPoints[0].y<=2048&&_tvPoints[2].y>=1536)
				{
					this.position = "back";
				}
			}	
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
			var length:int = 512;
			var vecter3Dlength:int = length / 2;
			var i:int;

			switch(this.position)
			{
				case "back":
					for(i = 0;i<_tvPoints.length;i++)
					{
						this["tv3D"+i].x = (this._tvPoints[i].x-length-vecter3Dlength)*200/length;
						this["tv3D"+i].y = -(this._tvPoints[i].y-length*3-vecter3Dlength)*200/length;
						this["tv3D"+i].z = -100;
					}
					break;
				case "front":
					for(i = 0;i<_tvPoints.length;i++)
					{
						this["tv3D"+i].x = (this._tvPoints[i].x-length-vecter3Dlength)*200/length;
						this["tv3D"+i].y = (this._tvPoints[i].y-length-vecter3Dlength)*200/length;
						this["tv3D"+i].z = 100;	
					}
					break;
				case "left":
					for(i = 0;i<_tvPoints.length;i++)
					{
						this["tv3D"+i].z = (this._tvPoints[i].x-vecter3Dlength)*200/length;
						this["tv3D"+i].y = (this._tvPoints[i].y-length-vecter3Dlength)*200/length;
						this["tv3D"+i].x = -100;		
					}
					break;
				case "right":
					for(i = 0;i<_tvPoints.length;i++)
					{
						this["tv3D"+i].z = -(this._tvPoints[i].x-length*2-vecter3Dlength)*200/length;
						this["tv3D"+i].y = (this._tvPoints[i].y-length-vecter3Dlength)*200/length;
						this["tv3D"+i].x = 100;		
					}
					break;
				case "top":		
					for(i = 0;i<_tvPoints.length;i++)
					{
						this["tv3D"+i].x = (this._tvPoints[i].x-length-vecter3Dlength)*200/length;
						this["tv3D"+i].z = (this._tvPoints[i].y-vecter3Dlength)*200/length;
						this["tv3D"+i].y = -100;		
					}
					break;
				case "bottom":
					for(i = 0;i<_tvPoints.length;i++)
					{
						this["tv3D"+i].x = (this._tvPoints[i].x-length-vecter3Dlength)*200/length;
						this["tv3D"+i].z = -(this._tvPoints[i].y-length*2-vecter3Dlength)*200/length;
						this["tv3D"+i].y = 100;		
					}
					break;
			}
			initTVScene();
		}
		
		public function get tvInputTriangles():Vector.<Triangle>
		{
			return this._tvInputTriangles;
		}
	}
}