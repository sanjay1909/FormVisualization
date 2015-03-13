package ehs.ui
{
	import spark.components.SkinnableContainer;
	
	import ehs.ui.skins.EHSPanelSkin;

	public class CustomPanel extends SkinnableContainer
	{
		public function CustomPanel()
		{
			super();
			setStyle("skinClass",Class(EHSPanelSkin));
		}
		
		[Bindable]
		public var title:String = "";
		
		[Bindable]
		public var status:String = "";
		
		
	}
}