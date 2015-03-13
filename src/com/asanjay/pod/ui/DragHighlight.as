package com.asanjay.pod.ui
{
	import spark.components.BorderContainer;
	
	public class DragHighlight extends BorderContainer
	{
		public function DragHighlight()
		{
			super();
			this.setStyle("borderColor",0xCCCCCC);
			this.setStyle("borderWeight",3);
			this.setStyle("borderStyle","solid");
		}
	}
}