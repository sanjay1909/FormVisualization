package weave.application
{
	import ehs.EHS;
	
	import print.IServerManager;
	import print.ServerManager;
	
	import weave.core.SessionStateLog;
	import weave.menus.EHSMenu;
	import weave.ui.controlBars.WeaveMenuBar;

	public class VisApp extends VisApplication
	{
		
		/**
		 * Constructor.
		 */
		public function VisApp()
		{
			//SessionStateLog.debug = true;
			super();
			WeaveAPI.ClassRegistry.registerSingletonImplementation(IServerManager,ServerManager);
			
			
			
			//Weave.properties.getToolToggle(BuildingEditor);
			
			WeaveMenuBar.defaultMenus.push( new EHSMenu());
			
		}
		
		
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void{
			EHS.properties.umassLogo.x = visDesktop.width/2 - EHS.properties.umassLogo.width/2;
			EHS.properties.umassLogo.y = visDesktop.height/2 - EHS.properties.umassLogo.height/2;
			visDesktop.addElementAt(EHS.properties.umassLogo,0);
			super.updateDisplayList(unscaledWidth,unscaledHeight);
		}
		
		
	
	
		
		
		
		
		
		
	}
}