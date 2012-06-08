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
  import flash.display.Loader;
  import flash.events.ErrorEvent;
  import flash.events.Event;
  import flash.events.EventDispatcher;
  import flash.events.IOErrorEvent;
  import flash.geom.Matrix;
  import flash.net.URLRequest;
  import flash.system.ApplicationDomain;

  /**
   * Loads and returns parts for a Garland object.
   * Multiple GarlandItems can be used together to layer graphics on a rig.
   */
  public class GarlandItem extends EventDispatcher implements IGarland{
    private var loader:Loader;
    private var domain:ApplicationDomain;
    private var url:String;

    /**
     * Constructs a new GarlandItem.
     * @param url The URL to fetch graphic resources from, this should point
     *            to a swf file containing exported symbols for each part name
     *            that the item wants to display.
     */
    public function GarlandItem(url:String) {
      this.url = url;
    }

    /**
     * Begin loading the resources for the item.
     * This will be a noop if the item is already loaded, or currently loading.
     */
    public function load():void {
      if (loader) {
        return;
      }
      loader = new Loader();
      loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
      loader.contentLoaderInfo.addEventListener(ErrorEvent.ERROR, onError);
      loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onError);
      loader.load(new URLRequest(url));
    }

    /**
     * Fired on completion of loading.
     * @dispatches Event.COMPLETE.
     */
    private function onComplete(event:Event):void {
      domain = event.target.applicationDomain;
      dispatchEvent(new Event(Event.COMPLETE));
    }

    /**
     * Fired when loading fails in any way.
     * @dispatches Event.CANCEL.
     */
    private function onError(event:Event):void {
      dispatchEvent(new Event(Event.CANCEL));
    }

    /**
     * Returns a DisplayObject for the specified part name.
     * @returns a DisplayObject or null if this item does not have graphics for
     *          the specified part.
     */
    public function getPart(name:String):DisplayObject {
      load();
      if (domain && domain.hasDefinition(name)) {
        var classReference:Class = domain.getDefinition(name) as Class;
        if (classReference) {
          return new classReference();
        }
      }
      return null;
    }

    /**
     * Has this item loaded its assets.
     * @returns true if the item has finished loading.
     */
    public function get loaded():Boolean {
      return Boolean(domain);
    }
  }
}
