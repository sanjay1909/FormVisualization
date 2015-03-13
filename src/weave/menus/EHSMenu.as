/*
Weave (Web-based Analysis and Visualization Environment)
Copyright (C) 2008-2011 University of Massachusetts Lowell

This file is a part of Weave.

Weave is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License, Version 3,
as published by the Free Software Foundation.

Weave is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.menus
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.controls.Menu;
	import mx.printing.FlexPrintJob;
	
	import spark.components.DataGrid;
	import spark.components.Menu;
	
	import ehs.EHS;
	import ehs.ui.admin.DatabaseTool;
	
	import print.IServerManager;
	import print.Page;
	import print.Printer;
	import print.ServerManager;
	
	import weave.Weave;
	import weave.api.reportError;
	import weave.ui.DraggablePanel;
	
	public class EHSMenu extends weave.menus.WeaveMenuItem
	{
		
		public function loadFile(url:Object, callback:Object = null, noCacheHack:Boolean = false):void
		{
			WeaveAPI.topLevelApplication['visApp']['loadFile'].apply(null,arguments);
		}
		
		public function EHSMenu()
		{
			super({
				shown: EHS.properties.enableEHSMenu,
				label: lang("Developer Tools"),
				children: [
					/*{
						shown: EHS.properties.enableLoadDatabase,
						label: lang("Show Database"),
						click: DatabaseTool.openTool 
					},{
						shown: EHS.properties.enableTemplateEditing,
						label: lang("Edit Template"),
						click: function ():void {
							var pm:ServerManager = WeaveAPI.ClassRegistry.getSingletonInstance(IServerManager) as ServerManager;
							loadFile(pm.inspectorInfo.templatePath.value, activateEditing,true);							
						}
					},{
						shown:  EHS.properties.enableEditingTermination,
						label: lang("Close Editing"),
						click: function ():void { 
								
							EHS.properties.enableEditingTermination.value = false;
							EHS.properties.enableTemplateEditing.value = true;
							if(EHS.properties.editingMode.value){
								EHS.properties.saveTemplateToServer();
							}
						}
					},{
						shown:  EHS.properties.enableLogout,
						label: lang("Log out"),
						click: function ():void { 
							EHS.properties.enableEditingTermination.value = false;
							EHS.properties.enableTemplateEditing.value = true;
							if(EHS.properties.editingMode.value){
								EHS.properties.saveTemplateToServer();
							}							
							var panel:DraggablePanel;
							for each (panel in WeaveAPI.globalHashMap.getObjects(DraggablePanel))				
							panel.removePanel();
							
							DatabaseTool.closeTool();
							EHS.properties.service.logout(); 
						}
					}
					
					,*/
					{
						shown:  EHS.properties.enableDebug,
						label: lang("Parent-Child Map"),
						click: function ():void { 
							EHS.properties.launchDebugWindow();
						}
					}
					/*,
					{
						shown:  EHS.properties.enableLogout,
						label: lang("Print"),
						click:function ():void { 
							Weave.root.requestObject("Printer",Printer,false);
						}
					}*/
				]
			});
		}
		
		private function activateEditing():void{
			EHS.properties.editingMode.value = true;
			EHS.properties.enableEditingTermination.value = true;
			EHS.properties.enableTemplateEditing.value = false;
		}
	}
}