package ehs.data
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.net.URLRequest;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import ehs.ui.ReportImage;
	
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.reportError;
	import weave.api.core.ILinkableObject;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableString;
	
	public class FollowUpData implements ILinkableObject
	{
		public function FollowUpData()
		{
		}
		
		public const comment:LinkableString = newLinkableChild(this,LinkableString);		
		public const images:LinkableHashMap = registerLinkableChild(this,new LinkableHashMap(LinkableString),populateImagesForPDF,true);
		
		
		
		public function populateImagesForPDF():void{
			
			var arr:Array = images.getNames();
			for(var i:int = 0; i < arr.length;i++){
				var imgUI:ReportImage = new ReportImage();
				var imageUrl:String = (images.getObject(arr[i]) as LinkableString).value;
				if (imageUrl && ReportImage.urlToImageMap[imageUrl] === undefined) // only request image if not already requested
				{
					//called Sessionstatelaoded to populate in URL images in ReportImage
					ReportImage.urlToImageMap[imageUrl] = null; // set this here so we don't make multiple requests
					WeaveAPI.URLRequestUtils.getContent(this, new URLRequest(imageUrl), handleImageDownload, handleFault, imageUrl);
				}
				/*else{
				imagesAsBitmapData.push(ReportImage.urlToImageMap[imageUrl]);
				}*/
			}
		}
		
		
		private var imageWidth:Number = 200;
		private var imageHeight:Number= 200;
		private function handleImageDownload(event:ResultEvent, token:Object = null):void
		{
			var bitmap:Bitmap = event.result as Bitmap;
			
			var bitmapData:BitmapData = bitmap.bitmapData;
			
			var imageOriginalWidth:Number = bitmapData.width;
			var imageOriginalHeight:Number = bitmapData.height;
			if(imageOriginalWidth > imageOriginalHeight){
				bitmap.width = imageWidth;
				bitmap.height = imageOriginalHeight *  imageWidth / imageOriginalWidth ;
			}
			else{
				bitmap.height = imageHeight;
				bitmap.width = imageOriginalWidth *  imageHeight / imageOriginalHeight ;
			}	
			ReportImage.urlToImageMap[token] = bitmap;
			//imagesAsBitmapData.push(bitmap);
			
		}
		
		/**
		 * This function is called when there is an error downloading an image.
		 */
		private function handleFault(event:FaultEvent, token:Object=null):void
		{
			reportError(event);
		}
		
		
	}
}