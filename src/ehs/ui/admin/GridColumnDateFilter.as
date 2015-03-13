

package ehs.ui.admin
{
	import mx.controls.DateField;
	import mx.controls.Label;
	import mx.events.CalendarLayoutChangeEvent;
	
	import spark.components.HGroup;
	import spark.components.gridClasses.GridColumn;
	import spark.layouts.VerticalLayout;
	
	public class GridColumnDateFilter extends GridColumnFilterControl
	{
		
				
		public function GridColumnDateFilter(column:GridColumn)
		{
			super(column);
			uiInit();
			this.layout = new VerticalLayout();
					
		}
		
		
		override protected function filterFunction(item:Object):Boolean {
			var cDate:Number = Date.parse(item[gridColumn.dataField]);
			
			if (!sDate || !eDate) {
				return true;
			}
			
			if (sDate.selectedDate && eDate.selectedDate) {
				return (sDate.selectedDate.time <= cDate) && (eDate.selectedDate.time >= cDate);
			} else if (sDate.selectedDate) {
				return sDate.selectedDate.time <= cDate;
			} else if (eDate.selectedDate) {
				return eDate.selectedDate.time >= cDate;
			} else {
				return true;
			}
		}
		
		private function triggerFilter(e:CalendarLayoutChangeEvent):void{
			
				if(searchListCollection!=null){
					searchListCollection.filterFunction=filterFunction;
					searchListCollection.refresh();
				}
		}
		
		///uiiiiiiiiiiiiiiiiiii
		private const sDate:DateField = new DateField();
		private const eDate:DateField = new DateField();
		
		private var fromLabel:Label = new Label();
		private var toLabel:Label = new Label();
		
		private var fromHgrp:HGroup = new HGroup();
		private var toHgrp:HGroup = new HGroup();
		override protected function createChildren():void{
			
			this.addElement(fromHgrp);
			this.addElement(toHgrp);
			super.createChildren();
			fromHgrp.addElement(fromLabel);
			fromHgrp.addElement(sDate);
			
			toHgrp.addElement(toLabel);
			toHgrp.addElement(eDate);
			
		}
		
		private function uiInit():void{
			fromLabel.setStyle("textAlign","right");
			fromLabel.text = "From:"
			toLabel.setStyle("textAlign","right");
			toLabel.text = "to:"
			sDate.addEventListener(CalendarLayoutChangeEvent.CHANGE,triggerFilter);
			eDate.addEventListener(CalendarLayoutChangeEvent.CHANGE,triggerFilter);	
		}
	}
}