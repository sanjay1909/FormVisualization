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

package weave.core
{
	import mx.binding.utils.BindingUtils;
	import mx.binding.utils.ChangeWatcher;
	import mx.core.UIComponent;
	import mx.utils.ObjectUtil;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableVariable;
	import weave.api.core.ISessionManager;
	import weave.compiler.Compiler;
	
	/**
	 * @see weave.core.SessionManager#linkBindableProperty()
	 */
	public class StructureSynchronizer implements IDisposableObject
	{
		public function StructureSynchronizer(linkableStructure:ILinkableVariable, bindableParent:Object, bindablePropertyName:String,linkableStructureProperty:String = null, delay:uint = 0, onlyWhenFocused:Boolean = false):void
		{
			sm.registerDisposableChild(bindableParent, this);
			this.linkableStructure = linkableStructure;
			this.linkableStructureProperty = linkableStructureProperty;
			this.bindableParent = bindableParent;
			this.bindablePropertyName = bindablePropertyName;
			this.delay = delay;
			this.onlyWhenFocused = onlyWhenFocused;
			this.callbackCollection = sm.getCallbackCollection(linkableStructure);
			this.uiComponent = bindableParent as UIComponent;
			
			// Copy session state over to bindable property now, before calling BindingUtils.bindSetter(),
			// because that will copy from the bindable property to the sessioned property.
			this.synchronize();
			
			// below, we need to check if the variables are still set in case dispose() was called from synchronize()
			
			// when the bindable property changes, set the session state
			if (this.linkableStructure)
				this.watcher = BindingUtils.bindSetter(synchronize, bindableParent, bindablePropertyName);
			
			// when the session state changes, set the bindable property
			if (this.callbackCollection)
				this.callbackCollection.addImmediateCallback(bindableParent, synchronize);
		}
		
		public function dispose():void
		{
			this.callbackCollection.removeCallback(synchronize);
			if (this.watcher)
				this.watcher.unwatch();
			
			this.linkableStructure = null;
			this.bindableParent = null;
			this.bindablePropertyName = null;
			this.linkableStructureProperty = null;
			this.callbackCollection = null;
			this.watcher = null;
		}
		
		public var debug:Boolean = false;
		
		private const sm:ISessionManager = WeaveAPI.SessionManager;
		private var callbackCollection:ICallbackCollection;
		private var linkableStructure:ILinkableVariable;
		private var linkableStructureProperty:String;
		private var bindableParent:Object;
		private var bindablePropertyName:String;
		private var delay:uint;
		private var onlyWhenFocused:Boolean;
		private var watcher:ChangeWatcher;
		private var uiComponent:UIComponent;
		private var useLinkableValue:Boolean = true;
		//private var callLaterTime:int = 0;
		private var recursiveCall:Boolean = false;
		
		private function debugLink(linkVal:Object, bindVal:Object, useLinkableBefore:Boolean, useLinkableAfter:Boolean, callingLater:Boolean =false):void
		{
			var link:String = (useLinkableBefore && useLinkableAfter ? 'LINK' : 'link') + '(' + Compiler.stringify(linkVal) + ')';
			var bind:String = (!useLinkableBefore && !useLinkableAfter ? 'BIND' : 'bind') + '(' + Compiler.stringify(bindVal) + ')';
			var str:String = link + ', ' + bind;
			if (useLinkableBefore && !useLinkableAfter)
				str = link + ' = ' + bind;
			if (!useLinkableBefore && useLinkableAfter)
				str = bind + ' = ' + link;
			if (callingLater)
				str += ' (callingLater)';
			
			trace(str);
		}
		
		
		// When given zero parameters, this function copies the linkable value to the bindable value.
		// When given one or more parameters, this function copies the bindable value to the linkable value.
		private function synchronize(firstParam:* = undefined):void
		{
			// stop if already disposed
			if (!linkableStructure)
				return;
			
			// unlink if linkableVariable was disposed
			if (sm.objectWasDisposed(linkableStructure))
			{
				sm.disposeObject(this);
				return;
			}
			
			/*if(linkableStructure.getSessionState()[linkableStructureProperty] == bindableParent[bindablePropertyName])
				return;
			*/
			if (debug)
				debugLink(
					linkableStructure.getSessionState(),
					firstParam===undefined ? bindableParent[bindablePropertyName] : firstParam,
					useLinkableValue,
					firstParam===undefined
					//callingLater
				);
			
			// If bindableParent has focus:
			// When linkableVariable changes, update bindable value only when focus is lost (callLaterTime = int.MAX_VALUE).
			// When bindable value changes, update linkableVariable after a delay.
			
			//if (!callingLater)
			//{
				// remember which value changed last -- the linkable one or the bindable one
				useLinkableValue = firstParam === undefined; // true when called from linkable variable grouped callback
				// if we're not calling later and there is already a timestamp, just wait for the callLater to trigger
				//if (callLaterTime)
				//{
					// if there is a callLater waiting to trigger, update the target time
					//callLaterTime = useLinkableValue ? int.MAX_VALUE : getTimer() + delay;
					
					//trace('\tdelaying the timer some more');
					
					//return;
				//}
			//}
			
			// if the bindable value is not a boolean and the bindable parent has focus, delay synchronization
			var bindableValue:Object = bindableParent[bindablePropertyName];
		/*	if (uiComponent && !(bindableValue is Boolean))
			{
				var obj:DisplayObject = uiComponent.getFocus();
				if (obj && uiComponent.contains(obj)) // has focus
				{
					if (linkableStructure is LinkableVariable)
					{
						var verified:Boolean = false;
						try
						{
							verified = (linkableStructure as LinkableVariable).verifyValue(bindableValue);
						}
						catch (e:Error)
						{
							trace('Error calling verifier:', e.getStackTrace());
						}
						if (verified)
						{
							// clear previous error string
							if (uiComponent.errorString == VALUE_NOT_ACCEPTED)
								uiComponent.errorString = '';
						}
						else
						{
							// show error string if not already shown
							if (!uiComponent.errorString)
								uiComponent.errorString = VALUE_NOT_ACCEPTED;
						}
					}
					
					var currentTime:int = getTimer();
					
					// if we're not calling later, set the target time (int.MAX_VALUE means delay until focus is lost)
					if (!callingLater)
						callLaterTime = useLinkableValue ? int.MAX_VALUE : currentTime + delay;
					
					// if we haven't reached the target time yet or callbacks are delayed, call later
					if (currentTime < callLaterTime)
					{
						// firstParam is ignored when callingLater=true
						uiComponent.callLater(synchronize, [firstParam, true]);
						return;
					}
				}
				else if (!useLinkableValue && onlyWhenFocused && !callingLater)
				{
					// component does not have focus, so ignore the bindableValue.
					return;
				}
				
				// otherwise, synchronize now
				// clear saved time stamp when we are about to synchronize
				callLaterTime = 0;
			}*/
			
			// if the linkable variable's callbacks are delayed, delay synchronization
			if (sm.getCallbackCollection(linkableStructure).callbacksAreDelayed)
			{
				// firstParam is ignored when callingLater=true
				WeaveAPI.StageUtils.callLater(this, synchronize, [firstParam, true]);
				return;
			}
			
			// synchronize
			if (useLinkableValue)
			{				
				var linkableValue:Object = linkableStructure.getSessionState()[linkableStructureProperty];
				
				if ((bindableValue is Number) != (linkableValue is Number))
				{
					try {
						if (linkableValue is Number)
						{
							if (isNaN(linkableValue as Number))
								linkableValue = '';
							else
								linkableValue = '' + linkableValue;
						}
						else
						{
                            // casting to number
							var struct:Object = Object(ObjectUtil.copy(linkableStructure.getSessionState()));
							struct[linkableStructureProperty][0] = Number(linkableValue);
							linkableStructure.setSessionState(struct);							
							linkableValue = struct[linkableStructureProperty];
						}
					} catch (e:Error) { }
				}
				if (bindableValue != linkableValue){
					//trace(' ---------------- linkableValue: ' + linkableValue);
					bindableParent[bindablePropertyName] = linkableValue;
				}
					
				
				// clear previous error string
				if (uiComponent && linkableStructure is LinkableVariable && uiComponent.errorString == VALUE_NOT_ACCEPTED)
					uiComponent.errorString = '';
			}
			else
			{
				var prevCount:uint = callbackCollection.triggerCounter;
				var structure:Object = Object(ObjectUtil.copy(linkableStructure.getSessionState()));
				
				structure[linkableStructureProperty] = bindableValue;
				//if(!StandardLib.compare(structure, Object(ObjectUtil.copy(linkableStructure.getSessionState())) ))
					//trace(' -----bindableValue @@@@@@@@@@@: ' + bindableValue);
				linkableStructure.setSessionState(structure);
				
				// Always synchronize after setting the linkableVariable because there may
				// be constraints on the session state that will prevent the callbacks
				// from triggering if the bindable value does not match those constraints.
				// This makes UIComponents update to the real value after they lose focus.
				if (callbackCollection.triggerCounter == prevCount && !recursiveCall)
				{
					// avoid infinite recursion in the case where the new value is not accepted by a verifier function
					recursiveCall = true;
					synchronize();
					recursiveCall = false;
				}
			}
		}
		
		private const VALUE_NOT_ACCEPTED:String = lang('Value not accepted.');
	}
}


