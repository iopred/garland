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
  import flash.display.DisplayObject;
  import flash.display.DisplayObjectContainer;
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.EventDispatcher;
  import flash.events.IEventDispatcher;
  import flash.geom.ColorTransform;
  import flash.geom.Matrix;

  /**
   * Wraps a GarlandItem to provide additional functionality.
   * Allows colorisation of the parts and transformations of parts.
   * Supports global transforms, or on a per part basis.
   */
  public class GarlandLayer implements IGarland {
    protected var item:IGarland;
    protected var colors:Array;
    protected var transform:Matrix;
    protected var transforms:Object = {};

    /**
     * Constructs a new GarlandLayer.
     * @param item      The GarlandItem to wrap.
     * @param colors    An array of colors to use when colorising parts. The
     *                  index of each color will be used to locate a child of
     *                  each part by the name "color<n>" where n is the index.
     * @param transform A global transformation to apply to each part.
     */
    public function GarlandLayer(item:IGarland,
                                 colors:Array = null, transform:Matrix = null) {
      this.item = item;
      this.colors = colors;
      this.transform = transform;
    }

    /**
     * Colorises a part by colorTransforming children with the name "color<n>"
     * where n is the index in the colors array.
     * @param part The display object to colorise.
     * @returns the same part as passed, after it has been colorised.
     */
    protected function colorPart(part:DisplayObject):DisplayObject {
      var container:DisplayObjectContainer = part as DisplayObjectContainer;
      if (container && colors) {
        for (var i:int = 0, l:int = colors.length; i < l; i++) {
          var child:DisplayObject = container.getChildByName("color" + i);
          if (child) {
            var color:uint = colors[i];
            child.transform.colorTransform = new ColorTransform(0, 0, 0, 1,
                (color & 0xFF0000) >> 16, (color & 0xFF00) >> 8, color & 0xFF);
          }
        }
      }
      return part;
    }

    /**
     * Applies a transformation to a part.
     * @param part The display object to transform
     * @param name The name of the part.
     * @returns the same part as passed, after it has been transformed.
     */
    protected function transformPart(part:DisplayObject,
                                     name:String):DisplayObject {
      if (!part || Garland.isAnimation(name) ||
          (!transform && !transforms[name])) {
        return part;
      }
      var transformMatrix:Matrix = new Matrix();
      if (transform) {
        transformMatrix.concat(transform);
      }
      if (transforms[name]) {
        transformMatrix.concat(transforms[name]);
      }
      part.transform.matrix = transformMatrix;
      return part;
    }

    public function addEventListener(type:String, listener:Function,
                                     useCapture:Boolean=false, priority:int=0,
                                     useWeakReference:Boolean=false):void {
      item.addEventListener(type, listener, useCapture,
          priority, useWeakReference);
    }

    /**
     * Add a transformation to a part.
     * @param part      The name of the part to transform
     * @param transform The transformation matrix to apply.
     */
    public function addTransform(part:String, transform:Matrix):void {
      transforms[part] = transform;
    }

    public function dispatchEvent(event:Event):Boolean {
      return item.dispatchEvent(event);
    }

    /**
     * Returns a DisplayObject for the specified part name, this part is
     * colorised and transformed if this layer contains transformation or color
     * information.
     * @returns a DisplayObject or null if this item does not have graphics for
     *          the specified part.
     */
    public function getPart(name:String):DisplayObject {
      return transformPart(colorPart(item.getPart(name)), name);
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

    public function hasEventListener(type:String):Boolean {
      return item.hasEventListener(type);
    }

    public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void {
      item.removeEventListener(type, listener, useCapture);
    }

    /**
     * Removes a transformation from a part.
     * @param part The name of the part to remove the transformation from.
     */
    public function removeTransform(part:String):void {
      delete transforms[part];
    }

    public function willTrigger(type:String):Boolean {
      return item.willTrigger(type);
    }

    public function get loaded():Boolean {
      return item.loaded;
    }
  }
}
