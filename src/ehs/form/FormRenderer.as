package ehs.form
{
	import flash.utils.Dictionary;
	import flash.utils.Proxy;
	
	import weave.api.newDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IFilteredKeySet;
	import weave.api.data.IQualifiedKey;
	import weave.core.LinkableHashMap;
	import weave.core.UntypedLinkableVariable;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.AttributeColumns.ProxyColumn;
	import weave.data.AttributeColumns.ReferencedColumn;
	import weave.data.AttributeColumns.StringColumn;
	import weave.data.BinningDefinitions.CategoryBinningDefinition;
	import weave.data.KeySets.FilteredKeySet;

	public class FormRenderer implements ILinkableObject
	{
		//private var cc:CallbackCollection = newLinkableChild(this,CallbackCollection);
		
		public function FormRenderer()
		{
			sectionBinnedColumn.binningDefinition.requestLocalObjectCopy(_category);
			// to make sure proxy column internal column is available when you ask for value using key
			setColumnKeySources([sectionColumn]);
				//,questionColumn]);
			questionFilteredColumn.filter.requestLocalObject(FilteredKeySet, true);
			
			registerLinkableChild(this,sectionColumn);
			//registerLinkableChild(cc, questionColumn);
			
			//linkSessionState(_filteredKeySet.keyFilter, questionFilteredColumn.filter);
			// to get unique string from the data
			
			//getCallbackCollection(this).addImmediateCallback(this,testFunction);
		}
		
		private function testFunction():void{
			trace('render --  called');
		}
		
		//private const dummy:CallbackCollection = newDisposableChild(this,CallbackCollection);
		
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
		
		/*public function getSelectableAttributeNames():Array
		{
			return ["Section", "Question" ];
			//"Answer","Answer Type","Dependent Answer"];
		}
		public function getSelectableAttributes():Array
		{
			return [sectionColumn, questionColumn]
			//, answerColumn, answerTypeColumn, dependentColumn];
		}*/
		
		protected var sectionBinnedColumn:BinnedColumn = newDisposableChild(this , BinnedColumn);
		protected const questionFilteredColumn:FilteredColumn = newDisposableChild(this, FilteredColumn);
		
		
		private const _category:CategoryBinningDefinition = newDisposableChild(this, CategoryBinningDefinition);
		
		
		public function get binnedSection():BinnedColumn{
			return sectionBinnedColumn;
		}
		
		public function get strColumn():StringColumn{
			var refCol:ReferencedColumn = sectionColumn.getInternalColumn() as ReferencedColumn;
			var proxCol:ProxyColumn = refCol?refCol.getInternalColumn() as ProxyColumn : null;
			var strCol:StringColumn = proxCol?proxCol.getInternalColumn() as StringColumn : null;
			return strCol;
		}
		
		public function get sectionColumn():DynamicColumn{
			return sectionBinnedColumn.internalDynamicColumn;
		}
		
		/*public function get questionColumn():DynamicColumn{
			return questionFilteredColumn.internalDynamicColumn;
		}
		*/
		public function get binAsyncCallback():ICallbackCollection{
			return sectionBinnedColumn.binningDefinition.asyncResultCallbacks
		}
		
		/** 
		 * This variable is returned by get keySet().
		 */
		protected const _filteredKeySet:FilteredKeySet = newDisposableChild(this,FilteredKeySet);
		
		/**
		 * @return An IKeySet interface to the record keys that can be passed to the drawRecord() and getDataBoundsFromRecordKey() functions.
		 */
		
		public function get filteredKeySet():IFilteredKeySet
		{
			return _filteredKeySet;
		}
		
		private function getSectionRecordKeys(sectionName:String):Array{
			var sectionKeys:Array = sectionBinnedColumn.getKeysFromBinName(sectionName);
			if(!sectionKeys){
				return [];
			}
			return sectionKeys;
		}
		
		public function renderAll(sectionName:String,sectionList:LinkableHashMap):void{
			var recordKeys:Array = getSectionRecordKeys(sectionName);
			for(var j:int = 0 ; j < recordKeys.length; j++){
				var recordKey:IQualifiedKey = recordKeys[j] as IQualifiedKey;
				var ul:UntypedLinkableVariable = sectionList.requestObject(recordKey.localName,UntypedLinkableVariable,false);
				ul.value = getObjectFromRecordKey(recordKey);
			}
		}
		
		private var _recordCache:Dictionary = new Dictionary(true);
		public function getObjectFromRecordKey(recordKey:IQualifiedKey):Object{
			
			
			/*if (detectLinkableObjectChange(this, questionColumn))
				_recordCache= new Dictionary(true);*/
			
			var obj:*;
			if(_recordCache[recordKey] === undefined){
				obj  = {};
				_recordCache[recordKey] =  obj;
			}else{
				obj = _recordCache[recordKey];
				return obj;
			}
			
		//	obj[questionColumn.getMetadata(ColumnMetadata.TITLE)] = questionColumn.getValueFromKey(recordKey,String);
			// set component UI descriptor here  	
			
			
			// as linkableVariable uses Objectutil.copy to convert this to a object we will lose the signature
			obj['keyType'] = recordKey.keyType;
			obj['localName'] = recordKey.localName;
			
			return obj;
		}
		
	}
}