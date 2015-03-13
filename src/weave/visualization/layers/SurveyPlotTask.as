package weave.visualization.layers
{
	import flash.display.BitmapData;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import avmplus.getQualifiedClassName;
	
	import weave.api.getCallbackCollection;
	import weave.api.linkableObjectIsBusy;
	import weave.api.newDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IKeyFilter;
	import weave.api.primitives.IBounds2D;
	import weave.api.ui.IPlotTask;
	import weave.api.ui.IPlotter;
	import weave.compiler.StandardLib;
	import weave.core.CallbackCollection;
	import weave.core.LinkableHashMap;
	import weave.visualization.plotters.SurveyPloter;
	
	public class SurveyPlotTask implements IPlotTask, ILinkableObject, IDisposableObject
	{
		public static var debug:Boolean = false;
		public static var debugMouseDownPause:Boolean = false;
		public static var debugIgnoreSpatialIndex:Boolean = false;
		
		public function toString():String
		{
			var type:String = 'section';
			if (debug)
			{
				var str:String = [
					debugId(_plotter),
					debugId(this),
					type
				].join('-');
				
				if (linkableObjectIsBusy(this))
					str += '(busy)';
				return str;
			}
			return StandardLib.substitute('PlotTask({0}, {1})', type, getQualifiedClassName(_plotter).split(':').pop());
		}
		
		//public static const TASK_TYPE_SUBSET:int = 0;
		//public static const	TASK_TYPE_SELECTION:int = 1;
		//public static const TASK_TYPE_PROBE:int = 2;
		public static const TASK_TYPE_SECTION:int = 3;
		
		public function SurveyPlotTask(taskType:int, plotter:IPlotter,sectionName:String,sectionList:LinkableHashMap,layerSettings:LayerSettings)
		{
			_taskType = taskType;
			_plotter = plotter;
			_sectionName = sectionName;
			_layerSettings = layerSettings;
			_sectionList = sectionList;
			
			
			// _dependencies is used as the parent so we can check its busy status with a single function call.
			var list:Array = [_plotter,_layerSettings];// we dont want to render when filterkey changes , list UI will take care of it
			for each (var dependency:ILinkableObject in list)
				registerLinkableChild(_dependencies, dependency);
			
			
			_dependencies.addImmediateCallback(this, asyncStart, true);
			
		}
		
		
		public function dispose():void
		{
			_plotter = null;
			_layerSettings = null;
			_sectionName ='';
			_sectionList = null;
		}
		
		public function get taskType():int { return _taskType; }
		
		public function get progress():Number { return _progress; }
		
		/**
		 * When this is set to true, the async task will be paused.
		 */
		internal var delayAsyncTask:Boolean = false;
		
		private var _dependencies:CallbackCollection = newDisposableChild(this, CallbackCollection);
		private var _prevBusyGroupTriggerCounter:uint = 0;
		
		private var _taskType:int = -1;
		private var _plotter:IPlotter = null;
		private var _layerSettings:LayerSettings;
		private var _sectionName:String = '';
		private var _sectionList:LinkableHashMap = null;
		
		public function get sectionList():LinkableHashMap { return _sectionList; }
		public function get sectionName():String { return _sectionName; }
		
		private var _iteration:uint = 0;
		private var _iterationStopTime:int;
		private var _keyFilter:IKeyFilter;
		private var _recordKeys:Array;
		private var _asyncState:Object = {};
		private var _pendingKeys:Array;
		private var _iPendingKey:uint;
		private var _progress:Number = 0;
		private var _delayInit:Boolean = false;
		private var _pendingInit:Boolean = false;
		
		
		
		/**
		 * This returns true if the layer should be rendered and selectable/probeable
		 * @return true if the layer should be rendered and selectable/probeable
		 */
		private function shouldBeRendered():Boolean
		{
			var visible:Boolean = true;
			if (!_layerSettings.visible.value)
			{
				if (debug)
					trace(this, 'visible=false');
				visible = false;
			}
			
			if (!visible && linkableObjectIsBusy(this))
			{
				WeaveAPI.SessionManager.unassignBusyTask(_dependencies);
			}
			return visible;
		}
		
		
		private function asyncStart():void
		{
			if (asyncInit())
			{
				if (debug)
					trace(this, 'begin async rendering');
				// normal priority because rendering is not often a prerequisite for other tasks
				WeaveAPI.StageUtils.startTask(this, asyncIterate, WeaveAPI.TASK_PRIORITY_NORMAL, asyncComplete);
				
				// assign secondary busy task in case async task gets cancelled due to busy dependencies
				WeaveAPI.SessionManager.assignBusyTask(_dependencies, this);
			}
			else
			{
				if (debug)
					trace(this, 'should not be rendered');
			}
		}
		
		/**
		 * @return true if shouldBeRendered() returns true.
		 */
		private function asyncInit():Boolean
		{
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
				_recordKeys = (_plotter as SurveyPloter).getSectionRecordKeys(_sectionName);
				//_recordKeys = [];				
				
				if (debug)
					trace(this, 'clear');
			}
			else
			{
				
				//_pendingKeys = null;
				_recordKeys = null;
			}
			return shouldRender;
		}
		
		private function asyncIterate(stopTime:int):Number
		{
			if (debugMouseDownPause && WeaveAPI.StageUtils.mouseButtonDown)
				return 0;
			
			if (delayAsyncTask)
				return 0;
			
			// if plotter is busy, stop immediately
			if (WeaveAPI.SessionManager.linkableObjectIsBusy(_dependencies))
			{
				if (debug)
					trace(this, 'dependencies are busy');
				if (!debugIgnoreSpatialIndex)
					return 1;
				
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
			/*if (_pendingKeys)
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
			}*/
			
			/***** draw *****/
			
			// next draw iteration
			_iterationStopTime = stopTime;
			
			while (_progress < 1 && getTimer() < stopTime)
			{
				// delay asyncInit() while calling plotter function in case it triggers callbacks
				_delayInit = true;
				
				if (debug)
					trace(this, 'before iteration', _iteration, 'recordKeys', recordKeys.length);
				_progress = _plotter.drawPlotAsyncIteration(this);
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
			
			if (shouldBeRendered())
			{
				// BitmapData has been completely rendered, so update completedBitmap and completedDataBounds
				
				getCallbackCollection(this).triggerCallbacks();
			}
		}
		
		/***************************
		 **  IPlotTask interface  **
		 ***************************/
		/**
		 * This is the off-screen buffer, which may change
		 */
		public function get buffer():BitmapData
		{
			return null;
		}
		
		/**
		 * This specifies the range of data to be rendered
		 */
		public function get dataBounds():IBounds2D
		{
			//_dataBounds
			return null;
		}
		
		/**
		 * This specifies the pixel range where the graphics should be rendered
		 */
		public function get screenBounds():IBounds2D
		{
			//_screenBounds
			return null;
		}
		
		public function get recordKeys():Array
		{
			return _recordKeys;
		}
		
		public function get iteration():uint
		{
			return _iteration;
		}
		
		public function get iterationStopTime():int
		{
			return _iterationStopTime;
		}
		
		public function get asyncState():Object
		{
			return _asyncState;
		}
		
		public function set asyncState(value:Object):void
		{
			_asyncState = value
		}
	}
}