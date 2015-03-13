package ehs.data
{
	
	
	import ehs.EHS;
	import ehs.EHSProperties;
	import ehs.EHSUtils;
	
	import weave.api.getCallbackCollection;
	import weave.api.registerLinkableChild;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	
	public class InspectionKeyData implements ILinkableObject
	{
		public function InspectionKeyData()
		{
			getCallbackCollection(this).addGroupedCallback(this,validate);
			followUpDate.addImmediateCallback(this, collectFollowUpDates);
		}
		
		
		public const building:LinkableString = registerLinkableChild(this,new LinkableString());
		public const roomNumbers:LinkableString = registerLinkableChild(this,new LinkableString());
		public const principalInvestigator:LinkableString = registerLinkableChild(this,new LinkableString());
		public const dept:LinkableString = registerLinkableChild(this,new LinkableString());
		public const inspector:LinkableString = registerLinkableChild(this,new LinkableString());
		
		public const primaryFunction:LinkableVariable = registerLinkableChild(this,new LinkableVariable(Array));
		public const inspectionDate:LinkableVariable = registerLinkableChild(this,new LinkableVariable(Date));
		public const followUpDate:LinkableVariable = registerLinkableChild(this,new LinkableVariable(Date));
		public const followUpDates:LinkableVariable = registerLinkableChild(this,new LinkableVariable(Array));
		
		public const printableData:LinkableVariable  = registerLinkableChild(this, new LinkableVariable(Array));
		
		public var completed:Boolean = false;
		
		
		public var isProfessor:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		private function validate():void{
			var primaryFunc:Array = primaryFunction.getSessionState() as Array;
			var insDate:Date = inspectionDate.getSessionState() as Date;
			
			if( (building.value && building.value.length) && (roomNumbers.value && roomNumbers.value.length) && 
				(principalInvestigator.value && principalInvestigator.value.length) && (dept.value && dept.value.length) &&
				(inspector.value && inspector.value.length) && primaryFunc && inspectionDate)
			{
				completed = true;
			}
			else{
				completed = false;
			}
				
		}
		
		private function collectFollowUpDates():void{
			var dateAsString:String;
			var date:Date = followUpDate.getSessionState() as Date;
			if(date){
				dateAsString = EHSUtils.formatDate(date);
			}
			var dates:Array = followUpDates.getSessionState() as Array;
			if(!dates){
				followUpDates.setSessionState(new Array());
			}
			dates = followUpDates.getSessionState() as Array;
			dates.push(dateAsString);
			followUpDates.setSessionState(dates);
			
		}
		
		public function getDataAsArray():Array{
			var arr:Array = new Array();
			arr.push(["Building", building.value]);
			if(roomNumbers.value.indexOf(",") >= 0){
				arr.push(["Rooms",roomNumbers.value]);
			}
			else{
				arr.push(["Room",roomNumbers.value]);
			}			
			arr.push(["Principal Investigator",principalInvestigator.value ]);
			arr.push(["Inspector",inspector.value]);
			arr.push(["Department", dept.value]);
			arr.push(["Inspection",EHSUtils.formatDate(inspectionDate.getSessionState()  as Date)]);
			arr.push(["Primary Function",(primaryFunction.getSessionState() as Array).join(", ")]);
			if(EHS.properties.mode.value == EHSProperties.FOLLOWUP){
				var followUpDatesAsString:String = (followUpDates.getSessionState() as Array).join(" ");
				arr.push(["Follow Up",followUpDatesAsString]);
			}
			
			
			
			return arr;
		}
		
		// to get ref of those object for PDF tool
		public function getDataAsObjectArray():Array{
			var arr:Array = new Array();
			arr.push({property:"Building",value:building});
			if(roomNumbers.value.indexOf(",") >= 0){
				arr.push({property:"Rooms",value:roomNumbers});
			}
			else{
				arr.push({property:"Room",value:roomNumbers});
			}			
			arr.push({property:"Principal Investigator",value:principalInvestigator });
			arr.push({property:"Inspector",value:inspector});
			arr.push({property:"Department",value: dept});			
			arr.push({property:"Date",value:inspectionDate});
			arr.push({property:"Primary Function",value:primaryFunction});
			arr.push({property:"Follow Up",value:followUpDates});
			return arr;
			
		}
		
		
		
		
		
		
	}
}