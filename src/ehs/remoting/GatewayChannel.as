package ehs.remoting
{
	import flash.utils.Dictionary;
	
	import mx.core.mx_internal;
	import mx.messaging.Channel;
	import mx.messaging.ChannelSet;
	import mx.rpc.AbstractOperation;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.remoting.RemoteObject;
	
	import weave.api.core.IDisposableObject;
	import weave.api.services.IAsyncService;
	import weave.utils.VectorUtils;

	public class GatewayChannel implements IAsyncService, IDisposableObject
	{
		protected var remoteObject:RemoteObject;
		public function GatewayChannel(channel:Channel,destiantion:String,source:String)
		{			
			remoteObject = new RemoteObject(destiantion);
			remoteObject.channelSet = new ChannelSet();
			remoteObject.channelSet.addChannel(channel);
			remoteObject.source = source;
			
			
			
			
		}
		
		
		protected var _source:String;
		public function get source():String
		{
			return _source;
		}
		
		
		/**
		 * This function makes a remote procedure call.
		 * @param methodName The name of the method to call.
		 * @param methodParameters The parameters to use when calling the method.
		 * @return An AsyncToken generated for the call.
		 */
		public function invokeAsyncMethod(methodName:String, methodParameters:Object = null):AsyncToken
		{
			var token:AsyncToken = new AsyncToken();
			
			_asyncTokenData[token] = arguments;
			
			if (!_invokeLater)
				invokeNow(token);
			
			return token;
		}
		
		/**
		 * This function may be overrided to give different servlet URLs for different methods.
		 * @param methodName The method.
		 * @return The servlet url for the method.
		 */
		protected function getGatewaySourceForMethod(methodName:String):String
		{
			return _source;
		}
		
		/**
		 * This will make a url request that was previously delayed.
		 * @param invokeToken An AsyncToken generated from a previous call to invokeAsyncMethod().
		 */
		protected function invokeNow(invokeToken:AsyncToken):void
		{
			var args:Array = _asyncTokenData[invokeToken] as Array;
			if (!args)
				return;
			
			var methodName:String = args[0];
			var methodParameters:Object = args[1];
			
			var method:AbstractOperation = remoteObject.getOperation(methodName);
			//method.
			method.arguments = methodParameters;
			var asyncToken:AsyncToken = method.send();
			asyncToken.addResponder(new CustomAsyncResponder(this, null, resultHandler, faultHandler, invokeToken));
			//_asyncTokenData[invokeToken] = method;
		}
		
		private function resultHandler(event:ResultEvent, token:AsyncToken):void
		{
			if (_asyncTokenData[token] !== undefined)
			{
				token.mx_internal::applyResult(event);
				delete _asyncTokenData[token];
			}
		}
		private function faultHandler(event:FaultEvent, token:AsyncToken):void
		{
			if (_asyncTokenData[token] !== undefined)
			{
				token.mx_internal::applyFault(event);
				delete _asyncTokenData[token];
			}
		}
		
		
		/**
		 * Set this to true to prevent url requests from being made right away.
		 * When this is set to true, invokeNow() must be called to make delayed url requests.
		 * Setting this to false will immediately resume all delayed url requests.
		 */
		protected function set invokeLater(value:Boolean):void
		{
			_invokeLater = value;
			if (!_invokeLater)
				for (var token:Object in _asyncTokenData)
					invokeNow(token as AsyncToken);
		}
		
		protected function get invokeLater():Boolean
		{
			return _invokeLater;
		}
		
		private var _invokeLater:Boolean = false;
		
		/**
		 * This is a mapping of AsyncToken objects to NetConnection objects. 
		 * This mapping is necessary so a client with an AsyncToken can cancel the loader. 
		 */		
		private const _asyncTokenData:Dictionary = new Dictionary();
		
		public function dispose():void
		{
			var fault:Fault = new Fault('Notification', 'Gateway was disposed', null);
			for each (var token:AsyncToken in VectorUtils.getKeys(_asyncTokenData))
			{
				var event:FaultEvent = new FaultEvent(FaultEvent.FAULT, false, true, fault, token);
				faultHandler(event, token);
			}
		}
		
		
	}
}
import mx.rpc.AsyncResponder;
import mx.rpc.AsyncToken;
import mx.rpc.events.ResultEvent;

import weave.api.core.ILinkableObject;
import weave.api.services.IURLRequestToken;

/**
 * This is an AsyncResponder that can be cancelled using the IURLRequestToken interface.
 * 
 * @author adufilie
 */
internal class CustomAsyncResponder extends AsyncResponder implements IURLRequestToken
{
	public function CustomAsyncResponder(relevantContext:Object, asyncToken:AsyncToken, result:Function, fault:Function, token:Object = null)
	{
		super(result || noOp, fault || noOp, token);
		
		this.relevantContext = relevantContext;
		
		this.asyncToken = asyncToken;
		if (asyncToken)
			asyncToken.addResponder(this);
		
		WeaveAPI.ProgressIndicator.addTask(this, relevantContext as ILinkableObject);
	}
	
	private static function noOp(..._):void {} // does nothing
	
	private var asyncToken:AsyncToken;
	private var relevantContext:Object;
	
	public function cancelRequest():void
	{
		WeaveAPI.ProgressIndicator.removeTask(this);
		if (asyncToken && !WeaveAPI.SessionManager.objectWasDisposed(this))
			remove();
		WeaveAPI.SessionManager.disposeObject(this);
	}
	
	private function remove():void{
		var responders:Array = asyncToken.responders;
		var index:int = responders.indexOf(this);
		if (index >= 0)
		{
			// remoteMethod RequestToken found -- remove it
			responders.splice(index, 1);
			// see if there are any more remoteMethod RequestTokens
			for each (var obj:Object in asyncToken.responders)
			if (obj is CustomAsyncResponder)
				return;			
		}
	}
	
	override public function result(data:Object):void
	{
		WeaveAPI.ProgressIndicator.removeTask(this);
		if (!WeaveAPI.SessionManager.objectWasDisposed(this) && !WeaveAPI.SessionManager.objectWasDisposed(relevantContext))
			super.result(data);
	}
	
	override public function fault(data:Object):void
	{
		WeaveAPI.ProgressIndicator.removeTask(this);
		if (!WeaveAPI.SessionManager.objectWasDisposed(this) && !WeaveAPI.SessionManager.objectWasDisposed(relevantContext))
			super.fault(data);
	}
}

/**
 * This is a CustomAsyncResponder that is used by getContent() to delay the handlers until the content finishes loading.
 * 
 * @author adufilie
 */
internal class ContentAsyncResponder extends CustomAsyncResponder
{
	public function ContentAsyncResponder(relevantContext:Object, asyncToken:AsyncToken, result:Function, fault:Function, token:Object = null)
	{
		super(relevantContext, asyncToken, result, fault, token);
	}
	
	/**
	 * This function should be called when the content is loaded.
	 * @param event
	 */	
	internal function contentResult(event:ResultEvent):void
	{
		super.result(event);
	}
	
	/**
	 * This function does nothing.  Instead, contentResult() should be called.
	 * @param data
	 */
	override public function result(data:Object):void
	{
		// Instead of this function, contentResult() will call super.result()
	}
}