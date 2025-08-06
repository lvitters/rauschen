# DEV DIARY (top secret and private - do not read)

## 2411

### Initial spark

I went to a university counselor today. For over a year I had been struggling to find a topic for my thesis. Or rather, I had tons of stuff on my mind, many stupid installations broadly touching on whatever subject I had a passing interest in. For some reason, I thought I needed to say something with my work. When I applied for my Master's, one of the professors asked me what I want to say with my work. I remember answering that I wanted to say nothing, that I just wanted to make stuff that looks nice. And then I got accepted, so for a while it seemed that was a good answer. <br> 
During my time there I noticed everyone else always had something to say with their work. They mostly even seemed to have something to say first and then create something about that. Or at least they made it seem that way.
I forced myself to read some stuff, "do some theory", even took a class or two about some theory texts. The discussions there sparked my interest a bit, but none of the ideas that came from that were interesting enough. Every excitement passed after a short time. <br>
For some reason I also thought I had to build something physical. Everyone else seemed to do that. I was sitting in a room with tons of electronic waste, cables, remnants of old installations and people building new ones for years now. And while I had experience coding something for a physical installation, and had built some smaller stuff here and there as well, I just felt like I needed to do a *proper* one myself. I'm not sure if it was me or someone else telling me this, but it seemed like nothing that I came up with was good enough. <br>
My thesis, because it was the last chance to make something before being thrown into the real world and with the resources of my school available, had to encompass all of that. <br>
Right there is when I was stopped while telling this story to the university's counselor. Of course it does not have to do that, or else I would never start. As obvious as that should be, sometimes you just cannot see the forest for the trees.
The counselor asked me, if no one was looking, if nobody cared, what *I* want to do. *For myself!* <br>

## Inspiration

If there is one common thread in my works over the years it is randomness. I started out doing visuals with Processing at the beginning because I loved that I could use *Perlin Noise* and random() to create something variable instead of deciding anything then and there. Creating *possibilty spaces*. Looking back, that is pretty much what I did over the time, maybe in some other languages, programs or mediums, but it was always that. I called it *generative choreographies* because it always uses many of the same entities doing something together. *Emergence* is a big word for me. So maybe the theory that I so desire to have behind my thesis can be that? <br>

How does something emerge from randomness? What is randomness even? How do we produce it? Where do we encounter it in the world?

### Library of Babel

