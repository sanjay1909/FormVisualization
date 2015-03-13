package ehs.data
{
	import ehs.EHS;
	import ehs.EHSProperties;
	
	import weave.api.registerLinkableChild;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	
	public class InspectionReportData implements ILinkableObject
	{
		public function InspectionReportData()
		{
			
		}
		
		
		
		
		public const status:LinkableString = registerLinkableChild(this,new LinkableString(EHSProperties.INSPECTION),updateFileStatus);
		public const formPriorityLevel:LinkableNumber = registerLinkableChild(this,new LinkableNumber());
		public const dueDate:LinkableVariable = registerLinkableChild(this,new LinkableVariable(Date));
		public const cho:LinkableString = registerLinkableChild(this,new LinkableString());
		public const choMailID:LinkableString = registerLinkableChild(this,new LinkableString());
		public const formComment:LinkableString = registerLinkableChild(this,new LinkableString());			
		
		
		public var completed:Boolean = false;
		private function validate():void{
			
			if( status.value && status.value.length)
			{
				completed = true;
			}
			else{
				completed = false;
			}
			
		}
		
		private function updateFileStatus():void{
			/*if(status.value && status.value.length > 0){
				if(!Admin.instance.userHasAuthenticated){
					Admin.instance.userHasAuthenticated = true;
					
				}
			}*/
			
		}
		
		
		
		
		
		
		
	}
}