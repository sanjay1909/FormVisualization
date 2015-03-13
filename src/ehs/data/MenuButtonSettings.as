package ehs.data
{
	import weave.api.registerLinkableChild;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableNumber;
	import weave.utils.LinkableTextFormat;
	
	public class MenuButtonSettings implements ILinkableObject
	{
		public function MenuButtonSettings()
		{
			menuTextFormat.color.value = 0xffffff;
			menuTextFormat.size.value = 14;
			menuTextFormat.font.value = "Arial";
		}
		
		
		public const menuButtonColor:LinkableNumber =  registerLinkableChild(this,new LinkableNumber(0x36373b));
		public const menuButtonSelectedStateColor:LinkableNumber =  registerLinkableChild(this,new LinkableNumber(0x202425));
		public const menuButtonOverStateColor:LinkableNumber =  registerLinkableChild(this,new LinkableNumber(0x202425));
		
		public const menuButtonAlpha:LinkableNumber = registerLinkableChild(this,new LinkableNumber(0.85));
		public const menuButtonAlphaOverAndSelected:LinkableNumber =  registerLinkableChild(this,new LinkableNumber(1));
		
		public const menuButtonFontSize:LinkableNumber =  registerLinkableChild(this,new LinkableNumber(14));
		public const menuButtonFontColor:LinkableNumber =  registerLinkableChild(this,new LinkableNumber(0xffffff));
		
		public const menuTextFormat:LinkableTextFormat = registerLinkableChild(this,new LinkableTextFormat());;
	}
}