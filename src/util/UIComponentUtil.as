package util
{
	import mx.core.UIComponent;
	import mx.core.UIComponentDescriptor;
	import mx.core.mx_internal;

	public class UIComponentUtil
	{
		public static function getDescriptor( component:UIComponent ):UIComponentDescriptor{
			var result:UIComponentDescriptor = component.descriptor;
			if( result == null ){
				result = component.descriptor = new UIComponentDescriptor({});
			}
			if( result.events == null ){
				result.events = {};
			}
			return result;
		}
		
		public static function getDocumentDescriptor( component:UIComponent ):UIComponentDescriptor{
			var result:UIComponentDescriptor = component.mx_internal::documentDescriptor;
			if( result == null ){
				result = component.mx_internal::documentDescriptor = new UIComponentDescriptor({});
			}
			if( result.events == null ){
				result.events = {};
			}
			return result;
		}
		
		public static function getProperties( component:UIComponent ):Object{
			return getDescriptor(component).properties;
		}
	}
}