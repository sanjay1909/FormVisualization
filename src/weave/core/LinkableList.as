package weave.core
{
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.IList;
	import mx.core.IPropertyChangeNotifier;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	import mx.utils.UIDUtil;
	
	import weave.api.registerLinkableChild;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	
	public class LinkableList extends EventDispatcher implements IList, ILinkableObject ,IPropertyChangeNotifier
	{
		
		public const list:LinkableHashMap = registerLinkableChild(this,new LinkableHashMap());
		
		/**
		 *  @private
		 *  Used for accessing localized Error messages.
		 */
		private var resourceManager:IResourceManager =	ResourceManager.getInstance();
		
		public function LinkableList()
		{
			list.childListCallbacks.addImmediateCallback(this,updateView,false,true);
		}
		
		//----------------------------------
		// uid -- mx.core.IPropertyChangeNotifier
		//----------------------------------
		
		/**
		 *  @private
		 *  Storage for the UID String. 
		 */
		private var _uid:String;
		
		/**
		 *  Provides access to the unique id for this list.
		 *  
		 *  @return String representing the internal uid. 
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */  
		public function get uid():String
		{
			if (!_uid) {
				_uid = UIDUtil.createUID();
			}
			return _uid;
		}
		
		public function set uid(value:String):void
		{
			_uid = value;
		}
		
		
		
		[Bindable("collectionChange")]
		public function get length():int
		{
			return list.getNames().length;
		}
		//required to remeber the index to remove object , when called from session change callback
		private const itemIndexMap:Dictionary = new Dictionary();
		
		//wrapped linkableobject map
		private const linkableObjectMap:Dictionary = new Dictionary();
		
		public function addItem(item:Object):void
		{
			var lo:ICallbackCollection  = list.requestObject("",item as Class,false) as ICallbackCollection;
		}
		
		
		
		private var currentIndex:int = -1;
		public function addItemAt(item:Object, index:int):void
		{
			currentIndex = index;
			list.delayCallbacks();
			var lo:ILinkableObject = list.requestObject("",item as Class,false);
			var name:String = list.getName(lo);		
			var names:Array = list.getNames();
			
			var index:int = names.indexOf(name);
			names.splice(index, 1);
			names.splice(index, 0, name);
			list.setNameOrder(names);
			list.resumeCallbacks();
			
		}
		
		public function getItemAt(index:int, prefetch:int=0):Object
		{
			if (index < 0 || index >= length)
			{
				var message:String = resourceManager.getString(
					"collections", "outOfBounds", [ index ]);
				throw new RangeError(message);
			}
			var objects:Array = list.getObjects();
			
			return linkableObjectMap[objects[index]];
		}
		
		public function getItemIndex(item:Object):int
		{
			var arr:Array = list.getNames();
			var n:int = arr.length;
			var name:String = list.getName(item.linkableObject);
			for (var i:int = 0; i < n; i++)
			{
				if (arr[i] === name)
					return i;
			}
			return -1;  
			
		}
		
		
		private var removeAllCalled:Boolean = false;
		public function removeAll():void
		{
			removeAllCalled = true;
			list.removeAllObjects();
		}
		
		/**
		 * This function removes all objects from this LinkableHashMap.
		 * @inheritDoc
		 */
		public function dispose():void
		{
			list.dispose();
		}
		
		
		
		public function removeItemAt(index:int):Object
		{
			if (index < 0 || index >= length)
			{
				var message:String = resourceManager.getString("collections", "outOfBounds", [ index ]);
				throw new RangeError(message);
			}
			var names:Array = list.getNames();
			var name:String  = names[index];
			list.removeObject(name);
			return null;
		}
		
		/**
		 *  Place the item at the specified index.  
		 *  If an item was already at that index the new item will replace it and it 
		 *  will be returned.
		 *
		 *  @param  item the new value for the index
		 *  @param  index the index at which to place the item
		 *  @return the item that was replaced, null if none
		 *  @throws RangeError if index is less than 0 or greater than or equal to length
		 */
		
		public function setItemAt(item:Object, index:int):Object
		{
			/*if(!item is ILinkableObject){
				reportError("Item is not a Ilinakable Object");
				return null; 
			}
			if (index < 0 || index >= length) 
			{
				var message:String = resourceManager.getString(
					"collections", "outOfBounds", [ index ]);
				throw new RangeError(message);
			}
			
			list.delayCallbacks();			
			removeItemAt(index);
			addItemAt(item,index);
			list.resumeCallbacks();*/
			return item;
		}
		
		public function toArray():Array
		{
			return list.getObjects();
		}
		
		public function itemUpdated(item:Object, property:Object=null, oldValue:Object=null, newValue:Object=null):void
		{
			var event:PropertyChangeEvent =	new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE);
			
			event.kind = PropertyChangeEventKind.UPDATE;
			event.source = item;
			event.property = property;
			event.oldValue = oldValue;
			event.newValue = newValue;
			itemUpdateHandler(event);   
		}
		/**
		 *  Called when any of the contained items in the list dispatch an
		 *  ObjectChange event.  
		 *  Wraps it in a <code>CollectionEventKind.UPDATE</code> object.
		 *
		 *  @param event The event object for the ObjectChange event.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */    
		protected function itemUpdateHandler(event:PropertyChangeEvent):void
		{
			internalDispatchEvent(CollectionEventKind.UPDATE, event);
			// need to dispatch object event now
			if (hasEventListener(PropertyChangeEvent.PROPERTY_CHANGE))
			{
				var objEvent:PropertyChangeEvent = PropertyChangeEvent(event.clone());
				var index:uint = getItemIndex(event.target);
				objEvent.property = index.toString() + "." + event.property;
				dispatchEvent(objEvent);
			}
		}
		
		private function updateView():void{
			var linkableObject:ILinkableObject;
			if(list.childListCallbacks.lastObjectAdded){
				linkableObject = list.childListCallbacks.lastObjectAdded;	
				// Object added through addItem will have current index = -1
				if(currentIndex == -1){
					currentIndex = length - 1; 
				}
				internalDispatchEvent(CollectionEventKind.ADD, linkableObject, currentIndex);
				currentIndex = -1;
			}
			if(removeAllCalled){
				removeAllCalled = false;
				internalDispatchEvent(CollectionEventKind.RESET);
			}
			if(list.childListCallbacks.lastObjectRemoved){
				linkableObject = list.childListCallbacks.lastObjectRemoved;
				var obj:* = linkableObjectMap[linkableObject];				
				if(!removeAllCalled){
					internalDispatchEvent(CollectionEventKind.REMOVE, linkableObject , itemIndexMap[obj]);					
				}
				delete itemIndexMap[obj];
				//updateIndex();
			}
			
		}
		
		// index value of removed object called from session callback 
		// needs to be updated
		private function updateIndex():void{
			var objects:Array = list.getObjects();
			for(var i:int = 0; i < objects.length; i++){
				itemIndexMap[linkableObjectMap[objects[i]]] = i;
			}
		}
	
		
		/**
		 *  Dispatches a collection event with the specified information.
		 *
		 *  @param kind String indicates what the kind property of the event should be
		 *  @param item Object reference to the item that was added or removed
		 *  @param location int indicating where in the source the item was added.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 9
		 *  @playerversion AIR 1.1
		 *  @productversion Flex 3
		 */
		private function internalDispatchEvent(kind:String, item:Object = null, location:int = -1):void
		{
			var object:*;
			if(kind == CollectionEventKind.ADD ){
				object = {edit : false , linkableObject: item };
				itemIndexMap[object] = location;
				linkableObjectMap[item] = object;
			}
			else{
				object = item;
			}
			if (hasEventListener(CollectionEvent.COLLECTION_CHANGE))
			{
				var event:CollectionEvent =	new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
				event.kind = kind;
				event.items.push(object);
				trace(item);
				trace(location);
				event.location = location;
				dispatchEvent(event);
			}
			
			// now dispatch a complementary PropertyChangeEvent
			if (hasEventListener(PropertyChangeEvent.PROPERTY_CHANGE) && 	(kind == CollectionEventKind.ADD || kind == CollectionEventKind.REMOVE))
			{
				var objEvent:PropertyChangeEvent =	new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE);
				objEvent.property = location;
				if (kind == CollectionEventKind.ADD)
					objEvent.newValue = object;
				else
					objEvent.oldValue = object;
				dispatchEvent(objEvent);
			}
		}
		
		
	
		
		
		
		
	}
}