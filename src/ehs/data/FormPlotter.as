package ehs.data
{
	import flash.utils.Dictionary;
	
	import ehs.ui.FormRenderTask;
	import ehs.ui.SurveySectionUI;
	
	import weave.Weave;
	import weave.api.linkSessionState;
	import weave.api.linkableObjectIsBusy;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IFilteredKeySet;
	import weave.api.data.IKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.ui.IPlotter;
	import weave.core.CallbackCollection;
	import weave.core.LinkableHashMap;
	import weave.core.UntypedLinkableVariable;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.BinningDefinitions.CategoryBinningDefinition;
	import weave.data.KeySets.FilteredKeySet;
	import weave.visualization.layers.LayerSettings;

	public class FormPlotter implements ILinkableObject
	{
		
		public function FormPlotter()
		{
			_filteredKeySet.keyFilter.targetPath = [Weave.DEFAULT_SUBSET_KEYFILTER];
			// to make sure proxy column internal column is available when you ask for value using key
			setColumnKeySources([sectionColumn,questionColumn]);
				//, answerColumn,answerTypeColumn,dependentColumn]);
			
			
			questionFilteredColumn.filter.requestLocalObject(FilteredKeySet, true);
			//answerFilteredColumn.filter.requestLocalObject(FilteredKeySet, true);
			//dependentFilteredColumn.filter.requestLocalObject(FilteredKeySet, true);
			
			registerLinkableChild(this,sectionColumn);
			registerLinkableChild(this,questionColumn);
			//registerLinkableChild(this,answerColumn);
			//registerLinkableChild(this,dependentColumn);
			
			linkSessionState(_filteredKeySet.keyFilter, questionFilteredColumn.filter);
			//linkSessionState(_filteredKeySet.keyFilter, answerFilteredColumn.filter);
			//linkSessionState(_filteredKeySet.keyFilter, dependentFilteredColumn.filter);
			
			// to get unique string from the data
			sectionBinnedColumn.binningDefinition.requestLocalObjectCopy(_category);
			sectionBinnedColumn.binningDefinition.asyncResultCallbacks.addImmediateCallback(this, createSections,false);
			
			sections.childListCallbacks.addImmediateCallback(this, configSection);
			
			
		}
		
		public function getAsyncBinResultCallbacks():ICallbackCollection{
			return sectionBinnedColumn.binningDefinition.asyncResultCallbacks;
		}
		
		public function getSelectableAttributeNames():Array
		{
			return ["Section", "Question" ];
				//"Answer","Answer Type","Dependent Answer"];
		}
		public function getSelectableAttributes():Array
		{
			return [sectionColumn, questionColumn]
				//, answerColumn, answerTypeColumn, dependentColumn];
		}
		
		
		public static const MULTIPLE_CHOICE_SINGLE:String = 'Multiple Choice Single Answer';
		public static const MULTIPLE_CHOICE_MULTIPLE:String = 'Multiple Choice Multiple Answer';
		public static const TEXT:String = 'Text';
		
		public const sections:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap());
		// equivalent to bitmap in other weave plotters
		public var surveySectionUIs:LinkableHashMap = registerDisposableChild(this,new LinkableHashMap(SurveySectionUI));
		
		protected const sectionBinnedColumn:BinnedColumn = newDisposableChild(this , BinnedColumn);
		protected const questionFilteredColumn:FilteredColumn = newDisposableChild(this, FilteredColumn);
		//protected const answerFilteredColumn:FilteredColumn = newDisposableChild(this, FilteredColumn);
		//protected const dependentFilteredColumn:FilteredColumn = newDisposableChild(this, FilteredColumn);
		
		//public const answerTypeColumn:DynamicColumn = newLinkableChild(this, DynamicColumn);
		
		
		private const _category:CategoryBinningDefinition = newLinkableChild(this, CategoryBinningDefinition);
		
		public function get sectionColumn():DynamicColumn{
			return sectionBinnedColumn.internalDynamicColumn;
		}
		
		public function get questionColumn():DynamicColumn{
			return questionFilteredColumn.internalDynamicColumn;
		}
		
		/*public function get answerColumn():DynamicColumn{
			return answerFilteredColumn.internalDynamicColumn;
		}*/
		
		/*public function get dependentColumn():DynamicColumn{
			return dependentFilteredColumn.internalDynamicColumn;
		}*/
		
		
		
		/** 
		 * This variable is returned by get keySet().
		 */
		protected const _filteredKeySet:FilteredKeySet = newLinkableChild(this,FilteredKeySet);
		
		/**
		 * @return An IKeySet interface to the record keys that can be passed to the drawRecord() and getDataBoundsFromRecordKey() functions.
		 */
		public function get filteredKeySet():IFilteredKeySet
		{
			return _filteredKeySet;
		}
		
		/**
		 * This will set up the keySet so it provides keys in sorted order based on the values in a list of columns.
		 * @param columns An Array of IAttributeColumns to use for comparing IQualifiedKeys.
		 * @param sortDirections Array of sort directions corresponding to the columns and given as integers (1=ascending, -1=descending, 0=none).
		 * @see weave.data.KeySets.FilteredKeySet#setColumnKeySources()
		 */
		private function setColumnKeySources( columns:Array , sortDirections:Array = null):void
		{
			_filteredKeySet.setColumnKeySources(columns, sortDirections);
		}
		
		
		/**
		 * This function sets the base IKeySet that is being filtered.
		 * @param newBaseKeySet A new IKeySet to use as the base for this FilteredKeySet.
		 */
		protected function setSingleKeySource(keySet:IKeySet):void
		{
			_filteredKeySet.setSingleKeySource(keySet);
		}
		
		
		private function createSections():void{
			
			if(linkableObjectIsBusy(sectionBinnedColumn))
			{
				trace('linkableObjectIsBusy BinnedColumn - internal Dynamic column(ref column - proxy col - str column');
				return;
			}
			
			var secs:Array = sectionBinnedColumn.binningDefinition.getBinNames();
			if(!secs || secs.length == 0){ // asyn call still collecting data
				trace('sectionData Empty');
				return;
			}
			
			
			// lopp section has to go to ne				
			for( var i:int = 0 ; i < secs.length; i++){
				trace('createSections: ' + secs[i]);
				sections.requestObject(secs[i],SurveySection,false);
				
			}
			CallbackCollection.debug = true;
			//SessionStateLog.debug = true;
			
			
		}
		
		
		public function getSectionRecordKeys(sectionName:String,taskType:int):Array{
			var sectionKeys:Array = sectionBinnedColumn.getKeysFromBinName(sectionName);
			if(!sectionKeys){
				return [];
			}
			return sectionKeys;
		}
		
		
		public function renderRecordAsyncIteration(task:FormRenderTask):Number{
			renderAll(task.recordKeys,task.sectionList,task.sectionName);
			return 1;
		}
		
		public var currentKey:IQualifiedKey = null;
		private function renderAll(recordKeys:Array,sectionList:LinkableHashMap,sectionName:String):void{
			for(var j:int = 0 ; j < recordKeys.length; j++){
				currentKey = recordKeys[j] as IQualifiedKey;	
				var sec:SurveySection = name_section_map[sectionName];
				sectionList.requestObject(currentKey.localName,UntypedLinkableVariable,false);
			}
		}
		
		private var _name_to_PlotTask_Array:Object = {}; // name -> Array of PlotTask
		public const layerSettings:LayerSettings = newLinkableChild(this,LayerSettings);
		private function configSection():void{
			if(sections.childListCallbacks.lastObjectAdded){
				var secName:String = sections.childListCallbacks.lastNameAdded;				
				if(secName ){
					var sec:SurveySection =  sections.childListCallbacks.lastObjectAdded as SurveySection;
					name_section_map[secName] = sec;
					sec.plotter = this;
					var ui:SurveySectionUI = surveySectionUIs.requestObject(secName,SurveySectionUI,false);
					ui.controller.hashMap = sec.checklist;
					var tasks:Array = _name_to_PlotTask_Array[secName] = [];
					for each (var taskType:int in [FormRenderTask.TASK_TYPE_SUBSET, FormRenderTask.TASK_TYPE_SELECTION, FormRenderTask.TASK_TYPE_PROBE])
					{
						var task:FormRenderTask = new FormRenderTask(FormRenderTask.TASK_TYPE_SUBSET,this,secName,sec.checklist,layerSettings);
						registerDisposableChild(this, task); // plotter is owner of task
						registerLinkableChild(ui, task); // task affects busy status of the sectuonUI
						tasks.push(task);
						//getCallbackCollection(task).addImmediateCallback(this, refreshLayers);
					}
					
					
					
				}
			}
		}
		
		
		private var name_section_map:Dictionary = new Dictionary(true);
		
		//private var _questionCache:Dictionary;
		//private var _answerCache:Dictionary;
		//private var _dependentCache:Dictionary;
		
		
		
		/**
		 * This gets called whenever any of the following change: questionColumn, answerColumn, dependentColumn
		 */		
		/*private function updateCache():void
		{
			//_questionCache = new Dictionary(true);
			//_answerCache = new Dictionary(true);
			//_dependentCache = new Dictionary(true);
			_recordCache= new Dictionary(true);
		}
		
		
		private var _recordCache:Dictionary = new Dictionary(true);
		
		
		
		private function getObjectFromRecordKey(recordKey:IQualifiedKey):*{
			
			if (detectLinkableObjectChange(this, questionColumn))
				updateCache();
			
			var obj:*;
			if(_recordCache[recordKey] === undefined){
				obj  = {};
				_recordCache[recordKey] =  obj;
			}else{
				obj = _recordCache[recordKey];
				return obj;
			}
			// second time we can access from cache is nothing is changed
			//if (_questionCache[recordKey] !== undefined)
			//{
				//obj['question']= _questionCache[recordKey];
				//obj['answer'] = _answerCache[recordKey];
				//obj['dependent'] = _dependentCache[recordKey];
				//obj['QKey'] = recordKey;
				
			//	return obj;
			//}
			
			obj['question'] = questionColumn.getValueFromKey(recordKey);
			//obj['answer'] = answerColumn.getValueFromKey(recordKey);
			//obj['dependent'] = dependentColumn.getValueFromKey(recordKey);
			obj['QKey'] = recordKey;
			
			//_questionCache[recordKey] = obj['question'];
			//_answerCache[recordKey] = obj['answer'];
			//_dependentCache[recordKey] = obj['dependent'];
			
			return obj;
			
		}*/
		
		
	
		
		
		
	}
}