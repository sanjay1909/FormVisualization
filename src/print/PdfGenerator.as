package print
{
	
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.utils.StringUtil;
	
	import ehs.EHS;
	import ehs.data.FollowUpData;
	import ehs.data.InspectionData;
	import ehs.services.beans.UserRecord;
	import ehs.ui.ReportImage;
	
	import org.alivepdf.colors.RGBColor;
	import org.alivepdf.events.PageEvent;
	import org.alivepdf.fonts.CoreFont;
	import org.alivepdf.fonts.FontFamily;
	import org.alivepdf.fonts.IFont;
	import org.alivepdf.layout.Align;
	import org.alivepdf.layout.Orientation;
	import org.alivepdf.layout.Size;
	import org.alivepdf.layout.Unit;
	import org.alivepdf.pdf.PDF;
	import org.alivepdf.saving.Method;
	
	import weave.core.LinkableString;
	
	public class PdfGenerator
	{	
		
		private var followUpTestRequired:Boolean = true;
		
		
		
		public function PdfGenerator()
		{
			
		}
		
		
		private var timesNewRoman:IFont = new CoreFont ( FontFamily.TIMES );					
		private var timesNewRomanItalic:IFont = new CoreFont ( FontFamily.TIMES_ITALIC );
		private var timesNewRomanBold:IFont = new CoreFont ( FontFamily.TIMES_BOLD );
		private var pdfX:Number;
		private var pdfY:Number;
		
		
		private var lineHeight:Number = 14;
		
		private var questionAndComSpace:Number = 6;
		private var commentAndImageSpace:Number = 0;
		private var paraSpace:Number = 10;
		private var betweenInspectionDataSpace:Number = 15;
		private var sectionHeadingSpace:Number = 12;
		private var insDatasAndSecComSpace:Number = 15;
		
		private var betweenSectionSpace:Number = 20;
				
		private var itemSpace:Number = 16;
		private var sectionSpace:Number = 18;
		
		private var formBeginDate:Date = null;
		private var formDuedate:Date= null;
		
		private function rightAlign(p:PDF,pts:Number):void{
			p.setX(pts);
		}
		
		private function placeFrontPage():void{
			p.addPage();
			placeLetterHead();			
			placeInspector();
			placeLabReportNote();
			
		}
		
		private function placeLetterHead():void{
			var pm:ServerManager = WeaveAPI.ClassRegistry.getSingletonInstance(IServerManager) as ServerManager;
			var cellHeight:Number = 14;
			
			p.setFont( timesNewRomanBold, 12,false );			
			p.addMultiCell(0,cellHeight,pm.printParameters.DEPARTMENT,0,Align.RIGHT);
			var deptWidth:Number = p.calculateParaWidthFor(pm.printParameters.DEPARTMENT);
			p.setFont( timesNewRoman, 10,false );	
			var yPos:Number = p.getY();
			p.addImage(EHS.properties.umassLogo,null,0,0,60,72);
			yPos = p.getY();
			var xPos:Number = p.getCurrentPage().w - p.getRightMargin() - deptWidth;
			
			p.addParagraph(pm.printParameters.CONTACT,cellHeight,Align.RIGHT);			
			p.addParagraph(pm.printParameters.ADDRESS,cellHeight,Align.LEFT,xPos,yPos);
		}
		
		
		private var inspector:UserRecord;
		private function placeInspector():void{
			var pm:ServerManager =  WeaveAPI.ClassRegistry.getSingletonInstance(IServerManager) as ServerManager;
			p.setY(p.getY() + 36);
			//activeForm().formData
			inspector = pm.inspectorInfo as UserRecord;
			p.setFont( timesNewRomanBold, 12,false );
			var safetyInspector:String = inspector.firstName.value +" "+ inspector.lastName.value +", " +inspector.qualification.value;
			p.addMultiCell(300,18,safetyInspector,0);
			p.setFont( timesNewRomanItalic, 12,false );	
			p.addMultiCell(320,18,inspector.position.value,0);			
			/*p.setFont( timesNewRoman, 12,false );	
			p.addMultiCell(200,18,ins.InspectorEmail,0);*/	
		}
		
		private function placeLabReportNote():void{
			var pm:ServerManager =  WeaveAPI.ClassRegistry.getSingletonInstance(IServerManager) as ServerManager;
			var lineSpace:Number = 20;
			var lineHeight:Number = 16;
			p.setFont( timesNewRoman, 12,false );
			p.setY(p.getY() + lineSpace);
			if(pm.keyData.isProfessor.value){
				p.writeText(lineHeight ,"Dear "+ "Professor " + pm.keyData.principalInvestigator.value +",");
			}
			else{
				p.writeText(lineHeight ,"Dear "+ pm.keyData.principalInvestigator.value +",");
			}
			
			p.setY(p.getY() + lineSpace);
			p.addParagraph(pm.printParameters.PARA1,lineHeight,Align.JUSTIFIED,-1,-1);
		
			p.setY(p.getY() + lineSpace );
			
			p.writeText(lineHeight,"Sincerely,");
			p.setY(p.getY() + lineSpace);
			p.writeText(lineHeight,"EEM-EHS Staff");
			
		}
		
		
		
		private function placeKeyElements():void{
			var columnNum:int = 0;
			var pm:ServerManager =  WeaveAPI.ClassRegistry.getSingletonInstance(IServerManager) as ServerManager;
			var keyMap:Array = pm.keyData.getDataAsArray();			
			for(var i:int = 0 ; i <keyMap.length ; i++){					
					columnNum = columnNum + 1;
					var keyCellWidth:Number;
					var QApairs:Array = keyMap[i];
					if(columnNum == 2){
						keyCellWidth = 90;						
					}
					else{
						keyCellWidth = 130;
					}
					
					// Print Label
					var keyName:String  = QApairs[0] + ":";
					p.setFont( timesNewRomanBold, 12,false );
					p.textStyle( new RGBColor(0x000000), 1 );						
					pdfY = p.getY();
					p.addMultiCell(keyCellWidth,18,keyName,0,Align.LEFT);
					p.setY(pdfY);
					pdfX = pdfX + keyCellWidth;
					p.setX(pdfX);
					
					// print Answers
					var answers:String = "";
					if(QApairs[1] is Array)	answers = (QApairs[1] as Array).join(",");
					else answers = QApairs[1]; 
					p.setFont( timesNewRomanItalic, 12,false );
					p.textStyle( new RGBColor(0x000000), 1 );
					
					
					if(columnNum == 2){
						p.addMultiCell(130,18,answers,0,Align.LEFT);
						pdfX = p.getLeftMargin();	
						pdfY = p.getY();
						columnNum = 0;
						
					}
					else{
						p.addMultiCell(130,18,answers,0 ,Align.LEFT);
						pdfX = pdfX + 130;
						// important not to set pdfy as we need to write in two columns
					}
					p.setXY(pdfX,pdfY);
								
			}
		}
		
		private function placeStatusAndRemarks():Boolean{
			var pm:ServerManager =  WeaveAPI.ClassRegistry.getSingletonInstance(IServerManager) as ServerManager;
			var str:String = pm.getFormStatusForPDF();
			if(str.length > 0){
				p.setFont( timesNewRomanBold, 16,false );
				p.textStyle( new RGBColor(0x000000), 1 );
				p.addMultiCell(0,16,str);
				return true;
			}
			return false;
		}
		
		private function placeFormComment():Boolean{
			var pm:ServerManager =  WeaveAPI.ClassRegistry.getSingletonInstance(IServerManager) as ServerManager;
			var str:String = pm.reportData.formComment.value
			if(str && str.length > 0){
				p.setFont( timesNewRomanBold, 14,false );
				p.textStyle( new RGBColor(0x000000), 1 );
				p.addMultiCell(0,14,str);
				return true;
			}
			return false;
		}
		
		private function placeSectionComment(secData:Object,hadInsDatas:Boolean):void{
			
			
			var sectionComment:String = StringUtil.trim((secData.comment as LinkableString).value) ;
			if(sectionComment.length > 0){
				if(hadInsDatas){
					pdfY = p.getY() + insDatasAndSecComSpace;
					p.setY(pdfY);
				}
				startBorder();
				p.setFont( timesNewRoman, 12 );
				p.textStyle( new RGBColor(0x000000), 1 );
				p.writeText(lineHeight,secData.title+ " Comment: \n");
				pdfY = p.getY() + questionAndComSpace
				p.setY(pdfY);
				p.setFont( timesNewRoman, 12 );
				p.textStyle( new RGBColor(0x000000), 1 );
				p.addMultiCell(0,lineHeight,sectionComment + "\n");						
			}
			var imageURLS:Array =secData.images.getObjects();
			var images:Array = ReportImage.imagesAsBitmapData(imageURLS);
			if(images.length > 0){
				pdfY = p.getY() + commentAndImageSpace;
				p.setY(pdfY); 
				placeImage(images);
			}
			else{
				pdfY = p.getY() ;
				p.setY(pdfY);				
			}
			completeBorder();
		}
		
		
		private function placeInspectionData(insData:InspectionData,secNum:int,quesNum:int):void{
			//question and priority section
			var question:String = "["+secNum +"."+ quesNum + "] " +(insData.question as LinkableString).value +"  - No \n";
			p.setFont( timesNewRoman, 12 );
			p.textStyle( new RGBColor(0x000000), 1 );
			p.addMultiCell(0,lineHeight,question,0,Align.LEFT);
			if((insData.priority as LinkableString).value == "high"){
				p.setFont( timesNewRomanItalic, 12 );
				p.textStyle( new RGBColor(0xFF0000), 1 );
				p.addMultiCell(0,lineHeight,"     This is a crictical deficiency. Please correct within 48 hours.",Align.LEFT);
			}
			pdfY = p.getY() + questionAndComSpace;
			p.setY(pdfY);
			var commentPDF:String = StringUtil.trim((insData.comment as LinkableString).value);
			// temp - workaround, till i find a better solution
			// Textarea adds one backslash in Text property, \n is converted to \\n and causing to print \n instead of linebreak
			var pattern:RegExp = new RegExp("\\\\n", "g");
			commentPDF  = commentPDF.replace(pattern,"\n");
			if(commentPDF.length > 0){
				p.setFont( timesNewRoman, 12 );				
				p.textStyle( new RGBColor(0x000000), 1 );
				p.addMultiCell(0,lineHeight,commentPDF);
			}
			
		}
		
		private function placeFollowUpdata(followUp:FollowUpData):void{
			//question and priority section
			p.setFont( timesNewRoman, 12 );
			p.textStyle( new RGBColor(0x000000), 1 );
			var commentPDF:String = StringUtil.trim((followUp.comment as LinkableString).value);
			// temp - workaround, till i find a better solution
			// Textarea adds one backslash in Text property, \n is converted to \\n and causing to print \n instead of linebreak
			var pattern:RegExp = new RegExp("\\\\n", "g");
			commentPDF  = commentPDF.replace(pattern,"\n");
			if(commentPDF.length > 0){
				p.setFont( timesNewRoman, 12 );				
				p.textStyle( new RGBColor(0x000000), 1 );
				p.addMultiCell(0,lineHeight,commentPDF);
			}
			
		}
		
		private function placeImage(imgCollection:Array):void{
			var len:int = imgCollection.length;
					
			for (var index:Number = 0;index < len; index = index + 2){
				var imgAndLabel:DisplayObject = imgCollection[index]  as DisplayObject;
				var imageArrays:Array;
				if(index + 1 == len){
					imageArrays = [imgAndLabel];
				}
				else{
					var imgAndLabel2:DisplayObject = imgCollection[index + 1]  as DisplayObject;
					imageArrays = [imgAndLabel,imgAndLabel2];
				}
				p.addImageRowsAtExactPoint(imageArrays,p.getLeftMargin(),p.getY());				
			}			
		}
		
		private function pageAdditionListener(e:PageEvent):void{
		
			if(isBorderExist){
				p.gotoPage((p.getPages().length)- 1);
				p.setY(p.pageBreakValue());
				completeBorder();
				p.gotoPage(p.getPages().length);
				p.setY(p.getTopMargin());
				startBorder();
			}
		}
		
		private var borderX:Number;
		private var borderY:Number;
		private var isBorderExist:Boolean = false;
		private function startBorder():void{
			borderX = p.getLeftMargin();
			borderY = p.getY();
			isBorderExist = true;
			
		}
		
		private var borderWidth:Number;
		private var borderHeight:Number;
		private function completeBorder():void{
			borderWidth = p.getCurrentPage().w - p.getLeftMargin() - p.getRightMargin();
			borderHeight = p.getY() - borderY;
			if(borderHeight >= 14){
				p.drawRect(new Rectangle(borderX,borderY - 3,borderWidth,borderHeight + 3));
			}
			
			isBorderExist = false;
		}
		
		private var p:ExtendedPDF;
		public function createPDF():ByteArray
		{				
			
			p = new ExtendedPDF( Orientation.PORTRAIT, Unit.POINT, Size.A4 );	
			p.addEventListener(PageEvent.ADDED,pageAdditionListener);
			p.setMargins(72,72,72,72);			
			p.setAutoPageBreak(true,72);
			
			placeFrontPage();
			
			p.addPage();
			
			
			pdfX = p.getX();					
			pdfY = p.getY();
			
			//------ Report form heading -------//
			p.setFont( timesNewRomanBold, 16,true );
			p.textStyle( new RGBColor(0x000000), 1 );
			var PDFheading:String = "EEM-EHS Lab Inspection Report";								
			p.addMultiCell(0,16,PDFheading,0,Align.CENTER);
			
			//------ Key Elements -------//
			p.setY(p.getY() + 20);
			placeKeyElements();
			p.setY(p.getY() + 20);			
			pdfX = p.getLeftMargin();
			
			
			var isPrinted:Boolean
			//------ Status Remark -------//
			p.setY(p.getY() + 20);
			isPrinted = placeStatusAndRemarks();
			if(isPrinted){
				p.setY(p.getY() + 16);			
				pdfX = p.getLeftMargin();
			}
			
			
			//------ Status Remark -------//
			p.setY(p.getY() + 16);
			isPrinted = placeFormComment();
			if(isPrinted){
				p.setY(p.getY() + 20);			
				pdfX = p.getLeftMargin();
			}
			
			
			
			
			//------ Loop through Sections -------//	
			var pm:ServerManager =  WeaveAPI.ClassRegistry.getSingletonInstance(IServerManager) as ServerManager;
			//required as Dictioanry doesnt givet the order at which it is added
			var sectionOrder:Array = pm.sectionOrder;
			var sections:Dictionary = pm.sectionFilledDataMap ;
			var secNumber:int = 0;
			for(var keyIndex:int = 0 ; keyIndex < sectionOrder.length ; keyIndex++){
				var sectionName:String = sectionOrder[keyIndex];
				var filledDatas:ArrayCollection = sections[sectionName];
									
				//+++++ Print section Heading ++++++//
				pdfY = p.getY() + sectionSpace;
				p.setY(pdfY);
				
				secNumber = secNumber + 1;
				var sectionHeading:String;
				sectionHeading = "["+secNumber+"] " + sectionName + "\n";
				p.setFont( timesNewRoman, 14,true );
				p.textStyle( new RGBColor(0x000000), 1 );													
				p.writeText(lineHeight,sectionHeading);	
				pdfY = p.getY() + sectionHeadingSpace;
				p.setY(pdfY);
				
				
				//******** Loop through Inspection Data ********//
				var len:int = filledDatas.length;
				for(var i:int = 0 ;i <len; i++){
					var insData:InspectionData  = filledDatas.getItemAt(i) as InspectionData;
					//******** Print inspection data ********//
					startBorder();// ------------border started
					placeInspectionData(insData,secNumber,i + 1);
					
					
					//******** loop inspection data images and print ********//
					var imageURLS:Array =insData.images.getObjects();
					var images:Array = ReportImage.imagesAsBitmapData(imageURLS);
					
					if(images.length > 0){
						 pdfY = p.getY() + commentAndImageSpace;//->->-----> adding space
						 p.setY(pdfY);
						 placeImage(images);
					 }				
					 
					completeBorder();// ------------border Completed
					// add followup comment and image if any
					var followUps:Array = insData.followUps.getObjects() as Array;
					if(followUps.length){
						for(var fi:int = 0 ; fi < followUps.length ; fi++){
							var followUpData:FollowUpData = followUps[fi] as FollowUpData;
							placeFollowUpdata(followUpData);
							var followUpImageURLS:Array =followUpData.images.getObjects();
							var followUpImages:Array = ReportImage.imagesAsBitmapData(followUpImageURLS);
							if(followUpImages.length > 0){
								pdfY = p.getY() + commentAndImageSpace;//->->-----> adding space
								p.setY(pdfY);
								placeImage(followUpImages);
							}	
						}
					}
					
					if(i != len -1){
						pdfY = p.getY() + betweenInspectionDataSpace;
						p.setY(pdfY);
					}	
					else{
						pdfY = p.getY();
						p.setY(pdfY);
					}						
				}
				
				//******** Print Section comment ********//
				var hadInsDatas:Boolean;
				if( len > 0){
					hadInsDatas = true;
				}
				else{
					hadInsDatas = false;
				}
				var secData:Object = pm.sectionCommentMap[sectionName];
				if(secData)
					placeSectionComment(secData,hadInsDatas);
				
			}
			
			//******** Print Contact Details********//
			pdfY = p.getY() + sectionSpace;
			p.setY(pdfY);
			printContactDetails();
			
			var by:ByteArray = p.save(Method.LOCAL);
			
			
			
			//p.save(Method.REMOTE, "http://ehsinspections.uml.edu/create.aspx",Download.INLINE,"preview.pdf");
			/* alertMsg = "Stored in Desktop as,";	
			alertMsgWithFileName = ""+fileName +".pdf" */
			
			return by;
		}		
		
		public function printContactDetails():void{
			var pm:ServerManager =  WeaveAPI.ClassRegistry.getSingletonInstance(IServerManager) as ServerManager;
			var str:String = pm.getContactStatusForPDF();
			p.setFont( timesNewRomanBold, 14,false );
			p.textStyle( new RGBColor(0x000000), 1 );
			p.addMultiCell(0,lineHeight,str);
		}
		
		
		
	}
}