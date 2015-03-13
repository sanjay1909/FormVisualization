package ehs
{
	import spark.components.Group;
	
	import weave.api.newLinkableChild;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableHashMap;
	
	public class Form extends Group implements ILinkableObject
	{
		public function Form()
		{
			super();
		}
		
		//public const children:LinkableHashMap = newLinkableChild(this, LinkableHashMap);
		//private var checklistGroup
		
		override protected function createChildren():void
		{
			super.createChildren();
		}

	}
}