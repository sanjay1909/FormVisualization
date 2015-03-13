package ehs
{
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	import mx.controls.Image;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	import mx.utils.UIDUtil;
	import mx.utils.URLUtil;
	
	import ehs.data.MenuButtonSettings;
	import ehs.data.SectionSettings;
	import ehs.services.EHSAdminGateway;
	import ehs.ui.FormDataCallout;
	import ehs.ui.ICommentAndImageUI;
	import ehs.ui.InspectionDataCallout;
	
	import print.PrinterContents;
	
	import weave.Weave;
	import weave.api.getCallbackCollection;
	import weave.api.linkBindableProperty;
	import weave.api.linkableObjectIsBusy;
	import weave.api.newDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;
	import weave.core.SessionManager;
	import weave.core.SessionStateLog;
	import weave.core.WeaveArchive;
	import weave.services.DelayedAsyncResponder;
	import weave.services.LocalAsyncService;
	
	public class EHSProperties implements ILinkableObject
	{
		public const service:EHSAdminGateway = registerLinkableChild(this, new EHSAdminGateway("/EHSservice/Gateway.aspx")); 
		public const pdfServiceUrl:LinkableString = registerLinkableChild(this, new LinkableString("http://localhost/EHSservice/create.aspx"));
		public const autoSave:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		
		public static const INSPECTION:String = "inspection";
		public static const FOLLOWUP:String = "followUp";
		public static const CLOSED:String = "closed";
		public static const REPORT:String = "report";
		
		public const mode:LinkableString = registerLinkableChild(this, new LinkableString(INSPECTION));
		public function EHSProperties()
		{
			//csvParser.
			
			umassLogo.source = logoIcon;
			
			linkBindableProperty(service.authenticated, this, 'userHasAuthenticated');
			service.addHook(
				service.login,
				function(connectionName:String, password:String):void
				{
					// not logged in until result comes back
					if (userHasAuthenticated)
						userHasAuthenticated = false;
					
					activeConnectionName = connectionName;
					activePassword = password;
				},
				function(event:ResultEvent, token:Object):void
				{
					// save info
					userHasAuthenticated = true;
					currentUserIsSuperuser = event.result as Boolean;
					
					// refresh lists
					/*service.getWeaveFileNames(false);
					service.getWeaveFileNames(true);
					service.getConnectionNames();
					service.getDatabaseConfigInfo();
					service.getKeyTypes();*/
				}
			);
			
			service.addHook(
				service.logout,
				function():void
				{
					activeConnectionName = "";
					activePassword = "";
					
					
				},
				function(event:ResultEvent, token:Object):void
				{
					// save info
					userHasAuthenticated = false;
					
					// refresh lists
					/*service.getWeaveFileNames(false);
					service.getWeaveFileNames(true);
					service.getConnectionNames();
					service.getDatabaseConfigInfo();
					service.getKeyTypes();*/
				}
			);
			//////////////////////////////
			// Weave client config files
			service.addHook(
				service.saveWeaveFile,
				null,
				function(event:ResultEvent, token:Object):void
				{
					EHSAdminGateway.messageDisplay(null, event.result as String, false);
					
					// refresh lists
					//service.getWeaveFileNames(false);
					//service.getWeaveFileNames(true);
				}
			);
			
			//////////////////////////////
			// ConnectionInfo management
			
			
			//////////////////////////////////
			// DatabaseConfigInfo management
			
			
			/////////////////
			// File uploads
			
			////////////////
			// Data import
			
			
			//////////////////
			// Miscellaneous
			(WeaveAPI.SessionManager as SessionManager).addTreeCallback(this,sendSessionDataToDebugWindow,true);
			//getCallbackCollection(Weave.root).addGroupedCallback();
			
		}
		
		
		
		
		
		[Bindable] public var userHasAuthenticated:Boolean = false;		
		[Bindable] public var currentUserIsSuperuser:Boolean = false;
		
		
		
		[Bindable] public function get activeConnectionName():String
		{
			return service.user;
		}
		public function set activeConnectionName(value:String):void
		{
			if (service.user == value)
				return;
			service.user = value;
			
			// log out and prevent the user from seeing anything while logged out.
			userHasAuthenticated = false;
			currentUserIsSuperuser = false;
			
		}
		[Bindable] public function get activePassword():String
		{
			return service.pass;
		}
		public function set activePassword(value:String):void
		{
			service.pass = value;
		}
		
		[Embed(source="/../ehs/resources/images/UMassLogo.png")]
		public var logoIcon:Class;
		
		public const umassLogo:Image = new Image();
			
		public const popUpUI:ICommentAndImageUI = registerLinkableChild(this, new InspectionDataCallout());
		public const formCallout:FormDataCallout = registerLinkableChild(this, new FormDataCallout());
		
		public const fileID:LinkableString = registerLinkableChild(this, new LinkableString());
		
		
		public const enableEHSMenu:LinkableBoolean = registerLinkableChild(this,new LinkableBoolean(true));
		public const enableLoadDatabase:LinkableBoolean = registerLinkableChild(this,new LinkableBoolean(true));
		public const enableTemplateEditing:LinkableBoolean = registerLinkableChild(this,new LinkableBoolean(true));
		public const enableLogout:LinkableBoolean = registerLinkableChild(this,new LinkableBoolean(true));
		public const enableDebug:LinkableBoolean = registerLinkableChild(this,new LinkableBoolean(true));
		public const enableEditingTermination:LinkableBoolean = registerLinkableChild(this,new LinkableBoolean(false));
		
		public const menuButtonSettings:MenuButtonSettings = registerLinkableChild(this, new MenuButtonSettings());
		public const sectionSettings:SectionSettings = registerLinkableChild(this, new SectionSettings());
		public const menuBackgroundColor:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x36373b));
		
		
		public const buildings:LinkableVariable = registerLinkableChild(this, new LinkableVariable(Array));
		
		
		public const filledSectionData:Dictionary = new Dictionary(true);
		
		public const printerContents:PrinterContents = registerLinkableChild(this, new PrinterContents());
		
		
		//////////////////////////////////////////
		// LocalConnection Code
		
		private static const ADMIN_SESSION_WINDOW_NAME_PREFIX:String = "WeaveAdminSession=";
		
		public function openWeavePopup(fileName:String = null, recover:Boolean = false):void
		{
			var params:Object = {};
			if (fileName)
				params['file'] = fileName;
			if (recover)
				params['recover'] = true;
			JavaScript.exec(
				{
					url: 'Labinspection.html?' + URLUtil.objectToString(params, '&'),
					target: ADMIN_SESSION_WINDOW_NAME_PREFIX + createWeaveSession(),
					windowParams: 'width=1000,height=740,location=0,toolbar=0,menubar=0,resizable=1'
				},
				'window.open(url, target, windowParams);'
			);
		}
		
		
		private var weaveService:LocalAsyncService = null; // the current service object
		// creates a new LocalAsyncService and returns its corresponding connection name.
		private function createWeaveSession():String
		{
			if (weaveService)
			{
				// Attempt close the popup window of the last service that was created.
				//					var token:AsyncToken = weaveService.invokeAsyncMethod('closeWeavePopup');
				//					addAsyncResponder(token, handleCloseWeavePopup, null, weaveService);
				// Keep the service in oldWeaveServices Dictionary because this invocation may fail if the popup window is still loading.
				// This may result in zombie service objects, but it won't matter much.
				// It is important to make sure any existing popup windows can still communicate back to the Admin Console.
				oldWeaveServices[weaveService] = null; // keep a pointer to this old service object until the popup window is closed.
			}
			// create a new service with a new name
			var connectionName:String = UIDUtil.createUID();
			weaveService = new LocalAsyncService(service, true, connectionName);
			return connectionName;
		}
		
		private var oldWeaveServices:Dictionary = new Dictionary(); // the keys are pointers to old service objects
		private function handleCloseWeavePopup(event:ResultEvent, service:LocalAsyncService):void
		{
			trace("handleCloseWeavePopup");
			service.dispose();
			delete oldWeaveServices[service];
		}
		// End of LocalConnection Code
		//////////////////////////////////////////
		public const editingMode:LinkableBoolean = registerLinkableChild(this,new LinkableBoolean(false));
		public const followUpMode:LinkableBoolean = registerLinkableChild(this,new LinkableBoolean(false));
		
		public function saveTemplateToServer(event:MouseEvent = null):void
		{	
			EHS.properties.editingMode.value = false;				
			Weave.history.clearHistory();
			trace("clear hsitory called");
			var content:ByteArray = WeaveArchive.createWeaveFileContent();	
			var adG:EHSAdminGateway =EHS.properties.service;
			var asyncToken:AsyncToken = adG.saveWeaveFile(content as ByteArray,'default.weave',true);			
			asyncToken.addResponder(new DelayedAsyncResponder(saveSuccessHandler, saveFailureHandler));
		}
		
		private function saveSuccessHandler(e:ResultEvent,token:Object = null):void{
			trace('template Success');
		}
		
		private function saveFailureHandler(e:FaultEvent,token:Object = null):void{
			trace('Template failed');
		}
		
		
		public const verticalGap:LinkableNumber = registerLinkableChild(this, new LinkableNumber(6));
		public const horizontalGap:LinkableNumber = registerLinkableChild(this, new LinkableNumber(6));
		public const columnCount:LinkableNumber = registerLinkableChild(this, new LinkableNumber(2));
		public const rowCount:LinkableNumber = registerLinkableChild(this, new LinkableNumber(2));
		
		
		private var _toolName:String = 'EHSProperties';
		public function launchDebugWindow():void
		{
			
			var windowFeatures:String = "menubar=no,status=no,toolbar=no";
			var success:Boolean = JavaScript.exec(
				{
					"catch": reportError,
					"toolname": _toolName,
					"url": "angular/WeaveSession/index.html",
					"features": windowFeatures
				},
				"if (!this.external_tools)",
				"    this.external_tools = {};",
				"var popup = window.open(url, toolname, features);",
				"this.external_tools[toolname] = popup;",
				"return !!popup;"
			);
			if (!success)
				reportError("Popup blocked by web browser");
			
			var launchTimer:Timer = new Timer(5000, 1);
			launchTimer.addEventListener(TimerEvent.TIMER, launchTimeout);
			launchTimer.start();
		}
		
		private var _debugWindowReady:Boolean = false
		private function launchTimeout(event:TimerEvent):void
		{
			if (!_debugWindowReady)
			{
				Alert.show(lang("This external tool failed to load. Try disabling your popup blocker for this site to prevent this from happening in the future."), _toolName + " " + lang("Error"), Alert.OK);
			}
		}
		
		public function debugModeReady():void
		{
			_debugWindowReady = true;
			//SessionStateLog.debug = true;
			sendSessionDataToDebugWindow();
		}
		
		//private const debug:LinkableBoolean = newDisposableChild(this,LinkableBoolean);
		private function sendSessionDataToDebugWindow():void
		{
			if(linkableObjectIsBusy(Weave.root)){
				trace('Weave.root is Busy');
				return;
			}
			/*if (!_cytoscapeReady.value || _primitiveNodes == null || _primitiveEdges == null)
			{
				callLater(sendNetworkToCytoscape);
				return;
			}
			var parameters:Object = {};
			var element_to_key_types:Object = {nodes: _nodeKeyType, edges: _edgeKeyType};
			var primitiveElements:Array = _primitiveNodes.concat(_primitiveEdges);
			
			parameters.dataSchema = _networkSchema;
			parameters.layout = _primitiveLayout;*/
			if(_debugWindowReady){
				//var sessionSatae:* = (WeaveAPI.SessionManager as SessionManager).getSessionStateTree(WeaveAPI.globalHashMap,'Weave');
				/*var weaveSession:* = (WeaveAPI.SessionManager as SessionManager).getParentChildMapTree(WeaveAPI.globalHashMap,'Weave',new Object());
				trace(5);
				JavaScript.exec(
					{
						"catch": reportError,
						"toolname": _toolName,
						"sessionJsonData": weaveSession
					},
					"this.external_tools[toolname].loadWeaveSessionData(sessionJsonData);"
				);*/
			}
			
		}
		
	
		
		
		
		
		
	}
}