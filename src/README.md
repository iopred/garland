Getting Started
---------------

It is extremely easy to load a SWF and play an animation..

```
var garland:Garland = new Garland();
garland.addItem(new GarlandItem("character.swf");
garland.animation = "Idle";
```

The loaded SWF file should contain an exported MovieClip named `_Idle`. Inside this MovieClip should be an animation similar to any other MovieClip created in Flash, it can (and should) contain Tweens but also supports color transforms and filters.
The defining characteristic of an animation is that all MovieClips inside the animation that should be exported for runtime so they can be layered by Garland.
Any MovieClips that are not exported for runtime will not be visible.

Let's assume that the `_Idle` animation in the previous SWF contained an exported MovieClip name `Head`.
If you were now to create a new SWF containing only an exported MovieClip named `Head`, you could layer this on top of your character animation simply by adding:

```
garland.addItem(new GarlandItem("armor.swf"));
```

Now, if you were to create a new SWF file with an exported animation `_Attack`, you could load that animation on to your Garland like any other item. This new animation could contain a new exported MovieClips for new effects (sword swoosh, dust clouds or shadows etc.).
Now you would be able to play this animation with all the layered parts previously added.

```
garland.addItem(new GarlandItem("sword.swf"));
garland.animation = "Attack";
```

Garland supports a host of additional features.

- Animation queues.
  Play an animation and automatically change to another when it finishes.
  The last animation in the queue will loop indefinately.

  ```
  garland.animations = ["Walk", "Idle"];
  ```

  or

  ```
  garland.animation = "Walk";
  garland.queue = ["Idle"];
  ```

- Per part transformations.
  Support big head mode with a few simple lines of code:

  ```
  var matrix:Matrix = new Matrix();
  matrix.scale(2, 2);
  garland.addTransform("Head", matrix);
  ```

- Colorised items with GarlandLayer.
  Export any number of part MovieClips with children named `color<n>`.
  You can then colorise these children with a GarlandLayer.

  ```
  garland.addItem(new GarlandLayer("armor.swf", [0xCC0000]));
  ```

- Per item transformations.
  Apply a global transformation on each part of a item:

  ```
  var matrix:Matrix = new Matrix();
  matrix.scale(2, 2);
  garland.addItem(new GarlandLayer("character.swf", null, matrix);
  ```

  Apply transformations to a specific part inside a specific item:

  ```
  var matrix:Matrix = new Matrix();
  matrix.scale(2, 2);
  var layer:GarlandLayer new GarlandLayer("armor.swf", null, matrix);
  layer.addTransform("Head", matrix)
  garland.addItem(layer);
  ```

- Nested Garlands
  Create your animations with other `_MovieClips` and Garland will automatically nest Garlands. This allows you to make simple character animations, but customise facial features or even trigger custom animations while another is playing!

  ```
  garland.animation = "Jump";
  var head:Garland = garland.getChildByName("Head") as Garland;
  if (head) {
      head.animations = ["HeadWink", "Head"];
  }
  ```

- Bitmap Caching
  Set cacheAsBitmap like any other DisplayObject and Garland will cache the individual parts instead of the entire DisplayObject.
  This is generally faster to render, however mouse click accuracy is lost.

- Garland supports most of the MovieClip API.

  - play
  - pause
  - gotoAndPlay
  - gotoAndStop
  - currentFrame
  - totalFrames
