package weave.visualization.plotters
{
	import flash.display.BitmapData;
	import flash.utils.Dictionary;
	
	import weave.api.detectLinkableObjectChange;
	import weave.api.getCallbackCollection;
	import weave.api.linkSessionState;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IFilteredKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.api.primitives.IBounds2D;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.ITextPlotter;
	import weave.core.CallbackCollection;
	import weave.core.LinkableHashMap;
	import weave.core.UntypedLinkableVariable;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.BinningDefinitions.CategoryBinningDefinition;
	import weave.data.KeySets.FilteredKeySet;
	import weave.visualization.layers.SurveyPlotTask;
	
	public class SurveyPloter implements ITextPlotter
	{
		//WeaveAPI.ClassRegistry.registerImplementation(ITextPlotter, SurveyPloter, "SurveyPlot");
		public function SurveyPloter()
		{
			//_filteredKeySet.keyFilter.targetPath = [Weave.DEFAULT_SUBSET_KEYFILTER];
			// to make sure proxy column internal column is available when you ask for value using key
			setColumnKeySources([sectionColumn,questionColumn]);
			//, answerColumn,answerTypeColumn,dependentColumn]);
			
			
			questionFilteredColumn.filter.requestLocalObject(FilteredKeySet, true);
			//answerFilteredColumn.filter.requestLocalObject(FilteredKeySet, true);
			//dependentFilteredColumn.filter.requestLocalObject(FilteredKeySet, true);
			
			registerSpatialProperty(sectionColumn);
			registerSpatialProperty(questionColumn);
			//registerLinkableChild(this,answerColumn);
			//registerLinkableChild(this,dependentColumn);
			
			linkSessionState(_filteredKeySet.keyFilter, questionFilteredColumn.filter);
			//linkSessionState(_filteredKeySet.keyFilter, answerFilteredColumn.filter);
			//linkSessionState(_filteredKeySet.keyFilter, dependentFilteredColumn.filter);
			
			// to get unique string from the data
			sectionBinnedColumn.binningDefinition.requestLocalObjectCopy(_category);
			//sectionBinnedColumn.binningDefinition.asyncResultCallbacks.addImmediateCallback(this, createSections,false);
			
			
		}
		/**
		 * This will set up the keySet so it provides keys in sorted order based on the values in a list of columns.
		 * @param columns An Array of IAttributeColumns to use for comparing IQualifiedKeys.
		 * @param sortDirections Array of sort directions corresponding to the columns and given as integers (1=ascending, -1=descending, 0=none).
		 * @see weave.data.KeySets.FilteredKeySet#setColumnKeySources()
		 */
		protected function setColumnKeySources(columns:Array, sortDirections:Array = null):void
		{
			_filteredKeySet.setColumnKeySources(columns, sortDirections);
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
		
		
		protected const sectionBinnedColumn:BinnedColumn = newDisposableChild(this , BinnedColumn);
		protected const questionFilteredColumn:FilteredColumn = newDisposableChild(this, FilteredColumn);
		//protected const answerFilteredColumn:FilteredColumn = newDisposableChild(this, FilteredColumn);
		//protected const dependentFilteredColumn:FilteredColumn = newDisposableChild(this, FilteredColumn);
		
		//public const answerTypeColumn:DynamicColumn = newLinkableChild(this, DynamicColumn);
		
		
		private const _category:CategoryBinningDefinition = newLinkableChild(this, CategoryBinningDefinition);
		
		
		public function get binnedSection():BinnedColumn{
			return sectionBinnedColumn;
		}
		
		public function get sectionColumn():DynamicColumn{
			return sectionBinnedColumn.internalDynamicColumn;
		}
		
		public function get questionColumn():DynamicColumn{
			return questionFilteredColumn.internalDynamicColumn;
		}
		
		public function get binAsyncCallback():ICallbackCollection{
			return sectionBinnedColumn.binningDefinition.asyncResultCallbacks
		}
		
		/**
		 * This function creates a new registered linkable child of the plotter whose callbacks will also trigger the spatial callbacks.
		 * @return A new instance of the specified class that is registered as a spatial property.
		 */
		protected function newSpatialProperty(linkableChildClass:Class, callback:Function = null):*
		{
			var child:ILinkableObject = newLinkableChild(this, linkableChildClass, callback);
			
			var thisCC:ICallbackCollection = getCallbackCollection(this);
			var childCC:ICallbackCollection = getCallbackCollection(child);
			// instead of triggering parent callbacks, trigger spatialCallbacks which will in turn trigger parent callbacks.
			childCC.removeCallback(thisCC.triggerCallbacks);
			registerLinkableChild(spatialCallbacks, child);
			
			return child;
		}
		
		/**
		 * This function registers a linkable child of the plotter whose callbacks will also trigger the spatial callbacks.
		 * @param child An object to register as a spatial property.
		 * @return The child object.
		 */
		protected function registerSpatialProperty(child:ILinkableObject, callback:Function = null):*
		{
			registerLinkableChild(this, child, callback);
			
			var thisCC:ICallbackCollection = getCallbackCollection(this);
			var childCC:ICallbackCollection = getCallbackCollection(child);
			// instead of triggering parent callbacks, trigger spatialCallbacks which will in turn trigger parent callbacks.
			childCC.removeCallback(thisCC.triggerCallbacks);
			registerLinkableChild(spatialCallbacks, child);
			
			return child;
		}
		
		
		/*
		 * Interface implementation
		 */
		/**
		 * This variable should not be set manually.  It cannot be made constant because we cannot guarantee that it will be initialized
		 * before other properties are initialized, which means it may be null when someone wants to call registerSpatialProperty().
		 */		
		private var _spatialCallbacks:ICallbackCollection = null;
		
		/**
		 * This is an interface for adding callbacks that get called when any spatial properties of the plotter change.
		 * Spatial properties are those that affect the data bounds of visual elements.
		 */
		public function get spatialCallbacks():ICallbackCollection
		{
			if (_spatialCallbacks == null)
				_spatialCallbacks = newLinkableChild(this, CallbackCollection);
			return _spatialCallbacks;
		}
		/** 
		 * This variable is returned by get keySet().
		 */
		protected const _filteredKeySet:FilteredKeySet = newSpatialProperty(FilteredKeySet);
		
		/**
		 * @return An IKeySet interface to the record keys that can be passed to the drawRecord() and getDataBoundsFromRecordKey() functions.
		 */
		
		public function get filteredKeySet():IFilteredKeySet
		{
			return _filteredKeySet;
		}
		
		public function getDataBoundsFromRecordKey(key:IQualifiedKey, output:Array):void
		{
		}
		public function getSectionRecordKeys(sectionName:String):Array{
			var sectionKeys:Array = sectionBinnedColumn.getKeysFromBinName(sectionName);
			if(!sectionKeys){
				return [];
			}
			return sectionKeys;
		}
		
		public function drawPlotAsyncIteration(task:IPlotTask):Number
		{
			var surveyTask:SurveyPlotTask = task as SurveyPlotTask;
			renderAll(surveyTask.recordKeys,surveyTask.sectionList,surveyTask.sectionName);
			return 1;
		}
		
		
		private function renderAll(recordKeys:Array,sectionList:LinkableHashMap,sectionName:String):void{
			for(var j:int = 0 ; j < recordKeys.length; j++){
				var recordKey:IQualifiedKey = recordKeys[j] as IQualifiedKey;
				var ul:UntypedLinkableVariable = sectionList.requestObject(recordKey.localName,UntypedLinkableVariable,false);
				ul.value = getObjectFromRecordKey(recordKey);
			}
		}
		
		
		private var _recordCache:Dictionary = new Dictionary(true);
		public function getObjectFromRecordKey(recordKey:IQualifiedKey):Object{
			
			
			if (detectLinkableObjectChange(this, questionColumn))
				_recordCache= new Dictionary(true);
			
			var obj:*;
			if(_recordCache[recordKey] === undefined){
				obj  = {};
				_recordCache[recordKey] =  obj;
			}else{
				obj = _recordCache[recordKey];
				return obj;
			}
			
			obj[questionColumn.getMetadata(ColumnMetadata.TITLE)] = questionColumn.getValueFromKey(recordKey,String);
			// set component UI descriptor here  	
		
			
			// as linkableVariable uses Objectutil.copy to convert this to a object we will lose the signature
			obj['keyType'] = recordKey.keyType;
			obj['localName'] = recordKey.localName;
			
			return obj;
		}
		
		
		
		
		
		public function getBackgroundDataBounds(output:IBounds2D):void
		{
		}
		
		public function drawBackground(dataBounds:IBounds2D, screenBounds:IBounds2D, destination:BitmapData):void
		{
			// can draw Colors or Logo 
			// by getting the graphics of the UI
			
		}
		
		
	}
}