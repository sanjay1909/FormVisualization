package ehs.form
{
	import ehs.data.SurveySection;
	import ehs.ui.SurveySectionUI;
	
	import weave.api.detectLinkableObjectChange;
	import weave.api.newLinkableChild;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.core.ILinkableObject;
	import weave.compiler.Compiler;
	import weave.core.ClassUtils;
	import weave.core.LinkableHashMap;

	public class RenderManager implements ILinkableObject
	{
		public function RenderManager()
		{
			/*var stats:IColumnStatistics = WeaveAPI.StatisticsCache.getColumnStatistics(renderer.sectionColumn);
			getCallbackCollection(stats).addImmediateCallback(this, createSections,true);*/
			renderer.binAsyncCallback.addImmediateCallback(this, createSections,true);
			sections.childListCallbacks.addImmediateCallback(this, configNewSection);
			sectionUIs.childListCallbacks.addImmediateCallback(this, pinSection);
		}
		
		
		public const sections:LinkableHashMap = registerLinkableChild(this,new LinkableHashMap());
		
		public const renderer:FormRenderer = newLinkableChild(this, FormRenderer);
		private const sectionUIs:LinkableHashMap = registerDisposableChild(this, new LinkableHashMap());
		
		public function get surveySectionUIs():LinkableHashMap{
			return sectionUIs;
		}
		
		
		private var _name_to_Section:Object = {}; // name -> Array of PlotTask
		
		private function stringifyJSON(obj:Object):Object
		{
			var JSON:Object = ClassUtils.getClassDefinition('JSON');
			if (JSON)
				return JSON.stringify(obj);
			else
				return Compiler.stringify(obj);
		}
		
		private function createSections():void{
			
			
			
			
			//PlotTask.debug = true;
			//StageUtils.debug_async_stack = true;
			//StageUtils.debug_async_time = true;
			//SessionStateLog.debug = true;
			if(detectLinkableObjectChange(this,renderer.binnedSection,renderer.binnedSection.binningDefinition)){
				var secs:Array = renderer.binnedSection.binningDefinition.getBinNames();
				if(!secs || secs.length == 0){ // asyn call still collecting data
					//trace('sectionData Empty');
					return;
				}	
				trace('Create All Sections');
				
				sections.removeAllObjects();
				//sections.delayCallbacks();
				for( var i:int = 0 ; i < secs.length; i++)
					sections.requestObject(secs[i],SurveySection,false);
				
				//var arr:* = (WeaveAPI.SessionManager as SessionManager).getParentChildTree(WeaveAPI.globalHashMap);
				//var obj:* = stringifyJSON(arr);
				//var json:* = DescribeType.getInstanceInfo(arr);
				//trace(arr);
			}
			
			
			
			//sections.resumeCallbacks()
		}
		
		
		private function configNewSection():void{
			
			
			// when section is removed, remove settings
			var oldName:String = sections.childListCallbacks.lastNameRemoved;
			if (oldName)
			{
				trace('remove  section: ' + oldName);
				sectionUIs.removeObject(oldName);
				return;
			}
			var newName:String = sections.childListCallbacks.lastNameAdded;			
			if(newName){	
				trace('Create  section: ' + newName);
				var sec:SurveySection = _name_to_Section[newName] = sections.childListCallbacks.lastObjectAdded as SurveySection;
				//renderer.renderAll(newName,sec.checklist);
				sectionUIs.requestObject(newName,SurveySectionUI,false);
			}
			
		}
		
		private function pinSection():void{
			var oldName:String = sectionUIs.childListCallbacks.lastNameRemoved;
			if (oldName)
			{
				trace('remove  section ui: ' + oldName);
				delete _name_to_Section[oldName];
				return;
			}
			var newName:String = sectionUIs.childListCallbacks.lastNameAdded;	
			if(newName){
				trace('create section UI: ' + newName);
				var sec:SurveySection = _name_to_Section[newName];
				var secUI:SurveySectionUI = sectionUIs.childListCallbacks.lastObjectAdded as SurveySectionUI;
				//secUI.controller.hashMap = sec.checklist;
			}
		}
		
		
	}
}