package ehs.ui.editors
{
	import ehs.ui.InspectionDataUI;
	
	import weave.api.core.ILinkableObject;

	public interface ITextEditor extends ILinkableObject
	{
		function pinLinkableDataUI(dataUI:InspectionDataUI):void;
	}
}