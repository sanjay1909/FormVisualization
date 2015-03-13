package com.asanjay.pod
{
	
	import com.asanjay.pod.events.PodEvent;
	import com.asanjay.pod.itemrenderer.PodListItemRenderer;
	import com.asanjay.pod.skins.PodListMinimizedSkin;
	import com.asanjay.pod.ui.DragHighlight;
	import com.asanjay.pod.ui.PodWindow;
	
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.core.ClassFactory;
	import mx.core.FlexGlobals;
	import mx.effects.Move;
	import mx.effects.Parallel;
	import mx.effects.easing.Exponential;
	import mx.events.DragEvent;
	import mx.events.ResizeEvent;
	
	import spark.components.Group;
	import spark.components.List;
	import spark.components.SkinnableContainer;
	import spark.effects.Resize;
	import spark.layouts.HorizontalLayout;
	import spark.layouts.VerticalLayout;

	public class PodLayoutManager extends SkinnableContainer
	{
		public function PodLayoutManager()
		{
			super();
			percentWidth =100;
			percentHeight = 100;
			
		}
		
		private const podList:List = new List();
		private const minimizedPods:ArrayCollection = new ArrayCollection();
		
		private const podContainer:Group = new Group();
		private const verticalLayout:VerticalLayout = new VerticalLayout();
		private const horizaontalLayout:HorizontalLayout = new HorizontalLayout();
		
		private const verticalListLayout:VerticalLayout = new VerticalLayout();
		private const horizaontalListLayout:HorizontalLayout = new HorizontalLayout();
		
		override protected function createChildren():void{
			podContainer.percentWidth =100;
			podContainer.percentHeight = 100;
			verticalListLayout.paddingBottom = verticalListLayout.paddingTop = 3;
			verticalListLayout.paddingLeft = verticalListLayout.paddingRight = 3;
			podList.layout = verticalListLayout;
			this.addElement(podList);
			this.addElement(podContainer);
			this.layout = horizaontalLayout;
			
			
			super.createChildren();
			podList.dataProvider = minimizedPods;
			podList.itemRenderer =  new ClassFactory(PodListItemRenderer);
			podList.setStyle("skinClass",PodListMinimizedSkin);
			podContainer.addEventListener(ResizeEvent.RESIZE, reSizeListener);
			
			FlexGlobals.topLevelApplication.addEventListener(PodEvent.RESTORE, onRestorePod);
			
			
		}
		
		private function reSizeListener(event:ResizeEvent):void{
			updateLayout();
		}
		
		//public var id:String;
		public var items:Array = new Array();					// Stores the pods which are not minimized.
		//public var minimizedItems:Array = new Array();			// Stores the minimized pods.
		public var maximizedPod:PodWindow;
		
		private var dragHighlightItems:Array = new Array();		// Stores the highlight items used to designate a drop area.
		private var gridPoints:Array = new Array();				// Stores the x,y of each pod in the grid.
		
		private var currentDragPod:PodWindow;							// The current pod which the user is dragging.
		private var currentVisibleHighlight:DragHighlight;		// The current highlight that is visible while dragging.
		private var currentDropIndex:Number;					// The index of where to drop the pod while dragging.
		private var currentDragPodMove:Move;					// The move effect used to transition the pod after it is released from dragging.
		
		private var parallel:Parallel;							// The main effect container.
		private var maximizeParallel:Parallel;
		
		private var itemWidth:Number;							// Pod width.
		private var itemHeight:Number;							// Pod height.
		
		private static const POD_GAP:Number = 4;				// The vertical and horizontal gap between pods.
		private static const TASKBAR_HEIGHT:Number = 24;		// The height of the area for minimized pods.
		private static const TASKBAR_HORIZONTAL_GAP:Number = 4; // The horizontal gap between minimized pods.
		private static const TASKBAR_ITEM_WIDTH:Number = 150;	// The preferred minimized pod width if there is available space.
		private static const TASKBAR_PADDING_TOP:Number = 4;	// The gap between the taskbar and the bottom of the last row of pods.
		private static const PADDING_RIGHT:Number = 0;			// The right padding within the container when laying out pods.
		
		
		
		
		private function updateLayout():void{
			var len:Number = items.length;
			var sqrt:Number = Math.floor(Math.sqrt(len));
			var numCols:Number = Math.ceil(len / sqrt);
			var numRows:Number = Math.ceil(len / numCols);
			var col:Number = 0;
			var row:Number = 0;
			var availablePodWidth:Number = podContainer.width;
			var availablePodHeight:Number = podContainer.height;
			
			var podWidth:Number = Math.round(availablePodWidth / numCols - ((POD_GAP * (numCols - 1)) / numCols));
			var podHeight:Number = Math.round(availablePodHeight / numRows - ((POD_GAP * (numRows - 1)) / numRows));
			
			if (parallel != null && parallel.isPlaying)
				parallel.pause();
			
			
			
			// Layout the pods.
			for (var i:Number = 0; i < len; i++)
			{
				if(i % numCols == 0 && i > 0)
				{
					row++;
					col = 0;
				}
				else if(i > 0)
				{
					col++;
				}
				
				var podX:Number = col * podWidth;
				var podY:Number = row * podHeight;
				
				if(col > 0) 
					podX += POD_GAP * col;
				if(row > 0) 
					podY += POD_GAP * row;
				
				podX = Math.round(podX);
				podY = Math.round(podY);
				
				var pod:PodWindow = items[i] as PodWindow;
				
				
				if (pod.mode == PodWindow.WINDOW_MAXIMIZED)// Window is maximized so do not include in the grid
				{
					pod.width = availablePodWidth;
					pod.height = availableMaximizedPodHeight;
					podContainer.setElementIndex(pod, podContainer.numElements - 1);
				}
				else{
					pod.width = podWidth;
					pod.height = podHeight;
					pod.x = podX;
					pod.y = podY;
				}
				
				if(pod.mode == PodWindow.WINDOW_MINIMIZED){
					podContainer.addElement(pod);
					podContainer.addElement(pod);
					 dragHighlight:DragHighlight = new DragHighlight();
					dragHighlightItems.push(dragHighlight)
					podContainer.addElement(dragHighlight);
				}
					
				
				
				pod.index = i;
				gridPoints[i] = new Point(podX, podY);
				
				
				
			}
			
			if (parallel != null && parallel.children.length > 0)
				parallel.play();
			
			// Layout the drag highlight items.
			len = dragHighlightItems.length;
			for (i = 0; i < len; i++)
			{
				var dragHighlight:DragHighlight = DragHighlight(dragHighlightItems[i]);
				if (i > (items.length - 1)) // The corresponding item is minimized so hide the highlights not being used.
				{
					dragHighlight.visible = false;
					dragHighlight.x = 0;
					dragHighlight.y = 0;
					dragHighlight.width = 0;
					dragHighlight.height = 0;
				}
				else
				{
					var point:Point = Point(gridPoints[i]);
					dragHighlight.x = point.x;
					dragHighlight.y = point.y;
					dragHighlight.width = itemWidth;
					dragHighlight.height = itemHeight;
					podContainer.setElementIndex(dragHighlight, i); // Move the hightlights to the bottom of the z-index.
				}
			}
		}
		
		
		
		//Weave: Added this function to support their index parameter in additemAt
		public function addPod(pod:PodWindow,  toList:Boolean):void
		{	
			initItem(pod);
			if(toList){
				minimizedPods.addItem(pod);
				pod.mode = PodWindow.WINDOW_MINIMIZED;
			}else{
				
				items.push(pod);
				// Add a highlight for each pod. Used to show a drop target box.
				
				podContainer.addElement(pod);
				var dragHighlight:DragHighlight = new DragHighlight();
				dragHighlightItems.push(dragHighlight)
				podContainer.addElement(dragHighlight);
				updateLayout();
			}
			
			
			
		}
		
		
		
		
		
		private function initItem(pod:PodWindow):void
		{
					
			pod.addEventListener(DragEvent.DRAG_START, onDragStartPod);
			pod.addEventListener(DragEvent.DRAG_COMPLETE, onDragCompletePod);
			pod.addEventListener(PodEvent.MAXIMIZE, onMaximizePod);
			pod.addEventListener(PodEvent.MINIMIZE, onMinimizePod);
			//pod.addEventListener(PodEvent.RESTORE, onRestorePod);
			pod.addEventListener(PodEvent.CLOSE, onClosePod);
			
			
		}
		public var effectDuration:int = 1000; // added for Weave
		// Pod has been maximized.
		private function onMaximizePod(e:PodEvent):void
		{
			
			var pod:PodWindow = PodWindow(e.currentTarget);
			maximizeParallel = new Parallel();
			
			maximizeParallel.duration = effectDuration;
			
			addResizeAndMoveToParallel(pod, maximizeParallel, availablePodWidth, availableMaximizedPodHeight, 0, 0);
			maximizeParallel.play();
			
			maximizedPod = pod;
			//dispatchEvent(new LayoutChangeEvent(LayoutChangeEvent.UPDATE));
		}
		
		// Creates a resize and move event and adds them to a parallel effect.
		private function addResizeAndMoveToParallel(target:PodWindow,parallel:Parallel,  widthTo:Number, heightTo:Number, xTo:Number, yTo:Number):void
		{
			var resize:Resize = new Resize(target);
			resize.widthTo = widthTo;
			resize.heightTo = heightTo;
			//resize. = Exponential.easeOut;
			parallel.addChild(resize);
			
			var move:Move = new Move(target);
			move.xTo = xTo;
			move.yTo = yTo;
			move.easingFunction = Exponential.easeOut;
			parallel.addChild(move);
		}
		
		
		// Returns the available width for all of the pods.
		private function get availablePodWidth():Number
		{
			return podContainer.width - PADDING_RIGHT;
		}
		
		// Returns the available height for all of the pods.
		private function get availablePodHeight():Number
		{
			return podContainer.height - TASKBAR_HEIGHT - TASKBAR_PADDING_TOP;
		}
		
		// Returns the available height for a maximized pod.
		private function get availableMaximizedPodHeight():Number
		{
			return podContainer.height;
		}
		
		// Returns the target y coord for a minimized pod.
		private function get minimizedPodY():Number
		{
			return podContainer.height - TASKBAR_HEIGHT;
		}
		// Pod has been minimized
		private function onMinimizePod(e:PodEvent):void
		{
			if (maximizeParallel != null && maximizeParallel.isPlaying)
				maximizeParallel.pause();
			
			var pod:PodWindow = PodWindow(e.currentTarget);
			items.splice(pod.index, 1);
			
			// Pod was previously maximized so there isn't a minimized pod anymore.
			if (pod.mode == PodWindow.WINDOW_MAXIMIZED)
				maximizedPod = null;
			
			//minimizedItems.push(pod);
			
			updateLayout();
			
			//dispatchEvent(new LayoutChangeEvent(LayoutChangeEvent.UPDATE));
		}
		
		//Weave: Added this function to support close event
		private function onClosePod(e:PodEvent):void
		{
			var pod:PodWindow = e.target as PodWindow;
			
			if (maximizeParallel != null && maximizeParallel.isPlaying)
				maximizeParallel.pause();
			
			items.splice(pod.index, 1);
			
			// Pod was previously maximized so there isn't a minimized pod anymore.
			if (pod.mode == PodWindow.WINDOW_MAXIMIZED)
				maximizedPod = null;
			
			if (podContainer == pod.parent)
				podContainer.removeElement(pod);
			
			closedPod = pod;
			dispatchEvent(e);
			closedPod = null;
			
			updateLayout();
		}
		public var closedPod:PodWindow = null;
		
		// Pod has been restored.
		private function onRestorePod(e:PodEvent):void
		{
			var pod:PodWindow = PodWindow(e.data);
			if (pod.mode == PodWindow.WINDOW_MAXIMIZED) // Current state is maximized
			{
				if (maximizeParallel != null && maximizeParallel.isPlaying)
					maximizeParallel.pause();
				
				maximizedPod = null;
				maximizeParallel = new Parallel();
				//Weave: Added for Weave to speed up the restore
				maximizeParallel.duration = effectDuration;
				var point:Point = Point(gridPoints[pod.index]);
				addResizeAndMoveToParallel(pod, maximizeParallel, itemWidth, itemHeight, point.x, point.y);
				maximizeParallel.play();
			}
			else if (pod.mode == PodWindow.WINDOW_MINIMIZED) // Current state is minimized so add it back to the display.
			{
				/*var len:Number = minimizedItems.length;
				for (var i:Number = 0; i < len; i++)
				{
					// Remove the minimized window from the minimized items.
					if (minimizedItems[i] == pod)
					{
						minimizedItems.splice(i, 1);
						break;
					}
				}*/
				
				if (pod.index < (items.length - 1)) // The pod index is within the range of the number of pods.
					items.splice(pod.index, 0, pod);
				else								// Out of range so add pod at the end.
					items.push(pod);
				
				updateLayout();
			}
			
			//dispatchEvent(new LayoutChangeEvent(LayoutChangeEvent.UPDATE));
		}
		
		private function onDragStartPod(e:DragEvent):void
		{
			currentDragPod = PodWindow(e.currentTarget);
			var len:Number = items.length;
			for (var i:Number = 0; i < len; i++) // Find the current drop index so we have a start point.
			{
				if (PodWindow(items[i]) == currentDragPod)
				{
					currentDropIndex = i;
					break;
				}
			}
			
			// Use the stage so we get mouse events outside of the browser window.
			FlexGlobals.topLevelApplication.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		private function onDragCompletePod(e:DragEvent):void
		{
			FlexGlobals.topLevelApplication.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			
			if (currentVisibleHighlight != null)
				currentVisibleHighlight.visible = false;
			
			// The x/y will not change if a user clicked on a header without dragging. In that case, we want to toggle the window state.
			var point:Point = Point(gridPoints[currentDropIndex]);
			if (point.x != currentDragPod.x || point.y != currentDragPod.y)
			{
				currentDragPodMove = new Move(currentDragPod);
				currentDragPodMove.easingFunction = Exponential.easeOut;
				currentDragPodMove.xTo = point.x;
				currentDragPodMove.yTo = point.y;
				currentDragPodMove.play();
				
				//dispatchEvent(new LayoutChangeEvent(LayoutChangeEvent.UPDATE));
			}
		}
		
		// Handles the live resorting of pods as one is dragged.
		private function onMouseMove(e:MouseEvent):void
		{
			var len:Number = items.length;	// Use the items since we can have more pods than highlights when a pod(s) is minimized.
			var dragHighlightItem:DragHighlight;
			var overlapArea:Number = 0; 	// Keeps track of the amount (w *h) of overlap between rectangles.
			var dragPodRect:Rectangle = new Rectangle(currentDragPod.x, currentDragPod.y, currentDragPod.width, currentDragPod.height);
			var dropIndex:Number = -1;		// The new drop index. This will create a range from currentDropIndex to dropIndex for transtions below.
			
			// Loop through the highlights and figure out which one has the greatest amount of overlap with the pod that is being dragged.
			// The highlight with the max overlap will be the drop index.
			for (var i:Number = 0; i < len; i++)
			{
				dragHighlightItem = DragHighlight(dragHighlightItems[i]);
				dragHighlightItem.visible = false;
				if (currentDragPod.hitTestObject(dragHighlightItem))
				{
					var dragHighlightItemRect:Rectangle = new Rectangle(dragHighlightItem.x, dragHighlightItem.y, dragHighlightItem.width, dragHighlightItem.height);
					var intersection:Rectangle = dragHighlightItemRect.intersection(dragPodRect);
					if ((intersection.width * intersection.height) > overlapArea)
					{
						currentVisibleHighlight = dragHighlightItem;
						overlapArea = intersection.width * intersection.height;
						dropIndex = i;
					}
				}
			}
			
			if (currentDropIndex != dropIndex) // Make sure we have a new drop index so we don't create redudant effects.
			{
				if (dropIndex == -1) // User is not over a highlight.
					dropIndex = currentDropIndex;
				
				if (currentDragPodMove != null && currentDragPodMove.isPlaying)
					currentDragPodMove.pause();
				
				if (parallel != null && parallel.isPlaying)
					parallel.pause();
				
				parallel = new Parallel();
				parallel.duration = effectDuration;
				
				var a:Array = new Array(); // Used to re-order the items array.
				a[dropIndex] = currentDragPod;
				currentDragPod.index = dropIndex;
				
				for (i = 0; i < len; i++)
				{
					var targetX:Number;
					var targetY:Number;
					var point:Point;
					var pod:PodWindow = PodWindow(items[i]);
					
					var index:Number;
					if (i != currentDropIndex)
					{
						// Find the index to determine the lookup in gridPoints.
						if ((i < currentDropIndex && i < dropIndex) ||
							(i > currentDropIndex && i > dropIndex)) // Below or above the range of dragging.
							index = i;
						else if (i > currentDropIndex && i <= dropIndex) // Drag forwards
							index = i - 1;
						else if (i < currentDropIndex && i >= dropIndex) // Drag backwards
							index = i + 1;
						else
							index = i;
						
						a[index] = pod;
						pod.index = index;
						
						point = Point(gridPoints[index]); // Get the x,y coord from the grid.
						
						targetX = point.x;
						targetY = point.y;
						
						if (targetX != pod.x || targetY != pod.y)
						{
							var move:Move = new Move(pod);
							move.easingFunction = Exponential.easeOut;
							move.xTo = targetX;
							move.yTo = targetY;
							parallel.addChild(move);
						}
					}
				}
				
				if (parallel.children.length > 0)
					parallel.play();
				
				currentDropIndex = dropIndex;
				
				// Reassign the items array so the new order is reflected.
				items = a;
			}
			
			currentVisibleHighlight.visible = true;
		}
		
		
		
				
		
		
	}
}