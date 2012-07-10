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

var touched = {};

function link(item) {
  var names = item.name.toString().split("/");
  var name = names[names.length - 1];
  if (!touched[name]) {
    touched[name] = true;
    item.linkageExportForAS = true;
    item.linkageExportInFirstFrame = true;
    item.linkageIdentifier = name;
  }
}

function setLinkageNames(timeline) {
  for (var l = 0; l < timeline.layers.length; l++) {
    var layer = timeline.layers[l];
    for (var f = 0; f < layer.frames.length; f++) {
      var frame = layer.frames[f];
      for (var e = 0; e < frame.elements.length; e++) {
        var element = frame.elements[e];
        if (element.libraryItem) {
          link(element.libraryItem);
        }
      }
    }
  }
}

var doc = fl.getDocumentDOM();
var library = doc.library;
for (var i = 0; i < library.items.length; i++) {
  var item = library.items[i];
  // Make sure the item is an animation.
  if ((item.name.indexOf("_") == 0 || item.name.indexOf("/_") != -1) &&
      item.itemType == "movie clip") {
    link(item);
    setLinkageNames(item.timeline);
  }
}