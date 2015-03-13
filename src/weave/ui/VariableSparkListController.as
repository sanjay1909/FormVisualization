package weave.ui
{
	
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.core.IUIComponent;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	
	import spark.components.List;
	import spark.layouts.VerticalLayout;
	import spark.layouts.supportClasses.DropLocation;
	import spark.layouts.supportClasses.LayoutBase;
	
	import weave.api.getCallbackCollection;
	import weave.api.newLinkableChild;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableWatcher;

	public class VariableSparkListController implements ILinkableObject
	{
		public function VariableSparkListController()
		{
		}
		
		private var _editor:List;
		private var _layout:LayoutBase = new VerticalLayout();
		private const _hashMapWatcher:LinkableWatcher = newLinkableChild(this, LinkableWatcher, refreshLabels, true);
		private const _dynamicObjectWatcher:LinkableWatcher = newLinkableChild(this, LinkableWatcher, updateDataProvider, true);
		private const _childListWatcher:LinkableWatcher = newLinkableChild(this, LinkableWatcher, updateDataProvider);
		private var _labelFunction:Function = null;
		private var _filterFunction:Function = null;
		private var _reverse:Boolean = false;
		
		
		public function dispose():void
		{
			view = null;
			hashMap = null;
			//dynamicObject = null;
		}
		
		private function maxVerticalScrollPosition():Number
		{
			var maxVSP:Number = (_editor.dataGroup.contentHeight) - (_editor.dataGroup.height) ;
			return maxVSP;
		}
		
		public function get view():List
		{
			return _editor;
		}
		
		public function get layout():LayoutBase
		{
			return _layout;
		}
		
		
		
		/**
		 * 
		 * @param editor This can be either a List or a DataGrid.
		 */
		public function set view(editor:List):void
		{
			if (_editor == editor)
				return;
			
			
			if (_editor)
			{
				_editor.removeEventListener(DragEvent.DRAG_OVER, dragOverHandler);
				_editor.removeEventListener(DragEvent.DRAG_DROP, dragDropHandler);
				_editor.removeEventListener(DragEvent.DRAG_COMPLETE, dragCompleteHandler);
				_editor.removeEventListener(DragEvent.DRAG_ENTER, dragEnterCaptureHandler, true);				
			}
			
			_editor = editor;
			
			if (_editor)
			{
				_editor.dragEnabled = true;
				_editor.dropEnabled = true;
				_editor.dragMoveEnabled = true;
				//_editor.allowMultipleSelection = _allowMultipleSelection;
				//_editor.showDataTips = false;
				_editor.addEventListener(DragEvent.DRAG_OVER, dragOverHandler);
				_editor.addEventListener(DragEvent.DRAG_DROP, dragDropHandler);
				_editor.addEventListener(DragEvent.DRAG_COMPLETE, dragCompleteHandler);
				_editor.addEventListener(DragEvent.DRAG_ENTER, dragEnterCaptureHandler, true);
				_editor.layout = layout;				
			}
			updateDataProvider();
		}
		
		private function updateDataProvider():void
		{
			if (!_editor)
				return;
			
			var vsp:int = layout.verticalScrollPosition;
			var selectedItems:Vector.<Object> = _editor.selectedItems;
			
			 if (hashMap)
			{
				//setNameColumnHeader();
				var objects:Array = hashMap.getObjects();
				if (_filterFunction != null)
					objects = objects.filter(_filterFunction);
				if (_reverse)
					objects = objects.reverse();
				_editor.dataProvider = new ArrayCollection(objects);
			}
			else
				_editor.dataProvider = null;
			
						
			var view:ICollectionView = _editor.dataProvider as ICollectionView;
			if (view)
				view.refresh();
			
			if (selectedItems && selectedItems.length)
			{
				_editor.validateProperties();
				if (vsp >= 0 && vsp <= maxVerticalScrollPosition())
					layout.verticalScrollPosition = vsp;
				_editor.selectedItems = selectedItems;
			}
			
			getCallbackCollection(this).triggerCallbacks();
		}
		private function updateHashMapNameOrder():void
		{
			if (!_editor)
				return;
			
			_editor.validateNow();
			
			if (hashMap)
			{
				// update object map name order based on what is in the data provider
				var newNameOrder:Array = [];
				for (var i:int = 0; i < _editor.dataProvider.length; i++)
				{
					var object:ILinkableObject = _editor.dataProvider[i] as ILinkableObject;
					if (object)
						newNameOrder[i] = hashMap.getName(object);
				}
				if (_reverse)
					newNameOrder.reverse();
				hashMap.setNameOrder(newNameOrder);
			}
		}
		
		
		// called when something is being dragged on top of this list
		private function dragOverHandler(event:DragEvent):void
		{
			if (dragSourceIsAcceptable(event))
				DragManager.showFeedback(DragManager.MOVE);
			else
				DragManager.showFeedback(DragManager.NONE);
		}
		
		// called when something is dropped into this list
		private function dragDropHandler(event:DragEvent):void
		{
			//hides the drop visual lines
			(event.currentTarget as List).layout.hideDropIndicator();
			//_editor.mx_internal::resetDragScrolling(); // if we don't do this, list will scroll when mouse moves even when not dragging something
			
			if (event.dragInitiator == _editor)
			{
				event.action = DragManager.MOVE;
				_editor.callLater(updateHashMapNameOrder);
			}
			else
			{
				event.preventDefault();
				
				var items:Array = event.dragSource.dataForFormat("items") as Array;
				if (hashMap)
				{
					var prevNames:Array = hashMap.getNames();
					var newNames:Array = [];
					var dropLocation:DropLocation = layout.calculateDropLocation(event);
					var dropIndex:int = dropLocation.dropIndex;
					var newObject:ILinkableObject;
					
					// copy items in reverse order because selectedItems is already reversed
					for (var i:int = items.length - 1; i >= 0; i--)
					{
						var object:ILinkableObject = items[i] as ILinkableObject;
						if (object && hashMap.getName(object) == null)
						{
							newObject = hashMap.requestObjectCopy(null, object);
							newNames.push(hashMap.getName(newObject));
						}
					}
					
					// insert new names inside prev names list and save the new name order
					var args:Array = newNames;
					newNames.unshift(dropIndex, 0);
					prevNames.splice.apply(null, args);
					hashMap.setNameOrder(prevNames);
					
				}
			}
		}
		
		private function dragSourceIsAcceptable(event:DragEvent):Boolean
		{
			if (event.dragSource.hasFormat("items"))
			{
				var items:Array = event.dragSource.dataForFormat("items") as Array;
				for each (var item:Object in items)
				{
					if (item is ILinkableObject)
						return true;
				}
			}
			return false;
		}
		
		// called when something is dragged on top of this list
		private function dragEnterCaptureHandler(event:DragEvent):void
		{
			if (dragSourceIsAcceptable(event))
				DragManager.acceptDragDrop(event.currentTarget as IUIComponent);
			event.preventDefault();
		}
		
		public var defaultDragAction:String = DragManager.COPY;
		
		// called when something in this list is dragged and dropped somewhere else
		private function dragCompleteHandler(event:DragEvent):void
		{
			if (event.shiftKey)
				event.action = DragManager.MOVE;
			else if (event.ctrlKey)
				event.action = DragManager.COPY;
			else
				event.action = defaultDragAction;
			
			_editor.callLater(removeObjectsMissingFromDataProvider);
		}
		
		private function removeObjectsMissingFromDataProvider():void
		{
			if (!_editor)
				return;
			
			if (hashMap)
			{
				var objects:Array = hashMap.getObjects();
				for each (var object:ILinkableObject in objects)
				{
					if(!(_editor.dataProvider as ArrayCollection).contains(object))
						hashMap.removeObject(hashMap.getName(object));
				}
			}
			
		}
		
		public function get hashMap():ILinkableHashMap
		{
			return _hashMapWatcher.target as ILinkableHashMap;
		}
		
		public function set hashMap(value:ILinkableHashMap):void
		{
			_hashMapWatcher.target = value;
			_childListWatcher.target = value && value.childListCallbacks;
		}
		
		private function refreshLabels():void
		{
			if (_editor)
				_editor.labelFunction = _editor.labelFunction; // this refreshes the labels
		}
	}
}