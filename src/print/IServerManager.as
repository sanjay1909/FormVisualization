package print
{
	import ehs.data.InspectionData;

	public interface IServerManager
	{
		function addFilledDataToSection(insdata:InspectionData):void;
		function removeFilledDataToSection(insdata:InspectionData):void;
		
		function addSectionToComment(sectionName:String , sectionObj:Object):void;
		function removeSectionToComment(sectionName:String):void;
	}
}