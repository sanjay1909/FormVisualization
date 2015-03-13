package print
{
	import mx.core.IUIComponent;
	import mx.core.IVisualElement;
	
	import weave.api.registerLinkableChild;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableVariable;
	import weave.core.LinkableWatcher;
	import weave.core.SessionManager;
	
	public class PageManager implements ILinkableObject
	{
		public function PageManager()
		{
			contents.childListCallbacks.addImmediateCallback(this, handleContentsList);
			contentSettings.childListCallbacks.addImmediateCallback(this,handleSettingsList);
		}
		
		
		
		// Will contain TargetPath from GlobalHasMap
		// If the targetPath Object is not an UI then based on it UI will be provided for That
		//public const contents:LinkableHashMap = registerLinkableChild(this,new LinkableHashMap());
		
		// Will contain TargetPath from GlobalHasMap
		// If the targetPath Object is not an UI then based on it UI will be provided for That
		public const contents:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(LinkableVariable));
		public const contentSettings:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(ContentSettings));
		
		private function handleContentsList():void{
			contents.delayCallbacks();
			contentSettings.delayCallbacks();
			
			// when content is removed, remove settings
			var oldName:String = contents.childListCallbacks.lastNameRemoved;
			if (oldName)
			{
				/*delete _name_to_SpatialIndex[oldName];
				delete _name_to_PlotTask_Array[oldName];*/
				contentSettings.removeObject(oldName);
			}
			
			var newName:String = contents.childListCallbacks.lastNameAdded;
			if (newName)
			{
				var content:LinkableVariable = contents.childListCallbacks.lastObjectAdded as LinkableVariable;
				var settings:ContentSettings = contentSettings.requestObject(newName, ContentSettings, contents.objectIsLocked(newName));
				
				placeContents(content,settings);
				
				
				//var spatialIndex:SpatialIndex = _name_to_SpatialIndex[newName] = newDisposableChild(newPlotter, SpatialIndex);
				//var tasks:Array = _name_to_PlotTask_Array[newName] = [];
				/*for each (var taskType:int in [PlotTask.TASK_TYPE_SUBSET, PlotTask.TASK_TYPE_SELECTION, PlotTask.TASK_TYPE_PROBE])
				{
					var plotTask:PlotTask = new PlotTask(taskType, newPlotter, spatialIndex, zoomBounds, settings);
					registerDisposableChild(newPlotter, plotTask); // plotter is owner of task
					registerLinkableChild(this, plotTask); // task affects busy status of PlotManager
					tasks.push(plotTask);
					// set initial size
					plotTask.setBitmapDataSize(_unscaledWidth, _unscaledHeight);
					
					// when the plot task triggers callbacks, we need to render the layered visualization
					getCallbackCollection(plotTask).addImmediateCallback(this, refreshLayers);
				}*/
				//setupBitmapFilters(newPlotter, settings, tasks[0], tasks[1], tasks[2]);
				// when spatial index is recreated, we need to update zoom
				//spatialIndex.addImmediateCallback(this, updateZoom);
				
				
			}
			
			contentSettings.setNameOrder(contents.getNames());
			
			contents.resumeCallbacks();
			contentSettings.resumeCallbacks();
			
		}
		
		
		private function handleSettingsList():void
		{
			// when settings are removed, remove plotter
			var oldName:String = contentSettings.childListCallbacks.lastNameRemoved;
			contents.removeObject(oldName);
			contents.setNameOrder(contentSettings.getNames());
		}
		
		private function placeContents(content:LinkableVariable,settings:ContentSettings):void{
			var contentPath:Array = content.getSessionState() as Array;
			var sm:SessionManager = WeaveAPI.SessionManager as SessionManager;
			var obj:ILinkableObject = sm.getObject(WeaveAPI.globalHashMap, contentPath);
			if(obj){
				settings.height.value =  (obj as IUIComponent).height;
				settings.width.value = (obj as IUIComponent).width;
			}
			
			
		}
		
		
	}
}