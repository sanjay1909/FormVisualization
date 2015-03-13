package ehs
{
	public class EHSUtils
	{
		public function EHSUtils()
		{
		}
		
		public static function formatDate(date:Date):String
		{
			var days:Array = new Array("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday");
			var months:Array = new Array("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December");
			var currentDay:String = days[date.getDay()];
			var currentMonth:String = months[date.getMonth()];
			var currentYear:String = String(date.getFullYear());
			var currentDate:String = String(date.getDate());
			var output:String =   currentMonth+ " "+ currentDate + ", " + currentYear;
			
			return output;
		}
		
		
	}
}