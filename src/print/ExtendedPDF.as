package print
{
	
	
	import flash.display.DisplayObject;
	
	import org.alivepdf.fonts.FontMetrics;
	import org.alivepdf.layout.Resize;
	import org.alivepdf.layout.Size;
	import org.alivepdf.links.ILink;
	import org.alivepdf.pdf.PDF;
	
	public class ExtendedPDF extends PDF
	{
		public function ExtendedPDF(orientation:String="Portrait", unit:String="Mm", pageSize:Size=null, rotation:int=0)
		{
			super(orientation, unit, pageSize, rotation);
		}
		
		public static const IMAGE_WIDTH:Number = 200;
		public static const IMAGE_HEIGHT:Number = 200;
		
		public static const ALLOWED_PADDING:Number = 17.09;
		
		public function getRightMargin():Number{
			return rightMargin;
		}
		
		public function getLeftMargin():Number{
			return leftMargin;
		}
		
		public function getTopMargin():Number{
			return topMargin;
		}
		
		public function getBottomMargin():Number{
			return bottomMargin;
		}
		
		public function printPageWidth():Number{
			return currentPage.w - leftMargin - rightMargin;
		}
		
		public function printPageHeight():Number{
			return currentPage.h  - bottomMargin;
		}
		
		public function pageBreakValue():Number{
			return pageBreakTrigger
		}
		
		public function addImageAtExactPoint( displayObject:DisplayObject, x:Number=0,y:Number=0):void
		{
			var width:Number = displayObject.width;
			var height:Number = displayObject.height;
			
			
			x = x-leftMargin ;
			y = y-topMargin + ALLOWED_PADDING ;			
			addImage(displayObject,null , x,y,width,height);
			
		}
		
		
		public function addImageRowsAtExactPoint( displayObjects:Array, x:Number=0,y:Number=0):void
		{
			var maxImageHeight:Number;
			if(displayObjects.length==2)
				maxImageHeight = ((displayObjects[0] as DisplayObject).height > (displayObjects[1] as DisplayObject).height)?(displayObjects[0] as DisplayObject).height :(displayObjects[1] as DisplayObject).height;
			else
				maxImageHeight = (displayObjects[0] as DisplayObject).height;
			
			if(isPageBreakRequired(y + maxImageHeight + ALLOWED_PADDING)){
				addPage();	
				x = leftMargin;
				y = topMargin;
			}
			if(displayObjects.length==1){				
					x = leftMargin + (printPageWidth() - (displayObjects[0] as DisplayObject).width)/2 ;				
			}
			else{
				var deltaX:Number = 0;
				var width:Number = (displayObjects[0] as DisplayObject).width;
				if(width < IMAGE_WIDTH){
					deltaX = (IMAGE_WIDTH - width)/2;
				}				
				x = leftMargin  + ALLOWED_PADDING + deltaX;
			}
			
			for(var i:int=0 ; i<displayObjects.length; i++){
				
				addImageAtExactPoint(displayObjects[i],x,y);
				x = x + IMAGE_WIDTH +  ALLOWED_PADDING;
			}			
			setY(y + maxImageHeight + 2* ALLOWED_PADDING);
		}
		 
		public function addParagraph(text:String,lineHeight:Number,align:String='J',xPos:Number = -1,yPos:Number = -1):void
		{
			
			// need to be set first , as it sets current x value too
			if(yPos > -1){
				setY(yPos);
			}
			if(xPos > -1){
				setX(xPos);
			}				
			addMultiCell(0, lineHeight, text, 0, align, 0);
		}
		
		public function calculateParaWidthFor(text:String):Number{
			var stringWidth:int = 0;
			var s:String = findAndReplace ("\r",'',text);
			var char:String;			
			var charWidth:int = 0;
			var numOfChar:int = s.length;
			if( numOfChar > 0 && s.charAt(numOfChar-1) == "\n" ) 
				numOfChar--;
			
			var i:int = 0;
			var currentMaxStringWidth:int = stringWidth;
			while (i < numOfChar)
			{			
				char = s.charAt(i);	
				
				if (char=="\n")
				{		
					if(stringWidth >  currentMaxStringWidth)
						currentMaxStringWidth = stringWidth;
					i++;
					stringWidth = 0;					
					continue;			
				}
				charWidth = charactersWidth[char] as int;
				
				if (charWidth == 0) 
					charWidth = FontMetrics.DEFAULT_WIDTH;
				
				stringWidth += charWidth;				
				i++;
			}
			if(stringWidth >  currentMaxStringWidth)
				currentMaxStringWidth = stringWidth;
			
			var strWidthInPt:Number = ((currentMaxStringWidth * fontSize)/I1000) + (2*currentMargin) ;
			return strWidthInPt;
		}
		
		public function calculateNumberOfLinesFor(text:String):int{
			var availableWidth:Number =  currentPage.w - rightMargin - currentX;
			var maxStrWidth:Number = (availableWidth-2*currentMargin)*I1000/fontSize;
			
			var s:String = findAndReplace ("\r",'',text);			
			var numOfChar:int = s.length;			
			if( numOfChar > 0 && s.charAt(numOfChar-1) == "\n" ) 
				numOfChar--;
			
			
			var i:int = 0;			
			var stringWidth:int = 0;			
			var numOfLine:int = 1;
			var char:String;			
			var charWidth:int = 0;
			
			while (i < numOfChar)
			{			
				char = s.charAt(i);									
				charWidth = charactersWidth[char] as int;
				
				if (charWidth == 0) 
					charWidth = FontMetrics.DEFAULT_WIDTH;
				
				stringWidth += charWidth;
				
				if (stringWidth > maxStrWidth)
				{					
					stringWidth = 0;
					numOfLine++;					
				}
				i++;
			}
			return numOfLine;
		}
		override protected function placeImage ( x:Number, y:Number, width:Number, height:Number, rotation:Number, resizeMode:Resize, link:ILink ):void
		{
		/*	if ( width == 0 && height == 0 )
			{
				width = image.width/k;
				height = image.height/k;
			}
			
			if ( width == 0 ) 
				width = height*image.width/image.height;
			if ( height == 0 ) 
				height = width*image.height/image.width;
			
			var realWidth:Number = currentPage.width-(leftMargin+rightMargin)*k;
			var realHeight:Number = currentPage.height-(bottomMargin+topMargin)*k;
			
			var xPos:Number = 0;
			var yPos:Number = 0;
			
			if ( resizeMode == null )
				resizeMode = new Resize ( Mode.NONE, Position.LEFT );
			
			if ( resizeMode.mode == Mode.RESIZE_PAGE )
				currentPage.resize( image.width+(leftMargin+rightMargin)*k, image.height+(bottomMargin+topMargin)*k, k );
				
			else if ( resizeMode.mode == Mode.FIT_TO_PAGE )
			{			
				var ratio:Number = Math.min ( realWidth/image.width, realHeight/image.height );
				
				if ( ratio < 1 )
				{
					width *= ratio;
					height *= ratio;
				}
			}
			
			if ( resizeMode.mode != Mode.RESIZE_PAGE )
			{		
				if ( resizeMode.position == Position.CENTERED )
				{	
					x = (realWidth - (width*k))*.5;
					y = (realHeight - (height*k))*.5;
					
				} else if ( resizeMode.position == Position.RIGHT )
					x = (realWidth - (width*k));
			}
			
			xPos = (resizeMode.position == Position.LEFT && resizeMode.mode == Mode.NONE) ? (x+leftMargin)*k : x+leftMargin*k;
			yPos = (resizeMode.position == Position.CENTERED && resizeMode.mode != Mode.RESIZE_PAGE) ? y+(bottomMargin+topMargin)*k : ((currentPage.h-topMargin)-(y+height))*k;
			
			
			
			
		
			var yPoss:Number;
			yPoss = y+(bottomMargin+topMargin)*k ;
			yPoss = ((currentPage.h-topMargin)-(y+height))*k;*/
			super.placeImage(x,y,width,height,rotation,resizeMode,link);
			
			/*var resizeModeposition:Boolean = (resizeMode.position == Position.CENTERED );
			var resizeModemode:Boolean = (resizeMode.mode != Mode.RESIZE_PAGE);
			
			if(resizeModeposition && resizeModemode){
				yPoss = y+(bottomMargin+topMargin)*k ;
			}
			else{
				yPoss = ((currentPage.h-topMargin)-(y+height))*k;
			}*/
		/*	yPoss = y+(bottomMargin+topMargin)*k ;
			yPoss = ((currentPage.h-topMargin)-(y+height))*k;
			
			*/
		}
		
		override public function addImage ( displayObject:DisplayObject, resizeMode:Resize=null, x:Number=0, y:Number=0, width:Number=0, height:Number=0, rotation:Number=0, alpha:Number=1, keepTransformation:Boolean=true, imageFormat:String="PNG", quality:Number=100, blendMode:String="Normal", link:ILink=null ):void
		{
			
			super.addImage(displayObject,resizeMode,x,y,width,height,rotation,alpha,keepTransformation,imageFormat,quality,blendMode,link);
			
		}
	}
}