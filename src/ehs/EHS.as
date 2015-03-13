package ehs
{
	import ehs.form.FormTool;
	
	import weave.Weave;
	import weave.api.core.ILinkableHashMap;
	import weave.data.DataSources.CSVDataSource;

	public class EHS
	{
		public function EHS()
		{
		}
		
		public static const DEFAULT_EHS_PROPERTIES:String = "EHSProperties";
		public static const DEFAULT_DATASOURCE:String = "FormDataSource";
		
		
		/**
		 * This function gets the EHSProperties object from the root of Weave.
		 */
		public static function get properties():EHSProperties
		{
			return root.getObject(DEFAULT_EHS_PROPERTIES) as EHSProperties;
		}
		
		
		/**
		 * This function gets the EHSProperties object from the root of Weave.
		 */
		public static function get dataSource():CSVDataSource
		{
			return root.getObject(DEFAULT_DATASOURCE) as CSVDataSource;
		}
		
		private static var _root:ILinkableHashMap = null; // root object of Weave
		
		public static function get root():ILinkableHashMap
		{
			if (_root == null)
			{
				_root = WeaveAPI.globalHashMap;
				createDefaultObjects(_root);
				//_history = new SessionStateLog(_root, 100);
			}
			return _root;
		}
		
		private static function createDefaultObjects(target:ILinkableHashMap):void
		{
			Weave.properties.getToolToggle(InspectionTool);
			Weave.properties.getToolToggle(FormTool);
			Weave.properties.getToolToggle(SurveyTool);
			target.requestObject(DEFAULT_EHS_PROPERTIES, EHSProperties, true);
			var csvDS:CSVDataSource = target.requestObject(DEFAULT_DATASOURCE, CSVDataSource, false);
			//csvDS.url.value = null;
			//csvDS.attributeHierarchy.value = null;
			csvDS.keyType.value = DEFAULT_DATASOURCE;
			
			Weave.history.clearHistory();
		}
		
		/**
		 * Used as storage for last loaded session history file name.
		 */		
		//public static var fileName:String = generateFileName();
		
		/*private static function generateFileName():String
		{
			var pm:ServerManager = WeaveAPI.getSingletonInstance(IServerManager) as ServerManager;
			return pm.getFileName();
		}*/
		
	}
}