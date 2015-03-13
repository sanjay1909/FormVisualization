package ehs.ui
{
	import mx.events.ValidationResultEvent;
	import mx.validators.Validator;
	
	import spark.components.TextInput;
	
	import flashx.textLayout.formats.TextAlign;

	public class TextInputWithValidation extends TextInput
	{
		
		public var validate:Boolean = false
		public function TextInputWithValidation()
		{
			this.needsSoftKeyboard = true;
			setStyle("textAlign",TextAlign.LEFT);
			
			if(validate){
				var validator:Validator = new Validator();				
				validator.source = this;
				validator.property = "text";
				validator.required = true;
				validator.requiredFieldError =  " required ";
				validator.addEventListener(ValidationResultEvent.VALID,handleValidation);
				validator.addEventListener(ValidationResultEvent.INVALID,handleValidation);				
			}
		}
		
		private function handleValidation(evt:ValidationResultEvent):void {
			if (evt.type == ValidationResultEvent.VALID) {
				//update menu bar			
			} else {
				// to -do update menu bar
			}
		}
	}
}