/*
 * Copyright (c) 2012 Christopher Rhodes
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */
package com.iopred.garland {
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.display.DisplayObject;
  import flash.display.DisplayObjectContainer;
  import flash.display.MovieClip;
  import flash.display.PixelSnapping;
  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.geom.Matrix;
  import flash.geom.Rectangle;

  /**
   * Garland.
   * A layered animation library.
   *
   * Garland provides a simple way to load animations from multiple swfs,
   * and to display them with layered graphics.
   */
  public class Garland extends Sprite implements IGarland {
    private static const GARLAND:String = "_";

    public static var COMPLETE:String = "garlandComplete";
    public static var END:String = "garlandEnd";
    public static var ERROR:String = "garlandError";
    public static var START:String = "garlandStart";

    private var activeParts:Object = {};
    private var addedLastFrame:Array = [];
    private var cacheAsBitmapValue:Boolean;
    private var looped:Boolean;
    private var parts:Object = {};
    private var playing:Boolean = true;
    private var rig:MovieClip = new MovieClip();

    protected var animationQueue:Array = [];

    internal var items:Array = [];
    internal var transforms:Object = {};

    /**
     * Constructs a new Garland object.
     */
    public function Garland() {
      addChild(rig);
      // Add the event at lowest priority, so we're the last thing updated.
      addEventListener(Event.ENTER_FRAME, onEnterFrame,
          false, int.MIN_VALUE, true);
    }

    /**
     * Given a part name, is this part an animation.
     * @returns true if the part is an animation.
     */
    public static function isAnimation(part:String):Boolean {
      return part.charAt(0) == GARLAND;
    }

    /**
     * Called whenever all items have completed loading.
     * @dispatches Garland.COMPLETE This event can be used to show the garland
     *                              when it is 'ready' useful when wanting to
     *                              show a loading spinner while items load.
     */
    private function complete():void {
      refresh();
      // We could wait for the update() call if we care about performance above
      // all else, however updating here allows listeners to get parts and use
      // the garland without waiting until the next frame.
      update();
      if (loaded) {
        dispatchEvent(new Event(COMPLETE));
      }
    }

    /**
     * Fired each frame and updates the rig.
     */
    private function onEnterFrame(event:Event):void {
      update();
    }

    /**
     * Fired whenever an item completes loading, refreshes the rig.
     */
    private function onComplete(event:Event):void {
      complete();
    }

    /**
     * Fired whenever an item fails to load, removes the item from the rig.
     */
    private function onError(event:Event):void {
      // Redispatch the error.
      dispatchEvent(event);
      removeItem(IGarland(event.target));
      complete();
    }

    /**
     * Clears all parts.
     * This will cause all parts to be redrawn.
     */
    protected function clear():void {
      while (numChildren) {
        removeChildAt(0);
      }
      parts = {};
      activeParts = {};
    }

    /**
     * For the entire display list, go to the specific frame.
     */
    protected function recursivelyGotoAndPlay(container:DisplayObjectContainer,
                                              frame:int):void {
      if (container is MovieClip) {
        MovieClip(container).gotoAndPlay(frame);
      }
      for (var i:int = 0, l:int = container.numChildren; i < l; i++) {
        var child:DisplayObjectContainer =
            container.getChildAt(i) as DisplayObjectContainer;
        if (child) {
          recursivelyGotoAndPlay(child, frame);
        }
      }
    }

    /**
     * Clear all parts, and refresh the current rig.
     * This will preserve the current frame and should be seamless.
     */
    protected function refresh():void {
      clear();
      var frame:int = currentFrame;
      // Preserve the current queue, unshift the current animation so it is not
      // thrown away.
      var queue:Array = animationQueue;
      queue.unshift(animation);
      animations = queue;
      if (playing) {
        gotoAndPlay(frame);
      } else {
        gotoAndStop(frame);
      }
    }

    /**
     * Updates the current display of the rig.
     * This method is the heart of Garland. It will attempt to make a perfect
     * copy of the current state of the rig, but also layer the parts from all
     * the current items added. This will give the rig multiple layers of
     * graphics.
     * @dispatches Garland.END if the animation is showing its final frame.
     *                         this event can be used to show a new animation,
     *                         but it is suggested to use 'queue'.
     */
    internal function update():void {
      // Trigger a jump to the current frame, this will correctly add new
      // parts.
      if (playing) {
        gotoAndPlay(currentFrame);
      } else {
        gotoAndStop(currentFrame);
      }
      // If we've hit the end of this animation, let everyone know, and go to
      // the next if we have one queued.
      if (currentFrame == 1 && (looped || totalFrames == 1)) {
        // Start the next animation, or in the case of a loop, reget the current
        // rig, we must do this so that MovieClips that shouldn't exist in
        // the next frame are correctly removed.
        if (animationQueue.length) {
          animations = animationQueue;
        } else {
          animation = animation;
        }
        dispatchEvent(new Event(END));
        looped = false;
      } else if (currentFrame == totalFrames) {
        looped = true;
      }
      // For parts that were added last frame, we need to kickstart them into
      // frame 2, or else we get two frames at frame 1.
      if (addedLastFrame.length) {
        for each(var container:DisplayObjectContainer in addedLastFrame) {
          recursivelyGotoAndPlay(container, 2);
        }
        addedLastFrame = [];
      }
      // Recreate the rig MovieClip. We do this by stepping through each of
      // it's children, and creating a new part for each, then we position each
      // part by using it's transform and filter objects. This way we retain
      // position and any other transformations (color, alpha, filters).
      var currentParts:Object = {};
      for (var i:int = 0, l:int = rig.numChildren; i < l; i++) {
        var child:DisplayObject = rig.getChildAt(i);
        if (!child || child is Shape) {
          continue;
        }
        var name:String = Object(child).constructor.toString();
        name = name.substring(7, name.length - 1);
        var part:DisplayObject = parts[name];
        if (!part) {
          part = getPart(name);
          parts[name] = part;
        }
        part.transform = child.transform;
        // We can't wrap an IGarland in a Sprite like we do for the other parts,
        // because then we couldn't interact them through getChildByName(),
        // so we must manually concat any transforms each frame.
        if (part is IGarland && transforms[name]) {
          var transformMatrix:Matrix = transforms[name].clone();
          transformMatrix.concat(child.transform.matrix);
          part.transform.matrix = transformMatrix;
        }
        part.transform.matrix3D = null;
        part.filters = child.filters;
        currentParts[name] = part;
        addChild(part);
        if (activeParts[name]) {
          delete activeParts[name];
        } else {
          // Restart the display tree of the part to frame 1, this is
          // consistant with they way MovieClip works.
          recursivelyGotoAndPlay(DisplayObjectContainer(part), 1);
          if (!(part is Garland)) {
            addedLastFrame.push(part);
          }
        }
      }
      // Remove any unused parts from last frame.
      for each(var displayObject:DisplayObject in activeParts) {
        removeChild(displayObject);
      }
      activeParts = currentParts;
      // We need to kickstart our own rig, just like we do the parts.
      if (currentFrame == 1) {
        if (playing) {
          gotoAndPlay(2)
        }
      }
    }

    /**
     * Add an item at the highest layer.
     * @param item The item to add.
     */
    public function addItem(item:IGarland):void {
      addItemAt(item, items.length);
    }

    /**
     * Add an item at the required layer.
     * @param item  The item to add.
     * @param index The desired index for the item.
     */
    public function addItemAt(item:IGarland, index:int):void {
      index = Math.max(0, Math.min(items.length, index));
      items.splice(index, 0, item);
      if (!item.loaded) {
        item.addEventListener(COMPLETE, onComplete, false, 0, true);
        item.addEventListener(ERROR, onError, false, 0, true);
        // Get a null part, to start loading.
        item.getPart(null);
      } else if (loaded) {
        complete();
      }
    }

    /**
     * Add a transformation to a part.
     * @param part      The name of the part to transform
     * @param transform The transformation matrix to apply.
     */
    public function addTransform(part:String, transform:Matrix):void {
      transforms[part] = transform;
    }

    /**
     * Returns if an item has been added.
     * @param item The item.
     * @returns true if the item has been added
     */
    public function containsItem(item:IGarland):Boolean {
      return items.indexOf(item) != -1;
    }

    /**
     * Given a part name, generate a layered part.
     * If the required part is an animation, return a new Garland object which
     * shares this objects items and transforms.
     * @param name The name of the part to return.
     * @returns a layered DisplayObject.
     */
    public function getPart(name:String):DisplayObject {
      var part:Sprite
      if (isAnimation(name)) {
        // If a part is requested that is an animation, we return a new Garland
        // instance. This new instance should share our items so it will look
        // alike.
        var garland:Garland = new Garland();
        garland.items = items;
        garland.transforms = transforms;
        garland.cacheAsBitmap = cacheAsBitmap;
        garland.animation = name.substr(1);
        garland.name = garland.animation;
        garland.update();
        return garland;
      } else {
        // Create a part with the combined parts of all our items.
        part = new Sprite();
        for (var i:int = 0, l:int = items.length; i < l; i++) {
          var itemPart:Sprite = items[i].getPart(name);
          if (itemPart) {
            if (transforms[name]) {
              var transformMatrix:Matrix = transforms[name].clone();
              transformMatrix.concat(itemPart.transform.matrix);
              itemPart.transform.matrix = transformMatrix;
              itemPart.transform.matrix3D = null;
            }
            part.addChild(itemPart);
          }
        }
        // If we are rendering as a bitmap, we simply draw our combined parts
        // into a new bitmapData object and position it so it can be transformed
        // like the original. We make the bitmap 2 pixels wider on each side
        // to prevent strange edge artifacts when displayed on non integer
        // pixels. Sadly we lose animated parts, but do not lose nested
        // animations.
        if (cacheAsBitmapValue) {
          var bounds:Rectangle = part.getBounds(part);
          var bitmapData:BitmapData = new BitmapData(bounds.width + 4,
              bounds.height + 4, true, 0);
          var translateMatrix:Matrix = new Matrix();
          translateMatrix.translate(-bounds.x + 2, -bounds.y + 2);
          bitmapData.draw(part, translateMatrix, null, null, null, true);
          var bitmap:Bitmap = new Bitmap(bitmapData);
          bitmap.smoothing = true;
          bitmap.pixelSnapping = PixelSnapping.NEVER;
          bitmap.x = bounds.x - 2;
          bitmap.y = bounds.y - 2;
          part = new Sprite();
          part.addChild(bitmap);
        }
        part.name = name;
        return part;
      }
    }

    /**
     * Gets the transformation for the desired part name.
     * @param   part The name of the part.
     * @returns the matrix transformation for the part, or null if no
     *          transformation is applied to this part.
     */
    public function getTransform(part:String):Matrix {
      return transforms[part];
    }

    /**
     * Go to a specific frame of the current animation and continue playing.
     * @param frame The frame to change to.
     */
    public function gotoAndPlay(frame:int):void {
      rig.gotoAndPlay(frame);
      playing = true;
    }

    /**
     * Go to a specific frame of the current animation and stop playing.
     * @param frame The frame to change to.
     */
    public function gotoAndStop(frame:int):void {
      rig.gotoAndStop(frame);
      playing = false;
    }

    /**
     * Continue playback of the current animation.
     */
    public function play():void {
      rig.play();
      playing = true;
    }

    /**
     * Remove an item.
     * @param item The item to remove.
     */
    public function removeItem(item:IGarland):void {
      var index:int = items.indexOf(item);
      if (index != -1) {
        items.splice(index, 1);
        refresh();
      }
    }

    /**
     * Removes an item at a specific layer index.
     * @param index The index to remove.
     */
    public function removeItemAt(index:int):void {
      if (index >= 0 && index < items.length) {
        items.splice(index, 1);
        refresh();
      }
    }

    /**
     * Removes a transformation from a part.
     * @param part The name of the part to remove the transformation from.
     */
    public function removeTransform(part:String):void {
      delete transforms[part];
    }

    /**
     * Sets the layer index of an item.
     * @param item  The item to change index.
     * @param index The new index of the item.
     */
    public function setItemIndex(item:IGarland, index:int):void {
      removeItem(item);
      addItemAt(item, index);
    }

    /**
     * Stop playback of the current animation.
     */
    public function stop():void {
      rig.stop();
      playing = false;
    }

    /**
     * Swaps the layering of two items.
     * @param item1 The first item to swap.
     * @param item2 The second item to swap.
     */
    public function swapItems(item1:IGarland, item2:IGarland):void {
      swapItemsAt(items.indexOf(item1), items.indexOf(item2));
    }

    /**
     * Swaps the layering of two items based on their index.
     * @param item1 The first index to swap.
     * @param item2 The second index to swap.
     */
    public function swapItemsAt(index1:int, index2:int):void {
      if (index1 >= 0 && index1 < items.length &&
          index2 >= 0 && index2 < items.length) {
        var temp:IGarland = items[index1];
        items[index1] = items[index2];
        items[index2] = temp;
      }
    }

    /**
     * Get the name of the current animation.
     */
    public function get animation():String {
      return rig.name;
    }

    /**
     * Set and play a looping animation.
     * @param value The name of the current animation, without the _ used when
     *              exported.
     * @dispatches Garland.START.
     */
    public function set animation(value:String):void {
      animationQueue = [];
      rig = null;
      for (var i:int = items.length - 1; i >= 0; i--) {
        rig = items[i].getPart(GARLAND + value) as MovieClip;
        // We only care about rigs with children, this is so that items may
        // contain animations for complete rigs, without needing to
        // contain the animations for subrigs.
        if (rig && rig.numChildren) {
          break;
        }
      }
      rig ||= new MovieClip();
      // Set the name even if we're using a blank movieclip, so we can support
      // refreshing the animation before rigs have loaded.
      rig.name = value;
      looped = false;
      dispatchEvent(new Event(START));
    }

    /**
     * Sets and plays an animation and queue in a single operation.
     * @param value A list of animations to play. The final animation will loop.
     */
    public function set animations(value:Array):void {
      if (value.length) {
        animation = value.shift();
        animationQueue = value;
      }
    }

    /**
     * Gets the current cacheAsBitmap value.
     * @returns true if we are currently rendering as a Bitmap.
     */
    public override function get cacheAsBitmap():Boolean {
      return cacheAsBitmapValue;
    }

    /**
     * Set if we should render as a Bitmap.
     * @param value A boolean specifying if we should render as a Bitmap.
     */
    public override function set cacheAsBitmap(value:Boolean):void {
      if (value != cacheAsBitmapValue) {
        cacheAsBitmapValue = value;
        clear();
        refresh();
        update();
      }
    }


    /**
     * Have we loaded all our assets.
     * @returns true if all of the items added have completed loading.
     */
    public function get loaded():Boolean {
      for (var i:int = 0, l:int = items.length; i < l; i++) {
        if (!items[i].loaded) {
          return false;
        }
      }
      return true;
    }

    /**
     * Gets the currently displayed frame in the animation.
     * @returns the current frame.
     */
    public function get currentFrame():int {
      // Empty movieclips will return 0 as the currentFrame, even though they
      // return 1 as totalFrames, clamp the value so we can make the correct
      // comparison.
      return Math.max(1, rig.currentFrame);
    }

    /**
     * Gets the current animation queue.
     * @returns an array of animation names.
     */
    public function get queue():Array {
      return animationQueue;
    }

    /**
     * Sets the animation cue. The first animation will play when the current
     * animation finishes.
     * @param value A list of animation names.
     */
    public function set queue(value:Array):void {
      animationQueue = value;
    }

    /**
     * Get the total number of frames in the current animation.
     * @returns the total frames.
     */
    public function get totalFrames():int {
      return rig.totalFrames;
    }
  }
}
