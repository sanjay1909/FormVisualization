package ehs.services
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.controls.Alert;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import avmplus.DescribeType;
	
	import ehs.EHS;
	import ehs.remoting.AMF3GatewayChannel;
	import ehs.remoting.GatewayChannel;
	import ehs.services.beans.LabSafetyRecord;
	import ehs.services.beans.UserRecord;
	
	import weave.Weave;
	import weave.api.registerLinkableChild;
	import weave.api.core.ILinkableObject;
	import weave.compiler.Compiler;
	import weave.compiler.StandardLib;
	import weave.core.CallbackCollection;
	import weave.core.LinkableBoolean;
	import weave.services.AsyncInvocationQueue;
	import weave.services.ProxyAsyncToken;
	import weave.services.WeaveDataServlet;
	import weave.services.addAsyncResponder;
	

	public class EHSAdminGateway implements ILinkableObject
	{
		
		
		public static const messageLog:Array = new Array();
		public static const messageLogCallbacks:CallbackCollection = new CallbackCollection();
		
		public static function messageDisplay(messageTitle:String, message:String, showPopup:Boolean):void 
		{
			// for errors, both a popupbox and addition in the Log takes place
			// for successes, only addition in Log takes place
			if (showPopup)
				Alert.show(message,messageTitle);
			
			// always add the message to the log
			if (messageTitle == null)
				messageLog.push(message);
			else
				messageLog.push(messageTitle + ": " + message);
			
			messageLogCallbacks.triggerCallbacks();
		}
		
		public static function clearMessageLog():void
		{
			messageLog.length = 0;
			messageLogCallbacks.triggerCallbacks();
		}
		
		
		public function EHSAdminGateway(gatewayURL:String)
		{
			adminChannel = registerLinkableChild(this,new AMF3GatewayChannel("my-amf",gatewayURL,"fluorine","ServiceLibrary.AdminService"));			
			queue = registerLinkableChild(this, new AsyncInvocationQueue(true)); // paused
			var info:* = DescribeType.getInfo(this, DescribeType.METHOD_FLAGS);
			for each (var item:Object in info.traits.methods)
			{
				var func:Function = this[item.name] as Function;
				if (func != null)
					propertyNameLookup[func] = item.name;
			}
			
			//initializeAdminService();
			
			queue.begin();
			
			
		}
		
		private var queue:AsyncInvocationQueue;
		private var adminChannel:AMF3GatewayChannel;
		private var dataService:AMF3GatewayChannel;
		private var propertyNameLookup:Dictionary = new Dictionary(); // Function -> String
		private var methodHooks:Object = {}; // methodName -> Array (of MethodHook)
		
		
		//TODO - move hooks from Admin.as to here, and automatically set these user/pass/authenticated settings
		public const authenticated:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		[Bindable] public var user:String = '';
		[Bindable] public var pass:String = '';
		
		// needs to be sessioned
		//public var userInfo:UserRecord;
		public const userInfo:UserRecord = registerLinkableChild(this, new UserRecord());
		
		
		/**
		 * @param method A pointer to a function of this WeaveAdminService.
		 * @param captureHandler Receives the parameters of the RPC call with the 'this' pointer set to the AsyncToken object.
		 * @param resultHandler A ResultEvent handler:  function(event:ResultEvent, parameters:Array = null):void
		 * @param faultHandler A FaultEvent handler:  function(event:FaultEvent, parameters:Array = null):void
		 */
		public function addHook(method:Function, captureHandler:Function, resultHandler:Function, faultHandler:Function = null):void
		{
			var methodName:String = propertyNameLookup[method];
			if (!methodName)
				throw new Error("method must be a member of " + getQualifiedClassName(this));
			var hooks:Array = methodHooks[methodName];
			if (!hooks)
				methodHooks[methodName] = hooks = [];
			var hook:MethodHook = new MethodHook();
			hook.captureHandler = captureHandler;
			hook.resultHandler = resultHandler;
			hook.faultHandler = faultHandler;
			hooks.push(hook);
		}
		
		private function hookCaptureHandler(query:ProxyAsyncToken):void
		{
			var methodName:String = query._params[0];
			var methodParams:Array = query._params[1];
			for each (var hook:MethodHook in methodHooks[methodName])
			{
				if (hook.captureHandler == null)
					continue;
				var args:Array = methodParams ? methodParams.concat() : [];
				args.length = hook.captureHandler.length;
				hook.captureHandler.apply(query, args);
			}
		}
		
		/**
		 * This gets called automatically for each ResultEvent from an RPC.
		 * @param method The WeaveAdminService function which corresponds to the RPC.
		 */
		private function hookHandler(event:Event, query:ProxyAsyncToken):void
		{
			var handler:Function;
			var methodName:String = query._params[0];
			var methodParams:Array = query._params[1];
			for each (var hook:MethodHook in methodHooks[methodName])
			{
				if (event is ResultEvent)
					handler = hook.resultHandler;
				else
					handler = hook.faultHandler;
				if (handler == null)
					continue;
				
				var args:Array = [event, methodParams];
				args.length = handler.length;
				handler.apply(null, args);
			}
		}
		
		/**
		 * This function will generate a DelayedAsyncInvocation representing a servlet method invocation and add it to the queue.
		 * @param method A WeaveAdminService class member function.
		 * @param parameters Parameters for the servlet method.
		 * @param queued If true, the request will be put into the queue so only one request is made at a time.
		 * @return The DelayedAsyncInvocation object representing the servlet method invocation.
		 */		
		private function invokeAdmin(method:Function, parameters:Array, queued:Boolean = true, returnType:Class = null):AsyncToken
		{
			var methodName:String = propertyNameLookup[method];
			if (!methodName)
				throw new Error("method must be a member of " + getQualifiedClassName(this));
			return generateQuery(adminChannel, methodName, parameters, queued, returnType);
		}
		
		/**
		 * This function will generate a DelayedAsyncInvocation representing a servlet method invocation and add it to the queue.
		 * @param methodName The name of a Weave AdminService servlet method.
		 * @param parameters Parameters for the servlet method.
		 * @param queued If true, the request will be put into the queue so only one request is made at a time.
		 * @return The DelayedAsyncInvocation object representing the servlet method invocation.
		 */		
		private function invokeAdminWithLogin(method:Function, parameters:Array, queued:Boolean = true, returnType:Class = null):AsyncToken
		{
			parameters.unshift(EHS.properties.activeConnectionName, EHS.properties.activePassword);
			return invokeAdmin(method, parameters, queued, returnType);
		}
		
		/**
		 * This function will generate a DelayedAsyncInvocation representing a servlet method invocation and add it to the queue.
		 * @param service The servlet.
		 * @param methodName The name of a servlet method.
		 * @param parameters Parameters for the servlet method.
		 * @param returnType The type of object which the result should be cast to.
		 * @return The ProxyAsyncToken object representing the servlet method invocation.
		 */		
		private function generateQuery(channel:GatewayChannel, methodName:String, parameters:Array, queued:Boolean, returnType:Class):AsyncToken
		{
			var query:ProxyAsyncToken = new ProxyAsyncToken(channel.invokeAsyncMethod, [methodName, parameters]);
			
			if (queued)
				queue.addToQueue(query);
			
			hookCaptureHandler(query);
			
			if ([null, Array, String, Number, int, uint].indexOf(returnType) < 0)
				addAsyncResponder(query, WeaveDataServlet.castResult, null, returnType);
			
			// automatically display FaultEvent error messages as alert boxes
			addAsyncResponder(query, hookHandler, alertFault, query);
			
			if (!queued)
				query.invoke();
			
			return query;
		}
		
		// this function displays a String response from a server in an Alert box.
		private function alertResult(event:ResultEvent, token:Object = null):void
		{
			messageDisplay(null,String(event.result),false);
		}
		
		private static const PREVENT_FAULT_ALERT:Dictionary = new Dictionary(true);
		
		
		/**
		 * Prevents the default error display if a fault occurs.
		 * @param query An AsyncToken that was generated by this service.
		 */		
		public function hideFaultMessage(query:AsyncToken):void
		{
			PREVENT_FAULT_ALERT[query] = true;
		}
		
		// this function displays an error message from a FaultEvent in an Alert box.
		private function alertFault(event:FaultEvent, query:ProxyAsyncToken):void
		{
			var methodName:String = query._params[0];
			var methodParams:Array = query._params[1];
			if (PREVENT_FAULT_ALERT[query])
			{
				delete PREVENT_FAULT_ALERT[query];
				return;
			}
			
			var paramDebugStr:String = '';
			
			if (methodParams is Array && methodParams.length > 0)
				paramDebugStr = methodParams.map(function(p:Object, i:int, a:Array):String { return Compiler.stringify(p); }).join(', ');
			else
				paramDebugStr += Compiler.stringify(methodParams);
			
			trace(StandardLib.substitute(
				"Received error on {0}({1}):\n\t{2}",
				methodName,
				paramDebugStr,
				event.fault.faultString
			));
			
			//Alert.show(event.fault.faultString, event.fault.name);
			var msg:String = event.fault.faultString;
			if (msg == "ioError")
				msg = "Received no response from the Gateway.\n"
					+ "Has the dll file been deployed correctly?\n"
					+ "Expected gateway URL: "+ adminChannel.source;
			messageDisplay(event.fault.name, msg, false);
		}
		
		
		
		public function saveWeaveFile(fileContent:ByteArray, fileName:String, overWrite:Boolean = false):AsyncToken
		{
			fileContent.compress();
			var query:AsyncToken = invokeAdmin(saveWeaveFile,[ fileContent,fileName,overWrite]);
			addAsyncResponder(query, alertResult);
			return query;
		}
		
		public function getFile(fileName:String):AsyncToken
		{
			
			var query:AsyncToken = invokeAdmin(getFile,[ fileName]);
			addAsyncResponder(query, loadWeave);
			return query;
		}
		
		private function loadWeave(event:ResultEvent,token:AsyncToken = null):void{
			Weave.loadWeaveFileContent(event.result);
			//trace(event.result);
		}
		
		
		public function insertToLabSafetyTable(record:LabSafetyRecord):AsyncToken
		{
			var query:AsyncToken = invokeAdmin(insertToLabSafetyTable,[record]);
			addAsyncResponder(query, alertResult);
			return query;
		}
		
		public function getRecordsByInspector(inspectorName:String):AsyncToken
		{
			var query:AsyncToken = invokeAdmin(getRecordsByInspector,[inspectorName]);
			addAsyncResponder(query, alertResult);
			return query;
		}
		
		/*public function login(username:String,password:String):AsyncToken{
			// logout shld be perforemd before setting credentials
			adminChannel.logout();
			adminChannel.setCredentials(username,password);
			var query:AsyncToken = invokeAdmin(login,null);
			addAsyncResponder(query, activate,failure);
			return query;
		}*/
		
		public function login(username:String, password:String):AsyncToken
		{
			adminChannel.logout();
			adminChannel.setCredentials(username,password);
			return invokeAdmin(login, null);
		}
		
		//remote channel logout is still not working so using server logout
		//https://issues.apache.org/jira/browse/FLEX-25546
		public function logout():AsyncToken{	
			adminChannel.logout();
			return invokeAdmin(logout,null);						
		}
		
		// this function is for verifying the local connection between Weave and the AdminConsole.
		public function ping():String { return "pong"; }
		
	}
}

internal class MethodHook
{
	public var captureHandler:Function;
	public var resultHandler:Function;
	public var faultHandler:Function;
}