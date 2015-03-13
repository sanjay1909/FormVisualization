package ehs.services.beans
{
	[RemoteClass(alias="ServiceLibrary.LabSafetyRecord")]
	public class LabSafetyRecord
	{
		
		public var filePath:String;
		public var fileID:String;
		
		public var building:String;
		public var roomNumber:String;
		public var pi:String;
		public var inspector:String;
		public var cho:String;
		public var choMailId:String;
		public var department:String;
		public var primaryFunction:String;
		public var inspectionDate:Date;
		
		public var dueDate:Date;
		public var status:String;
	}
}