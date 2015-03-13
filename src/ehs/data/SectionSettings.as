package ehs.data
{
	import weave.api.registerLinkableChild;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableNumber;
	import weave.utils.LinkableTextFormat;
	
	public class SectionSettings implements ILinkableObject
	{
		public function SectionSettings()
		{
			headingTextFormat.size.value = 20;
			headingTextFormat.bold.value = true;
			headingTextFormat.font.value = "Arial";
			checklistTextFormat.size.value = 14;
			checklistTextFormat.font.value ="Arial"
			
		}
		
		public const backGroundColor:LinkableNumber =  registerLinkableChild(this,new LinkableNumber(0xffffff));
		
		public const checklistTextFormat:LinkableTextFormat = registerLinkableChild(this,new LinkableTextFormat());;
		public const headingTextFormat:LinkableTextFormat = registerLinkableChild(this,new LinkableTextFormat());;
		
	}
}