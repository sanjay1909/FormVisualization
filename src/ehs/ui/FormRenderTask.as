package ehs.ui
{
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import ehs.data.FormPlotter;
	
	import weave.api.getCallbackCollection;
	import weave.api.linkableObjectIsBusy;
	import weave.api.newDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IDynamicKeyFilter;
	import weave.api.data.IKeyFilter;
	import weave.api.data.IQualifiedKey;
	import weave.core.CallbackCollection;
	import weave.core.LinkableHashMap;
	import weave.visualization.layers.LayerSettings;
	
	public class FormRenderTask implements ILinkableObject, IDisposableObject
	{
		public static const TASK_TYPE_SUBSET:int = 0;
		public static const	TASK_TYPE_SELECTION:int = 1;
		public static const TASK_TYPE_PROBE:int = 2;
		
		public static var debug:Boolean = false;
		public static var debugMouseDownPause:Boolean = false;
		
		public function FormRenderTask(taskType:int, plotter:FormPlotter,sectionName:String,sectionList:LinkableHashMap,layerSettings:LayerSettings = null )
		{
			_taskType = taskType;
			_plotter = plotter;
			_sectionName = sectionName;
			_sectionList = sectionList
			_layerSettings = layerSettings
			
			// TEMPORARY SOLUTION until we start using VisToolGroup
			var subsetFilter:IDynamicKeyFilter = _plotter.filteredKeySet.keyFilter;
			var keyFilters:Array = [subsetFilter, layerSettings.selectionFilter, layerSettings.probeFilter];
			var keyFilter:ILinkableObject = keyFilters[_taskType];
			
			
			// _dependencies is used as the parent so we can check its busy status with a single function call.
			var list:Array = [_plotter,keyFilter,_layerSettings];
			for each (var dependency:ILinkableObject in list)
				registerLinkableChild(_dependencies, dependency);
			
			getCallbackCollection(_plotter.filteredKeySet).addImmediateCallback(this, handleKeySetChange, true);
			_dependencies.addImmediateCallback(this, asyncStart, true);
		}
		
		private var _plotter:FormPlotter = null;
		private var _layerSettings:LayerSettings;
		private var _sectionName:String = '';
		private var _sectionList:LinkableHashMap = null;
		private var _keyFilter:IKeyFilter;
		private var _recordKeys:Array;
		
		private var _dependencies:CallbackCollection = newDisposableChild(this, CallbackCollection);
		
		private var _taskType:int = -1;
		
		
		public function dispose():void
		{
			_plotter = null;
			_sectionName= "";
			_sectionList = null;
			_layerSettings = null;
			
		}
		
		public function get taskType():int { return _taskType; }
		public function get sectionList():LinkableHashMap { return _sectionList; }
		public function get sectionName():String { return _sectionName; }
		
		
		/**
		 * When this is set to true, the async task will be paused.
		 */
		public var delayAsyncTask:Boolean = false;
		/**
		 * These are the IQualifiedKey objects identifying which records should be rendered
		 */
		public function get recordKeys():Array
		{
			return _recordKeys;
		}
		
		/**
		 * This returns true if the layer should be rendered and selectable/probeable
		 * @return true if the layer should be rendered and selectable/probeable
		 */
		private function shouldBeRendered():Boolean
		{
			var visible:Boolean = true;
			
			
			if (!visible && linkableObjectIsBusy(this))
			{
				WeaveAPI.SessionManager.unassignBusyTask(_dependencies);
				
			}
			return visible;
		}
		
		private var _prevBusyGroupTriggerCounter:uint = 0;	
		private var _delayInit:Boolean = false;
		private var _progress:Number = 0;
		private var _pendingInit:Boolean = false;
		private var _iteration:uint = 0;
		private var _iterationStopTime:int;
		private var _pendingKeys:Array;
		private var _iPendingKey:uint;
		
		
		private function asyncStart():void{
			if (asyncInit())
			{
				WeaveAPI.StageUtils.startTask(this, asyncIterate, WeaveAPI.TASK_PRIORITY_NORMAL, asyncComplete);
				WeaveAPI.SessionManager.assignBusyTask(_dependencies, this);
			}
			
		}
		
		private function asyncInit():Boolean{
			var shouldRender:Boolean = shouldBeRendered();
			if (_delayInit)
			{
				_pendingInit = true;
				return shouldRender;
			}
			_pendingInit = false;
			
			_progress = 0;
			_iteration = 0;
			_iPendingKey = 0;
			if (shouldRender)
			{
				_pendingKeys = _plotter.getSectionRecordKeys(_sectionName,_taskType);
				_recordKeys = [];
				if (_taskType == TASK_TYPE_SUBSET)
				{
					// TEMPORARY SOLUTION until we start using VisToolGroup
					_keyFilter = _plotter.filteredKeySet.keyFilter.getInternalKeyFilter();
					//_keyFilter = _layerSettings.subsetFilter.getInternalKeyFilter();
				}
				else if (_taskType == TASK_TYPE_SELECTION)
					_keyFilter = _layerSettings.selectionFilter.getInternalKeyFilter();
				else if (_taskType == TASK_TYPE_PROBE)
					_keyFilter = _layerSettings.probeFilter.getInternalKeyFilter();
			}else{
				_pendingKeys = null;
				_recordKeys = null;
			}
			return shouldRender;
		}
		
		private function asyncIterate(stopTime:int):Number{
			if (debugMouseDownPause && WeaveAPI.StageUtils.mouseButtonDown)
				return 0;
			
			if (delayAsyncTask)
				return 0;
			
			// if plotter is busy, stop immediately
			if (WeaveAPI.SessionManager.linkableObjectIsBusy(_dependencies))
			{
				if (debug)
					trace(this, 'dependencies are busy');
				// only spend half the time rendering when dependencies are busy
				stopTime = (getTimer() + stopTime) / 2;
			}
			
			/***** initialize *****/
			
			// restart if necessary, initializing variables
			if (_prevBusyGroupTriggerCounter != _dependencies.triggerCounter)
			{
				_prevBusyGroupTriggerCounter = _dependencies.triggerCounter;
				
				// stop immediately if we shouldn't be rendering
				if (!asyncInit())
					return 1;
			}
			/***** prepare keys *****/
			
			// if keys aren't ready yet, prepare keys
			if (_pendingKeys)
			{
				for (; _iPendingKey < _pendingKeys.length; _iPendingKey++)
				{
					// avoid doing too little or too much work per iteration 
					if (getTimer() > stopTime)
						return 0; // not done yet
					
					// next key iteration - add key if included in filter and on screen
					var key:IQualifiedKey = _pendingKeys[_iPendingKey] as IQualifiedKey;
					if (!_keyFilter || _keyFilter.containsKey(key)) // accept all keys if _keyFilter is null
					{
						_recordKeys.push(key);
					}
				}
				if (debug)
					trace(this, 'recordKeys', _recordKeys.length);
				
				// done with keys
				_pendingKeys = null;
			}
			
			/***** draw *****/
			
			// next draw iteration
			_iterationStopTime = stopTime;
			
			while (_progress < 1 && getTimer() < stopTime)
			{
				// delay asyncInit() while calling plotter function in case it triggers callbacks
				_delayInit = true;
				
				if (debug)
					trace(this, 'before iteration', _iteration, 'recordKeys', recordKeys.length);
				_progress = _plotter.renderRecordAsyncIteration(this);
				if (debug)
					trace(this, 'after iteration', _iteration, 'progress', _progress, 'recordKeys', recordKeys.length);
				
				_delayInit = false;
				
				if (_pendingInit)
				{
					// if we get here it means the plotter draw function triggered callbacks
					// and we need to restart the async task.
					if (asyncInit())
						return asyncIterate(stopTime);
					else
						return 1;
				}
				else
					_iteration++; // prepare for next iteration
			}
			
			return _progress;
			
		}
		
		private function asyncComplete():void
		{
			if (debug)
				trace(this, 'rendering completed');
			_progress = 0;
			// don't do anything else if dependencies are busy
			if (WeaveAPI.SessionManager.linkableObjectIsBusy(_dependencies))
				return;
			
			// busy task gets unassigned when the render completed successfully
			WeaveAPI.SessionManager.unassignBusyTask(_dependencies);
			
			_plotter.currentKey = null;
			if (shouldBeRendered())
			{
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		
		private var _keyToSortIndex:Dictionary;
		private function handleKeySetChange():void
		{
			// save a lookup from key to sorted index
			// this is very fast
			_keyToSortIndex = new Dictionary(true);
			var sorted:Array = _plotter.filteredKeySet.keys;
			for (var i:int = sorted.length; i--;)
				_keyToSortIndex[sorted[i]] = i;
		}
	}
}