One of the most interesting works to me over the years was the *Library of Babel*, a short story about a universe in the form of a vast library containing all possible four hundred and ten pages long books of a certain format and character set. Someone had created a website emulating the idea, which generates a unique address for any three thousand and two hundred character long text you give it, excluding digits and some special characters, and can give you back the corresponding three thousand and two hundred character long text for an address. So effectively, it gives you a key value pair for every three thousand and two hundred character long text that can be written, [including the paragraph you are reading right now](https://libraryofbabel.info/bookmark.cgi?yi_hxkkof50).

### Infinite Monkey Theorem

Anyone knows the *Infinite Monkey Theorem*. I am sure as hell not the first one to have the idea that an image on a computer of, let's say 1000x1000 pixels, is also a finite possibility space. If I generate randomly colored pixels it will just look like noise. Theoretically, after an infinite amount of time, there will be every possible picture. Maybe there is a way to use this noise as a basis and then create some interesting or *nice* looking stuff that *emerges* from that? I can call it *RAUSCHEN*, because it sounds way more mysterious in German.

### Ganzfeld

Two years go I went to *Copenhagen Contemporary*. It had one of *James Turrell*'s works. There was a tiny elevated hole in the wall. We had to step through it (without shoes) and went into a what I can only describe as a huge, white rectangle with rounded edges. At some point the museum's worker shouted "STOP" so we wouldn't walk too far into it. You couldn't actually make out where the back wall was, only that it was lit up with a huge colored gradient. We stood there for a couple of minutes staring into the light. It started flickering, warping and some patterns emerged in my view. I think all of that was in my head, because I couldn't see a projector anywhere. *Turrell* calls that a *Ganzfeld*.

### Unsupervised

Last year I went to *MoMa*. In the entry hall, there was a huge screen with some generative visuals. *Unsupervised* supposedly made these visuals from the archive of all of the museum's works. There was a small screen, inconspicuously hidden in a corner, that was displaying some of the stats and numbers that this process was using in the background. Might be an idea for my projection as well.


## 241121

Today I officially did the initial commit for *RAUSCHEN*. I started with a 800x800 canvas in *p5.js*. I want *RAUSCHEN* to be an installation first, something people would be in front of like a *Ganzfeld*, but I also want it running live on my website, so *p5.js* it is.
I want to use a bunch of *Perlin Noise* instances, so I created a first draft of a Noise object. I can just call as many instances of that as I need for all of the parameters that affect the pixel canvas. For now the canvas' pixels are just determined by random RGB values.

Also added a variable gridLines, determining and applying a step with which to iterate over the pixel array, so only every X or Y line or column would be affected be the random color changes. Looks interesting.

Expanded the Noise class to return a mapped range instead of a 0 to 1 value directly, so that gridLines can be controlled by Perlin Noise as well.

## 241122

Added a function to the Noise class that returns a Boolean corresponding to its internal noise value, so that I could toggle using the gridLines according to Noise as well.

Also added a function to cut off the Noise value, so that it is still computed internally as such, but will never return something above or below a certain value. Might be useful.

Changing individual pixel colors with the Noise class is definitely way too resource intensive, it only works if the gridLines is very high. Need to rethink that.

## 241125

Added timedEvents, counting frames until a random or set number of frames has been reached. Not everything needs to constantly change, for example the gridLines or overall canvas resolution should only change after X amount of frames.

## 241126

The increment with which the Noise objects "move through the Noise field" can now be changed by calling a function on it after initialization.

## 241127

Added functionality to send all the Noise object's values to another *p5.js* application over *OSC* so they can be displayed as graphs in a second projection, recording the values like a seismograph.

## 2412

*records partially lost*

Better to do this sooner than later: Moving to *Processing* will make things a lot easier. Better performance of *Java* vs *JavaScript*, easier to optimize performance, no browser in the middle. Fully embracing the installation aspect of this feels right. Having it run directly on my website might take away from it anyways.

## 250109

Moved everything to one repository. Will continue with the *Processing* version.

gridLines should really be working differently. Instead of affecting only every X and Y line of pixels, it should create rectangular / square cells, effectively changing the resolution of the pixel grid. Can't get this to work properly, for now it only works if X and Y are the same.

## 250117

Finally have it working with individual steps, now called xStep and yStep!

## 250122

Similar to the way it was already working in the *p5.js* version, there is now a second window of the application that displays a graph for a set amount of historical values per Noise object.

## 250123

Noise objects are now added to a global ArrayList for easier display in the graphs window.

The function to change the grid of cells now works with an offset. Previously, because of the way a nested loop will iterate over the cells, if canvas' width and height weren't divisible by the xStep and yStep values, only cells on the right and bottom edge would be cutoff. This is now even on all sides.

Added a new Noise object changing if cells should always be square or can be rectangular.

## 250127

Experimented with biases. When getting a range or variable range from a Noise object, I might want to have the output biased into a certain direction. Like have numbers closer to the max value occur more often. Math is difficult though. I am not sure if this is working properly or just multiplying every result?

## 250128

Maybe bias on top of bias is the solution to really "weight" the number into one direction? Maybe the bias strength should be determined by Noise to make every outcome still possible?

## 2502

*Having other responsibiliies.*

## 250304

Started experimenting with some oscilattors for creating some sound. Can't just be silent, right?

## 250305

Determining the cells color's completely with Noise is still very slow even in *Processing*. Professor gave me an example sketch using multi threading. Not sure how it could work for me, since I can not really divide my canvas into independent sectors. But worth looking into.

## 250310

Maybe using a shader for computing per pixel / per cell Noise is the right idea? No idea what shaders are or how they work, but I've definitely heard they are fast. Tested a simple noise shader.

If the shader gets an input texture and returns an output texture, I could just switch to a shader whenever something becomes to resource intensive.

### *Maybe I can even switch between a bunch of different shaders?*

## 250311

The intRandom() method from the multi threading example is way faster than *Processing*'s own! Same goes for floatRandom(). At least that helps.

## 250312

Can now switch between using a shader and not using a shader on the fly. Unfortunately, because using a shader means I must use *OpenGL* mode, the second window showing the graphs broke. But I will figure that out.

## 250313

Can now pass the canvas (buffer) to the shader as an input texture! Now it will actually look like it is doing something to the pixel grid.

## 250314

Implementing bias seems to skew all results towards the corresponding side. I can't seem to make it have certain results more often, it always just sort of multiplies all results, so that the ones on the other side never occur. I am not even sure anymore I understand the words bias and skew, or what the difference between them is, or if there is one.

I had the bias included in the call to get the Noise object's value range. Maybe it should just be a function in the global scope? Or should I just go back the min and max of a range being a Noise object itself again? Or maybe both?

Added a fps toggle.

## 250317

Maybe instead of individual Noise objects for every pixel, which wasn't working at all, and the reason why I've implemented a Noise shader, I can have just three Noise objects for one color that "leads", and then each cell's color is just a further call to those three Noise objects? Might look interesting and different to the Noise shader. Could switch between that and the shader depending on the current grid resolution?

## 250318

Added a debug key to toggle between printing or not printing all these debug messages. Otherwise all this printing will make the programm crawl to a halt. Also toggle a little debug area in the sketch window with some info like fps or when the next event will fire.

Brought my old *MIDI* keyboard. It has some knobs and buttons. Will be useful for testing instead of always having to wait for whatever I am testing to happen randomly.

Implemented some manual controls for controlling how fast the events will fire with its knob.

## 250319

### *note: everything up until this part has been reconstructed from commit messages*

Professor said to look at what a frame buffer object is. Sounds similar to what I am already using to pass the current grid to the shader?

We came up with the idea of creating a developer diary documenting my process of creating this. Sounds like a good idea, because I am really just making it up as I go. Would be nice to have some record of that.

Decided the graphs window really should be in a separate application anyways, so that I could choose to not run it, and save some resources in that case. That way the second window does not have to run in *OpenGL* mode as well.

Maybe for the sound I could use the oscillators to play a corresponding sound for each cell's color value change?