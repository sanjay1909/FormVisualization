

package ehs.ui.admin
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import spark.components.TextInput;
	import spark.components.gridClasses.GridColumn;
	import spark.events.TextOperationEvent;

	public class GridColumnTextFilter extends GridColumnFilterControl
	{
		public function GridColumnTextFilter(column:GridColumn)
		{
			super(column);			
			searchText.addEventListener(TextOperationEvent.CHANGE,searchTextChangeHandler);
			searchText.prompt = column.headerText;
		}
		
		
		
		//uiiiiiiiiiiiiiiiiiiiiiiiiiiiii
		private const searchText:TextInput = new TextInput();
		
		override protected function createChildren():void{
			this.addElement(searchText);
			super.createChildren();
		}
		
		
		//addskin suppor to have clear button over text itself
		protected function clearHandler(event:MouseEvent):void
		{
			searchText.text='';
			if(searchListCollection!=null){
				searchListCollection.filterFunction=null;
				searchListCollection.refresh();
			}
		}
		
		protected function searchTextChangeHandler(event:Event):void
		{
			doSearch();
		}
		
		//exposed public method to be called to force search from other pages
		public function doSearch():void
		{
			if(searchListCollection!=null){
				searchListCollection.filterFunction=filterFunction;
				searchListCollection.refresh();
			}
		}
		
		override protected function filterFunction(item:Object):Boolean
		{
			if(!gridColumn)
			 	return false;
			if(searchOperation(item,searchText.text)==true){
				return true;
			}			
			//if none of the columns satisfied the filter then you can return false
			return false;        
		}
		
		private function searchOperation(item:Object,searchWord:String):Boolean
		{
			//when the search text is empty show all text
			if(searchWord==''){
				return true;
			}
			
			//for complex object hierarchies walk through the object 
			//get the last string object in the chain you are filtering
			var object:Object=item;
			
			var selectedField:String = gridColumn.dataField;
			
			var tokens:Array = selectedField.split(".");
			
			for(var i:int=0;i<tokens.length;i++){
				//if the object is null at any instance return false
				//since we will not be able to walk down a null object tree
				if(object==null){
					return false;
				}
				object=object[tokens[i]];
			}
			
			//check again if the object is not null
			if(object==null){
				return false;
			}
			
			//do the actual search
			return object.toString().search(new RegExp(searchWord,"i")) > -1;
		}
		
	}
}