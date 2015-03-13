package ehs.ui
{
	import mx.events.FlexEvent;
	
	import spark.components.FormItem;
	import spark.components.IItemRenderer;
	
	public class FormItemRenderer extends FormItem implements IItemRenderer
	{
		public function FormItemRenderer()
		{
			//TODO: implement function
			super();
			
		}
		
		private var _data:Object;
		[Bindable("dataChange")]
		public function get data():Object { return _data; }
		public function set data(value:Object):void {
			_data = value;
					
			if (hasEventListener(FlexEvent.DATA_CHANGE))
				dispatchEvent(new FlexEvent(FlexEvent.DATA_CHANGE));
		}
		
		private var _itemIndex:int;
		public function get itemIndex():int { return _itemIndex; }
		public function set itemIndex(value:int):void {
			if (value == _itemIndex) return;
			
			_itemIndex = value;
			invalidateDisplayList();
		}
		
				
		private var _selected:Boolean = false;
		public function get selected():Boolean { return _selected; }
		public function set selected(value:Boolean):void {
			if (value != _selected) {
				_selected = value;
				invalidateDisplayList();
			}
		}
		
		public function get dragging():Boolean { return false; }
		public function set dragging(value:Boolean):void { }
		
		public function get showsCaret():Boolean { return false; }
		public function set showsCaret(value:Boolean):void { }
		
		
	}
}