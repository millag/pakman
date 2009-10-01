package{
	
	
	import flash.display.*;
	import flash.geom.*;
	
	
	public class Player extends MovieClip{
		public static const Up:Point = new Point(0,-1);
		public static const Down:Point = new Point(0,1);
		public static const Left:Point = new Point(-1,0);
		public static const Right:Point = new Point(1,0);
		
		protected static const DECELERATION:Number=0.25;
		protected var NormalSpeed:Number;
		
		
		// coords of the starting cell
		protected var startPos:Point;
		// coords of the curr cell
		protected var pos:Point;
		//offset to the center of the current cell we are in 
		protected var carry:Number;
		//
		protected var map:Map;
		//in units per frame
		protected var speed:Number;
		protected var dir:Point;
		
		
		public function Player(sPos:Point,m:Map){
			if(!sPos) 
				startPos=new Point();
			else 
				startPos=sPos;
			
			map=m;
			reset();
			
		}
		
		public function reset():void
		{
			pos=startPos.clone();
			speed=0;
			carry=0;
			dir=Left;
			setPosition(map.toWorldCoord(pos));
		}
		
		public function getPos():Point
		{
			return pos.clone();
		}
		
		public function getDirection():Point
		{
			return dir.clone();
		}
		
		public function setDirection(d:Point):void
		{
			if(Math.abs(d.x + d.y) != 1){
				speed=0;
				return;
			}
			
			var nextPos:Point= pos.add(d);
				
			if(map.isWall(nextPos.x,nextPos.y)){
				if(dir.toString() == d.toString()) 
					speed=getMaxSpeed();
				
				speed=Math.min(Math.abs(carry),speed);
				
				return;
			}
			
			speed=getMaxSpeed();
			
			if(dir.x*d.x+dir.y*d.y == 0){
				if(speed < Math.abs(carry))
					return ;
				
				setPosition(map.toWorldCoord(pos));
				speed-=Math.abs(carry);
			}
			
			dir=d;
		}
		
		protected function getMaxSpeed():Number
		{
			return  NormalSpeed;
		}
		
		protected function setPosition(p:Point):void
		{
			x=p.x;
			y=p.y;
		}
		
		protected function decelerate():void
		{
			if(speed <= 0 ||( map.isWall(pos.x+dir.x,pos.y+dir.y) && carry >= 0 )) 
				speed=0;
			else
				speed-=DECELERATION;
		}
		
		protected function traverse():void
		{
			var cellCenter:Point=map.toWorldCoord(pos);
			var nextPos:Point=new Point();
			nextPos.x=x + dir.x*speed;
			nextPos.y=y + dir.y*speed;
			
			var p:Point=map.toMapCoord(nextPos);
			
			if(!p){
				carry=0;
				speed=0;
				setPosition(cellCenter);
				return;
			}
			
			cellCenter=map.toWorldCoord(p);
			if(pos.toString()!=p.toString() && pos.add(dir).toString() != p.toString()){
				nextPos.x=cellCenter.x-dir.x*carry;
				nextPos.y=cellCenter.y-dir.y*carry;
			}
			pos=p;
			setPosition(nextPos);
			carry=dir.x*(nextPos.x-cellCenter.x)+dir.y*(nextPos.y-cellCenter.y);
			
			decelerate();
		}
		
	}
	
	
}