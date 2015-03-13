package weave.visualization.layers
{
	import ehs.data.SurveySection;
	import ehs.ui.SurveySectionUI;
	
	import weave.api.linkableObjectIsBusy;
	import weave.api.newLinkableChild;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableHashMap;
	import weave.core.UntypedLinkableVariable;
	import weave.visualization.plotters.SurveyPloter;
	
	public class SurveyManager implements ILinkableObject
	{
		public function SurveyManager()
		{
			plotter.binAsyncCallback.addGroupedCallback(this, createSections);
			sections.childListCallbacks.addImmediateCallback(this, handleSectionList);
			_surveySectionUIs.childListCallbacks.addImmediateCallback(this, pinSection);
			//PlotTask.debug = true;
			
		}
		
		public const layerSetting:LayerSettings = newLinkableChild(this, LayerSettings);
		public const plotter:SurveyPloter = newLinkableChild(this,SurveyPloter);
		
		public const sections:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap());
		private const _surveySectionUIs:LinkableHashMap = registerDisposableChild(this, new LinkableHashMap());
		public function get surveySectionUIs():LinkableHashMap{
			return _surveySectionUIs;
		}
		
		private var _name_to_PlotTask_Array:Object = {}; // name -> Array of PlotTask
		private var _name_to_Section:Object = {}; // name -> Array of PlotTask
		
		
		private function createSections():void{
			
			if(linkableObjectIsBusy(plotter.binnedSection))
			{
				trace('linkableObjectIsBusy BinnedColumn - internal Dynamic column(ref column - proxy col - str column');
				return;
			}	
			
			if(linkableObjectIsBusy(plotter))
			{
				trace('linkableObjectIsBusy plotter');
				return;
			}
			if(linkableObjectIsBusy(plotter.binAsyncCallback))
			{
				trace('linkableObjectIsBusy binAsyncCallback');
				return;
			}
			var secs:Array = plotter.binnedSection.binningDefinition.getBinNames();
			if(!secs || secs.length == 0){ // asyn call still collecting data
				trace('sectionData Empty');
				return;
			}
			
			sections.removeAllObjects();
			for( var i:int = 0 ; i < secs.length; i++)
				sections.requestObject(secs[i],SurveySection,false);			
		}
		
		
		private function handleSectionList():void{
			trace('handleSectionList');
			
			// when section is removed, remove settings
			var oldName:String = sections.childListCallbacks.lastNameRemoved;
			if (oldName)
			{
				delete _name_to_PlotTask_Array[oldName];
				_surveySectionUIs.removeObject(oldName);
				return;
			}
			var newName:String = sections.childListCallbacks.lastNameAdded;			
			if(newName){					
				var sec:SurveySection = _name_to_Section[newName] = sections.childListCallbacks.lastObjectAdded as SurveySection;
				//sec.plotter = plotter;				
				var tasks:Array = _name_to_PlotTask_Array[newName] = [];
				//for each (var taskType:int in [SurveyPlotTask.TASK_TYPE_SECTION])
					//, SurveyPlotTask.TASK_TYPE_SELECTION, SurveyPlotTask.TASK_TYPE_PROBE])
				//{
					var task:SurveyPlotTask = new SurveyPlotTask(SurveyPlotTask.TASK_TYPE_SECTION,plotter,newName,sec.checklist,layerSetting);
					registerDisposableChild(plotter, task); // plotter is owner of task
					registerLinkableChild(this, task); // task affects busy status of the sectuonUI
					tasks.push(task);
					//getCallbackCollection(task).addImmediateCallback(this, refreshLayers);
				//}	
				//setupBitmapFilters(plotter, layerSetting, tasks[0], tasks[1], tasks[2]);	
				
				_surveySectionUIs.requestObject(newName,SurveySectionUI,false);
				//sec.checklist.childListCallbacks.addImmediateCallback(this, initValue);
			}
			
		}
		
		private function pinSection():void{
			trace('pinSection');
			//_surveySectionUIs.delayCallbacks();
			// when section is removed, remove settings
			var oldName:String = _surveySectionUIs.childListCallbacks.lastNameRemoved;
			if (oldName)
			{
				delete _name_to_Section[oldName];
				return;
			}
			var newName:String = _surveySectionUIs.childListCallbacks.lastNameAdded;	
			if(newName){
				var sec:SurveySection = _name_to_Section[newName];
				var secUI:SurveySectionUI = _surveySectionUIs.childListCallbacks.lastObjectAdded as SurveySectionUI;
				secUI.controller.hashMap = sec.checklist;
			}
			//_surveySectionUIs.resumeCallbacks();
		}
		
		/*private function initValue():void{
			trace('initValue');
			if(checklist.childListCallbacks.lastObjectAdded){
				var ul:UntypedLinkableVariable = checklist.childListCallbacks.lastObjectAdded as UntypedLinkableVariable;		
				ul.value = getObjectFromRecordKey(plotter.currentKey);
			}
		}*/
		
		
		
		
		
	}
}