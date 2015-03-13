package com.asanjay.pod.events
{
	
	import flash.events.Event;

	public class PodEvent extends Event
	{
		public static const MINIMIZE:String = "minimize";
		public static const MAXIMIZE:String = "maximize";
		public static const CLOSE:String = "close";
		public static const NORMAL:String = "normal";
		public static const RESTORE:String = "restore";
		public static const CHANGE:String = "change";
		
		public var data:Object;
		
		
		public function PodEvent(type:String, data:Object=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.data = data;
		}
		
		
		override public function clone():Event
		{
			return new PodEvent(type, bubbles, cancelable, data);
		}
	}
}