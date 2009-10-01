package{
	
	import flash.display.*;
	import flash.geom.*;
	
	public class Pacman extends Player{
		
		public static const NORMAL:int=0;
		public static const VITAMINIZED:int=1;
		
		private static const VitaminizedSpeed:Number=3;
		private static const Vitamin_timeout:Number=5000;
		
		private var vtimeout:Number;
		
		private var mode:int;
		
		
		public function Pacman(sPos:Point,m:Map)
		{
			super(sPos,m);
			NormalSpeed=2;
		}
		
		override public function reset():void
		{
			super.reset();
			
			mode=NORMAL;
			vtimeout=0;
			
			if(dir.x){
				this.scaleX=dir.x;
				this.rotation=0;
			}
			else
				this.rotation=scaleX*dir.y*90;
		}
		
		override public function setDirection(d:Point):void
		{
			super.setDirection(d);
			
			if(dir.x){
				this.scaleX=dir.x;
				this.rotation=0;
			}
			else
				this.rotation=scaleX*dir.y*90;
			
		}
		
		override protected function getMaxSpeed():Number
		{
			return (mode == NORMAL)? NormalSpeed:VitaminizedSpeed;
		}
		
		public function isVitaminized():Boolean
		{
			return (mode == VITAMINIZED);
		}
		
		public function update(ms:Number =0):void
		{
			traverse();
			
			if(mode == VITAMINIZED){
				vtimeout-=ms;
				if(vtimeout <= 0){
					mode=NORMAL;
					vtimeout=0;
				}
			}
			
			var eaten:String=map.eatDotAt(pos);
			if(eaten == map.VITAMIN){
				mode=VITAMINIZED;
				vtimeout+=Vitamin_timeout;
			}
		}
		
	}
	
}