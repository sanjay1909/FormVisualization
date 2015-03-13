package print
{
	import weave.api.registerLinkableChild;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableNumber;
	
	public class ContentSettings implements ILinkableObject
	{
		public function ContentSettings()
		{
		}
		
		
			
		public const height:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		public const width:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		
	}
}