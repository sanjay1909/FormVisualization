

package ehs.ui.admin
{
	import mx.collections.ArrayCollection;
	
	import spark.components.Group;
	import spark.components.gridClasses.GridColumn;
	
	public class GridColumnFilterControl extends Group
	{
		public function GridColumnFilterControl(column:GridColumn)
		{
			super();
			gridColumn= column;
		}
		
		//the collection on which the search is to be applied
		[Bindable]
		public var searchListCollection:ArrayCollection;
		
		
		public var gridColumn:GridColumn;
		
		
		// override in sub classes to have seperate implementation
		protected function filterFunction(item:Object):Boolean{
			if(item)
				return true;
			else
				return false;			
		}
	}
}