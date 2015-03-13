package ehs.ui
{
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableVariable;
	
	public interface IInspectionUI extends ILinkableObject
	{
		function get data():LinkableVariable;
		
	}
}