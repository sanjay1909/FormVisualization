package ehs.ui
{
	
	import weave.api.registerLinkableChild;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableVariable;
	
	public class FormData  implements IInspectionUI
	{
		public function FormData()
		{
			super();
			sections.childListCallbacks.addImmediateCallback(this, handleSection);
			uiData.addImmediateCallback(this, createSections,false,true);
		}
		
		
		protected const uiData:LinkableVariable = registerLinkableChild(this, new LinkableVariable(Array));
		public function get data():LinkableVariable{
			return uiData;
		}
		
		private var _uiName:String;
		public function get uiName():String{
			return _uiName;
		}
		public function set uiName(name:String):void{
			_uiName = name;
		}
		
		private var currentSectioName:String = "";
		private var sectionName:String = "";
		private var currentInsSectionUI:*;
		
		private var headerArray:Array = [];
		private function createSections():void{
			var rows:Array = uiData.getSessionState() as Array;
			if(rows){
				if(sections.getNames().length != 1)// to make sure Home section not removed
					sections.removeAllObjects();
				var sectionRows:Array = [];
				for(var j:int = 1; j < rows.length;j++){
					var row:Object = rows[j];					
					currentSectioName = row["section"];
					if(sectionName != currentSectioName){
						sectionName = currentSectioName;
						if(sectionRows.length > 1){
							currentInsSectionUI.data.setSessionState(sectionRows);
						}
						sections.requestObject(currentSectioName,FormSectionUI,false);
						sectionRows = [];
					}
					sectionRows.push(row);
				}
				currentInsSectionUI.data.setSessionState(sectionRows);
			}
		}
		
		public const sections:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap());
		private function handleSection():void{
			if(sections.childListCallbacks.lastNameAdded != null){
				currentInsSectionUI = sections.childListCallbacks.lastObjectAdded;
				currentInsSectionUI.sectiontitle = sectionName;
			}
		}
		
		
	}
	
	
	
}