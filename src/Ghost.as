package{
	
	import flash.display.*;
	import flash.geom.*;
	import flash.events.*;
	
	public class Ghost extends Player{
		
		public static const RANDOM:int=0;
		public static const ATTACK:int=1;
		public static const DEAD:int=-1;
		
		private static const MODE_DURATION:int=8000;
		
		private var dirInd:int;
		
		private var id:int;
		private var mode:int;
		private var oldmode:int;
		
		private var direction_timeout:int;
		private var timeout:int;
		private var trajectory:Array;
		
		
		public function Ghost(sPos:Point,m:Map,Id:int)
		{
			super(sPos,m);
			NormalSpeed=2.25;
			id=Id;
			timeout=MODE_DURATION;
		}
		
		public function getMode():int
		{
			return mode;
		}
		
		override public function reset():void
		{
			super.reset();
			
			trajectory=null;
			direction_timeout=0;
			
			if(mode == DEAD){
				mode=oldmode;
				gotoAndStop(1);
			}
			else
				mode=ATTACK;
		}
		
		override public function setDirection(d:Point):void{
			if(Math.abs(d.x+d.y) != 1){
				trace("id",this.id);
				trace("mode",this.mode);
				trace("trajectory",this.trajectory);
				trace("pos",pos,d,dir);
				speed=0;
				return;
			}
			
			var nextPos:Point= pos.add(d);
	
			if(map.isWall(nextPos.x,nextPos.y)){
				if(dir.toString() == d.toString()) 
					speed=getMaxSpeed();
				 
				speed=Math.min(Math.abs(carry),speed);
				if( carry > 0)
					speed=-carry;
				return;
			}
			
			speed=getMaxSpeed();
			
			if(dir.x*d.x+dir.y*d.y == 0){
				if(speed < Math.abs(carry)){
					return;
				}
				
				setPosition(map.toWorldCoord(pos));
				speed-=Math.abs(carry);
			}
			
			dir=d;
			
		}
		
		public function die():void
		{
			oldmode = mode;
			mode = DEAD;
			gotoAndStop(2);
			
			trajectory = map.findPath(pos, startPos);
		}
	
		private function goHome():void
		{
			if (!trajectory.length){
				reset();
				return;
			}
			var dnext:Point;
			var next:Point=trajectory[0];
			
			if(next.toString() == pos.toString() ){
				if(carry >= 0){
					trajectory.shift();
					if(!trajectory.length ){
						reset();
						return;
					}
					
					next=trajectory[0];
				}
				else
					next=pos.add(dir);
			}
			
			dnext=next.subtract(pos);
			if(dnext.x*dir.x +dnext.y*dir.y == 0 && carry > getMaxSpeed()){
				dnext.x=-dir.x;
				dnext.y=-dir.y;
			}
			
			setDirection(dnext);
			traverse();
		}
		
		public function update(ms:int =0, run:Boolean =false):void
		{
			if(mode == DEAD){
				goHome();
				return;
			}
	
			if(run){
				trajectory=null;
				random(ms);
				return;
			}

			if (mode == ATTACK){
				attack(ms);
			}
			else
				if (mode == RANDOM)
					random(ms);
			
			if ((timeout -= ms) <= 0){
				timeout = MODE_DURATION - (Math.floor(Math.random() * 2000));
				if(mode == RANDOM){
					mode = ATTACK;
				}
				else{
					trajectory=null;
					mode = RANDOM ;
				}
			}
			
		}
		
		private function attack(ms:int =0):void
		{
			if(!trajectory){
				var par:Object=parent;
				var target:Point=par.getPacPos();
				trajectory=map.findPath(pos,target);
				return;
			}
			
			if (!trajectory.length){
				trajectory=null;
				random(ms);
				return;
			}
			var dnext:Point;
			var next:Point=trajectory[0];
			
			if(next.toString() == pos.toString() ){
				if(carry >= 0){
					trajectory.shift();
					if(!trajectory.length ){
						trajectory=null;
						if(Math.random() < 0.5){
							attack(ms);
						}
						else {
							random(ms);
						}
						return;
					}
					
					next=trajectory[0];
				}
				else
					next=pos.add(dir);
			}
			
			dnext=next.subtract(pos);
			if(dnext.x*dir.x +dnext.y*dir.y == 0 && carry > getMaxSpeed()){
				dnext.x=-dir.x;
				dnext.y=-dir.y;
			}
			
			setDirection(dnext);
			traverse();
		}
		
		private function random(ms:int =0):void
		{
			var next:Point=pos.add(dir);
			var stuck:Boolean=map.isWall(next.x,next.y);
			
			var dnext:Point=getDirection();
			
			if((stuck && carry >= 0) || direction_timeout-ms <=0){
				if( carry <= NormalSpeed ){
					if(Math.random() < 0.5){
						dnext.x=-dir.y;
						dnext.y=dir.x;
					}else{
						dnext.x=dir.y;
						dnext.y=-dir.x;
					}
					
					next=pos.add(dnext);
					if(map.isWall(next.x,next.y)   ){
						dnext.x=-dnext.x;
						dnext.y=-dnext.y;
					}
					next=pos.add(dnext);
					if(map.isWall(next.x,next.y)   ){
						dnext=getDirection();
						direction_timeout=500 + Math.floor(Math.random()*2000);
					}
					else{
						if(Math.abs(carry) <= NormalSpeed)
							direction_timeout=500 + Math.floor(Math.random()*2000);
						else
							direction_timeout=ms;
					}
				}
				else
					direction_timeout=500 + Math.floor(Math.random()*2000);
					
				next=pos.add(dnext);
				if(map.isWall(next.x,next.y) ){
					dnext.x=-dnext.x;
					dnext.y=-dnext.y;
				}
				
			}
			
			setDirection(dnext);
			direction_timeout-=ms;
			
			traverse();
		}
		
	}
	
}
