package ehs.data
{
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableHashMap;
	import weave.core.UntypedLinkableVariable;
	
	public class SurveySection implements ILinkableObject
	{
		public function SurveySection()
		{
			//checklist.childListCallbacks.addImmediateCallback(this, initValue);
			
		}
		
		public const checklist:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap());
		
		public const secData:UntypedLinkableVariable = newLinkableChild(this, UntypedLinkableVariable);
		
		private const dummy:UntypedLinkableVariable = newLinkableChild(this, UntypedLinkableVariable);
		
		//public var plotter:SurveyPloter = null;
		
		/*private function initValue():void{
			trace('initValue');
			if(checklist.childListCallbacks.lastObjectAdded){
				var ul:UntypedLinkableVariable = checklist.childListCallbacks.lastObjectAdded as UntypedLinkableVariable;		
				ul.value = getObjectFromRecordKey(plotter.currentKey);
			}
		}*/
		
		
				
		
		/*private var _recordCache:Dictionary = new Dictionary(true);		
		
		private function getObjectFromRecordKey(recordKey:IQualifiedKey):*{
			
			if (detectLinkableObjectChange(this, plotter.questionColumn))
				_recordCache= new Dictionary(true);
			
			var obj:*;
			if(_recordCache[recordKey] === undefined){
				obj  = {};
				_recordCache[recordKey] =  obj;
			}else{
				obj = _recordCache[recordKey];
				return obj;
			}
			
			
			plotter.fillObjectFromRecordKey(obj);
			return obj;
			
		}*/
		
	}
}