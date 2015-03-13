package ehs.data
{
	import flash.utils.Dictionary;

	public class FormMetaData
	{
		public function FormMetaData()
		{
			
		}
		
		
		
		
		public var keyColumnID:String;
		public var sectionColumnID:String;
		public var questionColumnID:String;
		public var answerColumnIDs:Array;
		public var answerColumnTypes:Array;
		
		public const dependentIDS:Dictionary = new Dictionary();
		public const dependentValue:Dictionary = new Dictionary();
		
		
	}
}