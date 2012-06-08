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

var types = {};

function setGuides(hide, timeline, index) {
  for (var l = 0; l < timeline.layers.length; l++) {
    var layer = timeline.layers[l];
    if (hide) {
      types[i + "_" + l] = layer.layerType;
      layer.layerType = "guide";
    } else {
      layer.layerType = types[i + "_" + l];
    }
  }
}

var doc = fl.getDocumentDOM();
var library = doc.library;
var i;
var item;
for (i = 0; i < library.items.length; i++) {
  item = library.items[i];
  // Make sure the item isn't an animation.
  if (item.name.indexOf("_") != 0 && item.name.indexOf("/_") == -1 &&
      item.itemType == "movie clip") {
    setGuides(true, item.timeline, i);
  }
}

doc.publish();

for (i = 0; i < library.items.length; i++) {
  item = library.items[i];
  // Make sure the item isn't an animation.
  if (item.name.indexOf("_") != 0 && item.name.indexOf("/_") == -1 &&
      item.itemType == "movie clip") {
    setGuides(false, item.timeline, i);
    // Animations will play up if we don't go into the items once we've reset
    // their layer types.
    library.editItem(item.name);
  }
}

doc.exitEditMode();