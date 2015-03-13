package print
{
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.navigateToURL;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import spark.components.Alert;
	
	import ehs.EHS;
	import ehs.EHSUtils;
	import ehs.data.InspectionData;
	import ehs.data.InspectionKeyData;
	import ehs.data.InspectionReportData;
	import ehs.services.EHSAdminGateway;
	import ehs.services.beans.LabSafetyRecord;
	import ehs.services.beans.UserRecord;
	
	import org.alivepdf.saving.Download;
	
	import weave.api.getSessionState;
	import weave.api.reportError;
	import weave.api.core.ILinkableVariable;
	import weave.compiler.StandardLib;
	import weave.core.SessionManager;
	import weave.core.StructureSynchronizer;
	import weave.core.WeaveArchive;
	import weave.primitives.Dictionary2D;
	import weave.services.DelayedAsyncResponder;

	public class ServerManager implements IServerManager
	{
		public function ServerManager()
		{
			
		}
		
		
		
		// required to maintain the order for sectionFilledDatamap
		public var sectionOrder:Array = new Array();
			
		public var sectionFilledDataMap:Dictionary = new Dictionary(true);
		public var sectionCommentMap:Dictionary = new Dictionary(true);
		public var printParameters:PrintProperties = new PrintProperties();
		
		public var keyData:InspectionKeyData;
		public var reportData:InspectionReportData;
		
		public const DEFAULT_NAME:String = "Safety Form"
		/**
		 * Used as storage for last loaded session history file name.
		 */		
		public var fileName:String = DEFAULT_NAME;
		
		
		// Should be used only for loacl saving
		public function getFileName():String
		{
			if(fileName == DEFAULT_NAME){
				if( (keyData.principalInvestigator.value && keyData.principalInvestigator.value.length > 0 ) 
					&& (keyData.building.value && keyData.building.value.length > 0)
					&& (keyData.roomNumbers.value && keyData.roomNumbers.value.length > 0)){
					fileName =  keyData.principalInvestigator.value + "_" + keyData.building.value +"_"+ keyData.roomNumbers.value + '_' + StandardLib.formatDate(new Date(), "YYYY-MM-DD_HH.NN.SS", false) + '.weave';
					trace(fileName);
				}
				else{
					
					fileName = DEFAULT_NAME;
					trace(fileName);
				}	
			}
			fileName  = fileName.replace(" ","_");
					
			return fileName;
		}
		
		public var fileID:String;
		
		public function populateLabSafetyRecord():LabSafetyRecord{
			var rec:LabSafetyRecord = new LabSafetyRecord();
			rec.building = keyData.building.value;
			rec.cho = reportData.cho.value;
			rec.choMailId = reportData.choMailID.value;
			rec.department = keyData.dept.value;
			rec.dueDate = reportData.dueDate? getSessionState(reportData.dueDate) as Date : null;
			// file path after saveing the file , only the name is created on clinet , the folde ris addeda t server
			rec.filePath = EHS.properties.fileID.value;			
			rec.fileID = EHS.properties.fileID.value;
			
			rec.inspectionDate = getSessionState(keyData.inspectionDate) as Date;
			rec.inspector = inspectorInfo.firstName.value + " " + inspectorInfo.lastName.value;
			rec.pi = keyData.principalInvestigator.value;
			rec.primaryFunction = (getSessionState(keyData.primaryFunction) as Array).join(",");
			rec.roomNumber = keyData.roomNumbers.value;
			rec.status = reportData.status.value;
			
			
			return rec;
		}
		
		
		// not mkaing any checks, here
		// assuming the inspector fills the form before
		// need to restructure better
		public function getFormStatusForPDF():String{
			var beginDate:Number;
			var endDate:Number;
			var diff:Number;
			if(!reportData.dueDate.getSessionState()){
				return "";
			}
			if(keyData)
				beginDate = (keyData.inspectionDate.getSessionState() as Date).getTime();
			if(reportData)
				endDate = (reportData.dueDate.getSessionState() as Date).getTime();
			if(beginDate && endDate)
				endDate = endDate-beginDate;
			else
				return "";
			
			if(diff != 0){
				return "Corrective actions are due by: "  + EHSUtils.formatDate(reportData.dueDate.getSessionState() as Date);
			}
			else return "";
		}
		
		
		//private var inspector:Inspector = new Inspector();
		public function get inspectorInfo():UserRecord{
			//inspector.InspectorName = keyData.inspector.value;
			return EHS.properties.service.userInfo;
		}
		
		public function getContactStatusForPDF():String{
			//var mailid:String = reportData.choMailID.value;
			//if(!mailid || mailid.length == 0){
				//mailid = userInfo.email;
			//}
			var str:String = "If you have any questions, please contact " + inspectorInfo.firstName.value + " "+inspectorInfo.lastName.value  + " at " +  inspectorInfo.email.value;
			
			if(reportData.dueDate.getSessionState() ){
				var beginNumber:Number = (keyData.inspectionDate.getSessionState() as Date).getTime();
				var endNumber:Number = (reportData.dueDate.getSessionState() as Date).getTime();
				var diff:Number = endNumber - beginNumber;
				
				if(diff != 0){
					str	= "Please respond to " + inspectorInfo.firstName.value + " "+inspectorInfo.lastName.value  + " by email at " +  inspectorInfo.email.value + " when corrective actions are complete.";
				}	
			}
			
			return str;
		}
		
		// need to public for section where datas are not filled but comments are used
		public function requestDataCollection(sectionName:String):ArrayCollection{
			
			if(sectionFilledDataMap[sectionName] ){
				return sectionFilledDataMap[sectionName];
			}
			sectionOrder.push(sectionName);
			return sectionFilledDataMap[sectionName] = new ArrayCollection();
		}
		
		public function addSectionToComment(sectionName:String , sectionObj:Object):void{			
			sectionCommentMap[sectionName] = sectionObj;
		}
		
		public function removeSectionToComment(sectionName:String):void{
			delete sectionCommentMap[sectionName];
		}
		
		public function addFilledDataToSection(insdata:InspectionData):void{
			var dataCollection:ArrayCollection = requestDataCollection(insdata.section.value);
			if(dataCollection.getItemIndex(insdata) < 0)
				dataCollection.addItem(insdata);			
		}
		
		public function removeFilledDataToSection(insdata:InspectionData):void{
			var dataCollection:ArrayCollection = requestDataCollection(insdata.section.value);
			dataCollection.removeItem(insdata);			
			if(dataCollection.length <= 0){
				sectionOrder.splice(sectionOrder.indexOf(insdata.section.value),1);
				delete sectionFilledDataMap[insdata.section.value];	
			}
						
		}
		
		private function getDataAsPDF():ByteArray{
			var dataPdf:PdfGenerator = new PdfGenerator();			
			return dataPdf.createPDF();
		}
		
		public function print():void{
			if(keyData.completed){
				var ba:ByteArray = getDataAsPDF();
				generatePDFfromByteArray(ba);
			}
			else{
				Alert.show("Key Section needs to be completed");
			}
			
		}
		
		//public const pdfServiceUrl:String = "http://ehsinspections.uml.edu/create.aspx";
		
		// need to move to UI code as webview is only for mobile alone
		private function generatePDFfromByteArray(_by:ByteArray):void{
			if(_by is ByteArray){
				
				var fileName:String = "preview";
				//var header:URLRequestHeader = new URLRequestHeader("Content-type","application/octet-stream");
				var myRequest:URLRequest = new URLRequest (EHS.properties.pdfServiceUrl.value+'?name='+fileName+'&method='+ Download.INLINE );
				//myRequest.requestHeaders.push (header);
				myRequest.method = URLRequestMethod.POST;
				myRequest.data = _by;
				
				//can use only simple headers , dueot secuirty sandbox violation after flashplayer 14 update
				// turned off the headerrequestvalidation on server side
				navigateToURL(myRequest, "_blank" );	
				//navigateToURL(new URLRequest("http://www.youtube.com"),"blank");
				
				/*var webView:StageWebView = new StageWebView();
				var stage:Stage = (activeForm().formUI  as FormUI).stage;
				webView.viewPort = new Rectangle(0,20,stage.width,stage.height-20);
				webView.stage = stage;
				webView.assignFocus();
				webView.loadURL(myRequest.url);*/
				
			}
			else{
				
			}
			
		}
		
		// insert to database is called only at the time of creation
		
		public function saveSessionStateToServer():AsyncToken
		{
			if(EHS.properties.editingMode.value){
				return null;
			}
			var content:ByteArray = WeaveArchive.createWeaveFileContent();
			
			var adG:EHSAdminGateway =EHS.properties.service;
			var asyncToken:AsyncToken;
			var newFile:Boolean = false;
			if(EHS.properties.fileID.value && EHS.properties.fileID.value.length>0){
				asyncToken = adG.saveWeaveFile(content as ByteArray,EHS.properties.fileID.value,true);							
			}
			else{					
				var fileName:String =  'Weave_' + StandardLib.formatDate(new Date(), "YYYY-MM-DD_HH.NN.SS", false) + '.weave';					
				asyncToken = adG.saveWeaveFile(content as ByteArray,fileName);
				EHS.properties.fileID.value = fileName;
				newFile = true;
			}
			asyncToken.addResponder(new DelayedAsyncResponder(saveSuccessHandler, saveFailureHandler, newFile));
			return asyncToken;
		}
		
		private function saveSuccessHandler(e:ResultEvent,newFile:Boolean):void{
			if(newFile){				
				var rec:LabSafetyRecord = populateLabSafetyRecord();		
				var adG:EHSAdminGateway =EHS.properties.service;
				adG.insertToLabSafetyTable(rec);
			}
			
		}
		
		private function saveFailureHandler(e:FaultEvent,newFile:Boolean):void{
			reportError(e);
		}
		
		
		
		/******************************************************
		 * linking sessioned objects with bindable properties
		 ******************************************************/
		
		/**
		 * @inheritDoc
		 */
		public function linkBindableProperty(linkableStructure:ILinkableVariable,linkablePropertyName:String, bindableParent:Object, bindablePropertyName:String, delay:uint = 0, onlyWhenFocused:Boolean = false):void
		{
			var sm:SessionManager = WeaveAPI.SessionManager as SessionManager;
			if (linkableStructure == null || bindableParent == null || bindablePropertyName == null)
			{
				reportError("linkBindableProperty(): Parameters to this function cannot be null.");
				return;
			}
			
			if (!bindableParent.hasOwnProperty(bindablePropertyName))
			{
				reportError('linkBindableProperty(): Unable to access property "'+bindablePropertyName+'" in class '+getQualifiedClassName(bindableParent));
				return;
			}
			
			// unlink in case previously linked (prevents double-linking)
			unlinkBindableProperty(linkableStructure,linkablePropertyName, bindableParent, bindablePropertyName);
			
			if (sm.objectWasDisposed(linkableStructure))
				return;
			
			var lookup:Object = _synchronizers.get(linkableStructure, bindableParent);
			if (!lookup)
				_synchronizers.set(linkableStructure, bindableParent, lookup = {});
			lookup[bindablePropertyName] = {};
			lookup[bindablePropertyName][linkablePropertyName] = new StructureSynchronizer(linkableStructure, bindableParent, bindablePropertyName, linkablePropertyName,delay, onlyWhenFocused);
		}
		/**
		 * @inheritDoc
		 */
		public function unlinkBindableProperty(linkableVariable:ILinkableVariable, linkablePropertyName:String,bindableParent:Object, bindablePropertyName:String):void
		{
			var sm:SessionManager = WeaveAPI.SessionManager as SessionManager ;
			if (linkableVariable == null || bindableParent == null || bindablePropertyName == null || linkablePropertyName == null)
			{
				reportError("unlinkBindableProperty(): Parameters to this function cannot be null.");
				return;
			}
			
			var lookup:Object = _synchronizers.get(linkableVariable, bindableParent);
			if (lookup && lookup[bindablePropertyName][linkablePropertyName])
			{
				sm.disposeObject(lookup[bindablePropertyName][linkablePropertyName])
				delete lookup[bindablePropertyName][linkablePropertyName];
			}
		}
		/**
		 * This is a multidimensional mapping, such that
		 *     _synchronizers.dictionary[linkableVariable][bindableParent][bindablePropertyName]
		 * maps to a Synchronizer object.
		 */
		private const _synchronizers:Dictionary2D = new Dictionary2D(true, true); // use weak links to be GC-friendly
		
		
		
		
		
	
	}
}