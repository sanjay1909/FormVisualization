package ehs.services
{
	public class LabSafetyServer
	{
		
		
		public static var isAuthorized:Boolean ;
		public static var currentUser:String;
		public static var busy:Boolean;
		
		
		public static function saveToDrive():void{
			if(isAuthorized){
				JavaScript.exec('this.GoogleDrive.updateWeaveFile()');
			}
		}
	}
}