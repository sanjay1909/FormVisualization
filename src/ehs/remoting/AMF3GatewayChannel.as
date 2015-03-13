package ehs.remoting
{
	import flash.utils.ByteArray;
	
	import mx.messaging.channels.AMFChannel;
	import mx.rpc.AsyncToken;
	
	import weave.services.ProxyAsyncToken;

	public class AMF3GatewayChannel extends GatewayChannel
	{
		
		private var amfChannel:AMFChannel;
		public function AMF3GatewayChannel(id:String,uri:String,destiantion:String,source:String)
		{
			amfChannel = new AMFChannel(id,uri);
			super(amfChannel,destiantion,source);
		}
			
		public function setCredentials(username:String, password:String):void{
			remoteObject.setCredentials(username,password);
		}
		
		public function logout():void{
			remoteObject.logout();
		}
		
		
		
		/**
		 * This function makes a remote procedure call to a EHS AMF3 Gateway.  As a special case, if
		 * methodParameters is an Array and the last item is a ByteArray, the bytes will be appended after
		 * the initial AMF3 serialization of the preceeding parameters to allow additional content that can
		 * be treated as a stream in Java.
		 * @param methodName The name of the method to call.
		 * @param methodParameters The parameters to use when calling the method.
		 * @return An AsyncToken that you can add responders to.
		 */
		override public function invokeAsyncMethod(methodName:String, methodParameters:Object = null):AsyncToken
		{
			var pt:ProxyAsyncToken = new ProxyAsyncToken(super.invokeAsyncMethod, arguments, readCompressedObject);
			pt.invoke();
			return pt;
		}
		
		//registerClassAlias("UserRecord",UserRecord);		
		/**
		 * This function reads an object that has been AMF3-serialized into a ByteArray and compressed.
		 * @param compressedSerializedObject The ByteArray that contains the compressed AMF3 serialization of an object.
		 * @return The result of calling uncompress() and readObject() on the ByteArray, or null if the RPC returns void.
		 * @throws Error If unable to read the result.
		 */
		public static function readCompressedObject(compressedSerializedObject:ByteArray):Object
		{
			// length may be zero for void result
			if (compressedSerializedObject.length == 0)
				return null;
			
			//var packed:int = compressedSerializedObject.bytesAvailable;
			//var time:int = getTimer();
			//the compression stream used in .net is not compatibale 
			//compressedSerializedObject.uncompress();
			
			//var unpacked:int = compressedSerializedObject.bytesAvailable;
			//trace(packed,'/',unpacked,'=',Math.round(packed/unpacked*100) + '%',getTimer()-time,'ms');
			var result:* = compressedSerializedObject.readObject();
			return result;
		}
	}
}