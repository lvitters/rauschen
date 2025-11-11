<!--
<style>
	/* styling for PDF generation */
	@import url('https://fonts.googleapis.com/css2?family=Commit+Mono:wght@400;700&display=swap');

	* {
		font-family: 'Commit Mono', monospace !important;
	}

	h1, h2, h3, h4, h5, h6 {
		page-break-after: avoid !important;
		break-after: avoid !important;
		page-break-inside: avoid !important;
		break-inside: avoid !important;
	}
</style>
-->

# DEV DIARY (top secret - do not read)

## 2411

### Initial spark

I went to a university counselor today. For over a year I had been struggling to find a topic for my thesis. Or rather, I had tons of stuff on my mind, many stupid installations broadly touching on whatever subject I had a passing interest in. For some reason, I thought I needed to say something with my work. When I applied for my Master's, one of the professors asked me what I wanted to say with my it. I remember answering that I wanted to say nothing, that I just wanted to make stuff that looks nice. And then I got accepted, so for a while it seemed that was a good answer. <br> 
During my time there I noticed everyone else *always* had something to say with their work. They mostly even seemed to have something to say *first* and *then* create something about that. Or at least they made it seem that way.
I forced myself to read some stuff, "do some theory", even took a class or two about some theory texts. The discussions there sparked my interest a bit, but none of the ideas that came from that were interesting enough. Every excitement passed after a short time. <br>
For some reason I thought I also had to build something physical. Everyone else seemed to do it. I was sitting in a studio with tons of electronic waste, cables, remnants of old installations and people building new ones for years now. And while I had experience coding something for a "physical" installation, and had built some smaller stuff here and there as well, I just felt like I needed to do a *proper* one myself. I'm not sure if it was me or someone else telling me this, but it seemed like nothing that I came up with was good enough. <br>
My thesis, because it was the last chance to make something like that before being thrown into the real world and with the resources of my school still available to me, had to encompass all of that. <br>
Right there is when I was stopped while telling this story to the university's counselor. Of course it does not have to do that, or else I would never start. As obvious as that should be, sometimes you just cannot see the forest for the trees.
The counselor asked me, if no one was looking, if nobody cared, what *I* really want to do. *For myself!* <br>

## Inspiration

If there is one common thread in my works over the years it is randomness. I started out doing visuals with Processing at the very beginning because I loved that I could use Perlin Noise and random() to create something variable instead of deciding anything then and there. Creating *possibilty spaces*. Looking back, that is pretty much what I did all this time, maybe in some other languages, programs or mediums, but it was always that. I called it *generative choreographies* because it always uses many of the same entities doing something together. *Emergence* is a big word for me. So maybe the theory that I so desire to have behind my thesis can be about that? <br>

How does something emerge from randomness? What is randomness even? How do we produce it? Where do we encounter it in the world?

### Library of Babel

One of the most interesting works to me over the years was the Library of Babel, a short story about a universe in the form of a vast library containing all possible four hundred and ten pages long books of a certain format and character set. Someone had created a website emulating the idea, which generates a unique address for any three thousand and two hundred character long text you give it, excluding digits and some special characters, and can give you back the corresponding three thousand and two hundred character long text for any such address. So effectively, it gives you a key value pair for every three thousand and two hundred character long text that can be written, [including the paragraph you are reading right now](https://libraryofbabel.info/bookmark.cgi?ftmdz,111).

### Infinite Monkey Theorem

Everyone knows the Infinite Monkey Theorem. I am sure as hell not the first one to have the idea that an image on a computer of, let's say 1000x1000 pixels, is also a finite possibility space. If I generate randomly colored pixels it will just look like noise. Theoretically, after an infinite amount of time, the outcome will include every possible image. Maybe there is a way to use this noise as a basis and then create some interesting or *nice* looking stuff that *emerges* from that? I can call it **RAUSCHEN**, because it sounds way more mysterious in German.

### Ganzfeld

Two years go I went to Copenhagen Contemporary. It had one of James Turrell's works. There was a tiny elevated hole in the wall. We had to step through it (without shoes) and went into a what I can only describe as a huge, white rectangle with rounded edges. At some point the museum's worker shouted "STOP" so we wouldn't walk too far into it. You couldn't actually make out where the back wall was, only that it was lit up with a huge colored gradient. We stood there for a couple of minutes staring into the light. It started flickering, warping and patterns emerged in my view. I think it must have been in my head, because I couldn't see a projector anywhere. Turrell calls that a "Ganzfeld".

### Unsupervised

Last year I went to MoMa. In the entry hall, there was a huge screen with some generative visuals. "Unsupervised" supposedly made these visuals from the archive of all of the museum's works. Of course there was mention of "an AI dreaming it up". There also was a small screen, inconspicuously hidden in a corner, that was displaying some of the stats and numbers that this process was using in the background. Might be an idea for my projection as well.


## 241121

Today I officially did the initial commit for **RAUSCHEN**. I started with a 800x800 canvas in p5.js. I want **RAUSCHEN** to be an installation first, something people would be in front of like a Ganzfeld, but I also want it running live on my website, so p5.js it is.
I want to use a bunch of Perlin Noise instances, so I created a first draft of a Noise object. I can just call as many instances of that as I need for all of the parameters that affect the pixel canvas. For now the canvas' pixels are just determined by random RGB values.

Also added a variable called gridLines, determining and applying a step with which to iterate over the pixel array, so only every X or Y line or column would be affected be the random color changes. Looks interesting.

Expanded the Noise class to return a mapped range instead of a 0 to 1 value directly, so that gridLines can be controlled by Perlin Noise as well.

## 241122

Added a function to the Noise class that returns a Boolean corresponding to its internal noise value, so that I could toggle using gridLines according to Noise as well.

Also added a function to cut off the Noise value, so that it is still computed internally as such, but will never return something above or below a certain value. Might be useful.

Changing individual pixel colors with the Noise class is definitely way too resource intensive, it only works if gridLines is high, so not many pixels are actually affected. Need to rethink that.

## 241125

Added timedEvents, counting frames until a random or set number of frames has been reached. Not everything needs to constantly change, for example gridLines or overall canvas resolution should only change after X amount of frames.

## 241126

The increment with which the Noise objects "move through the Noise field" can now be changed by calling a function on it after initialization.

## 241127

Added functionality to send all the Noise object's values to another p5.js application over OSC so they can be displayed as graphs in a second projection, recording the values like a seismograph.

## 2412

*records partially lost*

Better to do this sooner than later: Moving to Processing will make things a lot easier. Better performance of Java vs JavaScript, easier to optimize performance, no browser in the middle. How do I know all this? I don't really. The more you learn the less you know. 

But fully embracing the installation aspect of this feels right. Having it run directly on my website might take away from it anyways.

## 250109

Moved everything to one repository. Will continue with the Processing version.

gridLines should really be working differently. Instead of affecting only every X and Y line of pixels, it should create rectangular / square cells, effectively changing the resolution of the pixel grid. Can't get this to work properly, for now it only works if X and Y are the same.

## 250117

Finally have it working with individual steps, now called xStep and yStep!

## 250122

Similar to the way it was already working in the p5.js version, the application now creates a second window that displays a graph for a set amount of historical values per noise object.

## 250123

Noise objects are now added to a global ArrayList for easier display in the graphs window.

The function to change the grid of cells now works with an offset. Previously, because of the way a nested loop will iterate over the cells, if the canvas' width and height weren't divisible by the xStep and yStep values, only cells on the right and bottom edge would be cut off. This is now even on all sides.

Added a new noise object determining if cells should always be square or can also be rectangular.

## 250127

Experimented with biases. When getting a range or variable range from a noise object, I might want to have the output biased into a certain direction. For example have those numbers that are closer to the max value occur more often. Math is difficult though. I am not sure if this is working properly or if it just multiplying every result?

## 250128

Maybe bias on top of bias is the solution to really "weight" the number into one direction? Maybe the bias strength should be determined by noise to make every outcome still possible to occur?

## 2502

*Having other responsibiliies.*

## 250304

Started experimenting with some oscillators for creating some sound. Can't just be silent, right?

## 250305

Determining the cells' color's completely with noise is still very slow even in Processing. Professor gave me an example sketch using multi threading. Not sure how it could work for me, since I can not really divide my canvas into independent sectors. But worth looking into.

## 250310

Maybe using a shader for computing per pixel / per cell noise is the right idea? No idea what shaders are or how they work, but I've definitely heard they are fast. Tested a simple noise shader.

If the shader gets an input texture and returns an output texture, I could just switch to a shader whenever something becomes too resource intensive.

### *Maybe I can even switch between a bunch of different shaders?*

## 250311

The intRandom() method from the multi threading example is way faster than Processing's own! Same goes for floatRandom(). At least that helps.

## 250312

Can now switch between using a shader and not using a shader on the fly. Unfortunately, because using a shader means I must use OpenGL mode, the second window showing the graphs broke. But I will figure that out.

## 250313

Can now pass the canvas (buffer) to the shader as an input texture! Now it will actually look like it is doing something to the pixel grid.

## 250314

Implementing bias seems to skew all results towards the corresponding side. I can't seem to make it have certain results more often, it always just sort of multiplies all results, so that the ones on the other side never occur. I am not even sure anymore that I understand the words bias and skew, or what the difference between them is, or if there is one.

I had the bias included in the call to get the noise object's value range. Maybe it should just be a function in the global scope? Or should I just go back to the min and max of a range being a noise object itself again? Or maybe both?

Added a fps toggle.

## 250317

Maybe instead of individual noise objects for every pixel, which wasn't really working anyways, and was also the reason why I've implemented a noise shader, I can have just three Noise objects for one color that "leads", and then each cell's color is just a further call to those three noise objects? Might look interesting and different to the noise shader. Could switch between that and the shader depending on the current grid resolution?

## 250318

Added a debug key to toggle between printing or not printing all these debug messages. Otherwise all this printing will make the programm crawl to a halt. Also toggle a little debug area in the sketch window with some info like fps or when the next event will fire.

Brought my old MIDI keyboard. It has some knobs and buttons. Will be useful for testing instead of always having to wait for whatever I am testing to happen randomly.

Implemented some manual controls for controlling how fast the events will fire with its knobs. There is a minSwitchTime and maxSwitchTime, so for the next event a random time can be chosen from between the two.

## 250319

### *note: everything up until this part has been reconstructed from commit messages*

Professor said to look at what a frame buffer object is. Sounds similar to what I am already using to pass the current grid to the shader? We weren't sure if I am actually passing the buffer correctly as the input texture.

We came up with the idea of creating a developer diary documenting my process of creating this program. Sounds like a good idea, because I am really just making it up as I go. Would be nice to have some record of that, even if it won't include everything or make sense to anyone but me.

Talked about that the graphs window really should be in a separate application anyways, so that I could choose to not run it, and save some resources in that case. That way the second window does not even have to run in OpenGL mode.

Maybe for the sound I could use the oscillators to play a corresponding sound for each cell's color value change? Professor recommended me his sound library called "Wellen".

## 250320

Wellen has something called "digital signal processing" that works by playing X samples per second. I could feed that by using X number of pixels per second for the samples.

Apparently, the buffer's pixel array is empty after every call to the shader, so it never receives its past output back as an input.

## 250321

The digital signal processing can now be paused and restarted.

Tried again with the two windows, but can't really get the second window to work without using the P2D renderer. Maybe a workaround could be to have the control stuff be in the main window and put the visuals in the second window? Switch it around? Seems messy though.

Decided I will actually just have two separate applications that communicate everything between each other. "Full duplex" is a buzzword I have heard about this once. One with the visuals, and one with the controls and graphs.

## 250325

Starting to understand some of this shader stuff. I think writing a bunch of them myself is not feasible, so I vibe coded a new one that is supposed to look like Conway's Game of Life with the rules adapted to work with my input textures.

Added it to an ArrayList of shaders to (randomly) choose from. Right now a new random shader is determined each frame, however I think that choice should "stick" for a couple of frames sometimes. Another thing to be determined by noise! I could add a ton of (vibe coded?) shaders this way.

## 250326

Should I have a second projection or a screen somewhere that shows some screenshots from the application?

I should only map the midi controller's values after being sent to the main sketch, because some of them might be affected by the buffer resolution, like xStep and yStep. The control sketch should really just send over raw values.

I can now control xStep and yStep via the midi controller. Which often crashed the sketch. Need to figure out why exactly. Changing them manually looks pretty cool. Sometimes this gradual change should happen automatically. Use lerp()?

It also looks like the cells are overlapping and moving outside of their grid when changing the steps gradually. Screenshots don't show this. Is it just a persistence of vision effect? Also, it looks like they are moving in and out of the top left corner, which makes sense, but I don't know how to mitigate this yet.

## 250327

I noticed that the sound is affected way more by horizontal changes to the grid than vertical ones. It makes sense because the samples are taken from a horizontal line. I could switch this up once in a while.

Using two knobs for manually changing each step dimension. One is granular control, one is a multiplier.

Don't really need minSwitchTime, it can just always be between 0 and maxSwitchTime.

## 250328

Instead of a horizontal line for the audio samples I tried out a square in the center of the buffer. Sounds horrible. Maybe it should be a diagonal line?

Took me way too long to realize this: Contrary to how it works in simple geometry and right angled triangles' sides, a diagonal line between opposite corners of a pixel buffer has the exact same number of pixels as a straight line between two adjacent corners. Mind blown.

Anyways, I tried out horizontal, vertical and diagonal lines through the buffer for the audio sampling. It all makes sense and sounds a bit different depending on the image. Maybe switch between those?

Tried out a rotating line as well, but it creates some sound effects that look like they don't fit to what is happening on screen, since the line will not be visible in the end.

Resizing the buffer creates some problems with the audio line and I don't know why. I also don't really know how large the "audio block" array is supposed to be that the digital signal processing receives. It works, but I am not sure how.

At least I found out that it works asynchronously, so now a thread safe copy of the buffer is created for the DSP to use.

## 250401

I received the Intech Studio Grid PBF4 controller today. It is fully customizable and programmable, (looks way cooler), and has some sliders and toggle buttons as well! This will come in handy. This way I can also stop using my laptop keys for controls and move to a controller fully.

## 250402

When changing xStep and yStep, the offset can now be determined randomly, getting rid of that "coming in from the top left corner" effect. It looks like it is juggling around the cells, which is interesting, but I also added a toggle to the offset being even on all sides, going back to how it looked before, if I want that.

## 250403

Implemented a toggle that when enabled, automatically saves a screenshot with a timestamp to a specific folder every X seconds.

Using toggles with the controller buttons seems complicated. It remembers its button states by its LEDs being on or off, but doesn't necessarily represent what the corresponding variables in the sketch will be. Solution for now is to always send the actual midi values, instead of just a toggle signal. Unfortunately this means that sometimes a button has to be pressed twice to "catch up" with what states the sketch has, but at least the LEDs will match this way. This is not full duplex at all.

Experimented with vibe coding some more shaders. Seems very powerful, but prompting is pretty difficult if you don't exactly know what outcome you even want. Seems similar to my regular coding.

## 250404

Midi controller buttons now have a short and long press to toggle, effectively giving me double the buttons on one page. Something is weird though still.

The three most recent screenshots will now be displayed in the control sketch. Maybe actually saving them permanently can be handled here somehow, so that the folder doesn't becomes too large?

## 250407

Talked a bunch to the creators of the midi controllor on their forum. Hopefully the press/toggle logic is working now, since there seems to be some bug in their software. They said they will fix it. 

Screenshots are now saved to a "temp" folder by the main sketch. If there are more than 100 files, the oldest one will be deleted. From that "temp" folder, the X most recent ones are displayed in the control sketch. When clicking on one of them, it will be permanently saved to a "saved" folder. That way I only keep the nice ones. At least while I am actually looking at it.

## 250408

Added the showDebug toggle to the midi controller.

Rearranged some code into separate files for better overview.

Talked to my professor about the actual exhibition. Will I just have the installation running there or will I actively present it somehow?

Experimented with some new shaders. It seems like they will be very interchangeable, so I will put their creation date in the files' names.

## 250409

It seems to make a difference if I just feed the regular buffer into the shaders as an input texture, or if I have a copy called tempBuffer and use that. Not sure what exactly is happening yet. Also, the function resizeBuffer() doesn't always work like I expect it to, I need to look further into that.

A solution for the problem where the button states vary from the main sketch and the midi controller's memory could be to reset the controller whenever the program starts.

I also need all of the variables that I control manually now, to also be controllable automatically. Need to remember that.

Found out that apparently I can set the DSP's audio block to a custom size!

## 250411

Talked to the person who oversees the exhibition space. I will use one of the square 3x3m walls for the projection. I need to come up with a way to mount the projector though. I don't want the stand they have, because it looks bulky. Instead I want to use one of the slim poles that they usually use for the walls. Instead of just a screen for the control sketch, I want to have a monitoring station, where I occasionally change some settings manually with the controller. Got the idea from a videogame I played, where an FBI-like agency is monitoring paranormal events with all sorts of contraptions, really like that aesthetic. I want to attach a screen, the midi controller and a mouse to that pole somehow.

Should also think about the speaker setup I will use at some point.

## 250412

Figured out how to reset the controller buttons on program start. I can send a signal to the controller and have some logic on it to reset everything. However, this doesn't solve issue yet where it looses track on page change.

## 250414

Talked to professor again. I think I will get away with just using the projector's built perspective functions to map the projection to the surface. Maybe for when I don't have such a nice projector, I need to think about coding some mapping functions into the program.

The sound is quite annoying right now. Maybe I can use a filter to make it a bit more bearable.

Did some UI rearrangements. At the end I will want it to be fullscreen anyways, so this is preliminary.

Further experimented to achieve true "buffer ping pong", where the shader output is actually used as an input for the next shader frame. Still complicated, not sure it is really working yet.

## 250417

Went to fullscreen for the control application. It runs so slow now.

Rescaling the screenshot before displaying helps a bit, but the graphs updating looks really choppy and tanks the framerate.

Managed to switch the control sketch to P2D, which helps the performance, but somehow breaks fullscreen mode.

Instead of in the entire background, I will now display the graphs in their own little box. Helps performance. Also makes them very hard to read, maybe they should be less detailed (have a wider step).

## 250422

Tried actual speakers for the first time. The very high end of the sound spectrum should be completely filtered out, it just hurts your ear.

Professor though the new controller would be a great way to maybe also perform on the installation a bit. Maybe it can be a hybrid? I could call it a "performance installation".

## 250501

Worked on some new shaders.

I think I finally achieved "true buffer ping pong" by using the tempBuffer. Resizing the grid now works correctly with buffer and tempBuffer, by copying a cut of the old buffer to a smaller new one or scaling up the old buffer to a bigger new one.

This also stops the shaders from looking like they are stuck sometimes. My theory is that previously they would sometimes keep receiving the same input texture over multiple frames, showing no change whenever resizeBuffer() was called.

Maybe I should move completely away from using mix(input, output) at the end of the shaders and only display the output? Should produce similar results IF the buffer ping pong technique is actually working.

## 250508

Tried all day to get a working "ReactionDiffusion" shader. Maybe I should stop trying and focus on something else for now?

## 250519

Decided I will treat the exhibition as a first iteration. Can always add more shaders down the line. Every exhibition (if there are more) will look different, depending on which shaders I use.

Tried to combine low and high pass sound filters. It doesn't really act like I want it to. I think a band pass filter might be the solution. Or should I combine it with some other stuff?

## 250520

Got a band pass filter that works as expected. A noise object is now controlling its position and width on the spectrum. Need to tinker with the actual available ranges though.

## 250522

I think I achieved what I will title as "pseude duplex" communication. On startup, the main sketch now sends button statuses to the midi controller and updates short and long press values. The controller also sends a "page change" update back to the program, so it can receive the button statuses then as well. It is not true "full duplex", but effectively does the same thing. The Intech Studio people said that wouldn't be possible in the forum. Take that!

## 250523

Screenshot saving now occurs in another thread to avoid the small hiccup every time.

For the noiseColor that doesn't use a shader, I now use a leadingColor where each pixel just has a random offset from that leadingColor. Looks interesting, but still after lots of optimization doesn't go above 45fps. Not good, not terrible.

## 250526

Instead of the screenshots moving one slot to the left when a new one comes in, they remain in their slot until they are the oldest one before being replaced. Makes it much easier to actually save one, because they don't change positions every three seconds.

Added two new shaders, one with simple Voronoi cells and one that has a new input uniform "numberOfCells" to display the correct number of cells as the input texture had. Really I wanted the shader to figure that out by itself, but maybe a new uniform like that can also be used by other shaders? Up until now I thought the best way would be to only have the grid dimensions, time value and input texture as input uniforms. Let's test this further.

Spent half the day testing different anti aliasing methods for the shaders. Do not want obvious jagged edges or stairs to appear, the edges should be smooth. Now I know why this is such a problem in videogames.

## 250528

The main sketch now sends a list of shader names to the control sketch, so they can be displayed in the control sketch. Whichever shader is active is highlighted.

Added "commit mono" font to the control sketch. It will be partly user facing, so it needs to look at least a bit nice. Hope it portrays a bit of a scientific tool look as well.

## 250529

Added solo / mute buttons to the shader list. The control sketch now sends a list of active shaders to the main sketch, which then determines the pool of shaders that can actually be used.

Hovering over and saving screenshots is now a bit better indicated and uses a flag instead of a time, so it will be apparent which screenshot has already been saved.

I found a library called FastNoiseLite. Maybe I can use that to make the noise color stuff that isn't in the shaders more interesting. But not today.

## 250530

Using FastNoiseLite to control the offset of noiseColor sometimes. Getting some interesting noise textures appearing from it. It also has a bunch of noise algorithms, like Perlin or OpenSimplex, to choose from. The program will switch between these noise algorithms occasionally.
The input coordinates for where in those pre-calculated noise fields the sketch gets its values from, how it "moves through the noise field", are determined by a noise object as well! This means that whatever noise texture is visible in the grid will be stretched and squished in both X and Y directions, but also speed up and slow down (in Z direction).

Changed the original FlowField shader to move in mostly one direction. Noticed that Voronoi shaders get faster over time. Maybe I need to pass something other than the time as an input uniform?

## 250602

The time input uniform "u_time" now gets reset to 0 when it reaches 1000, so that shaders do not get faster indefinitely.

Did the first test with the actual large projector: It looks stunning. Very bright and really lush colors. Getting excited. Plus I can probably get away with using its built in mapping functions.

When I set my desktop background to black and run the sketch in windowed mode, I can easily move it to the correct position on the wall. Seems like a bit of a hacky way to map something, but it isn't stupid if it works.

Actually, when removing the title bar from the window, there is no handle to move it anymore. So I need to implement moving the window with the arrow keys somehow. Not that easy to actually access all these functions. Seems like I am layers deep into the stack Processing is built on. Interesting to dig around in here, but also scary, like pulling back the curtain.

Implemented a mode where FastNoiseColor not only determines the noiseColor offset, but where each individual cell's color is determined fully by noise. That is kind of what I originally wanted to achieve before I moved to shaders. Thank god I didn't find out about this library before, or I maybe would never have started using shaders. At least now, I have a couple of different ways to generate input textures for the shaders.

## 250603

Implemented a manual way to switch between using a different shader each frame or not.

Added a new shader where a "pulse" moves in irregular lines accross the buffer. Tried to change some older shaders so they would adhere to the input texture's colors more. Don't want it to look like they generate new colors so much.

Control sketch was crashing often when switching on or off some shaders. I think I fixed it!

Added a new shader that sections the input texture and shuffles these sections around.

## 250606

Added a new shader that rotates pixels around variable rotation centers. Looks a bit like little washing mashines. Ends up grey often, which I guess makes sense, but should be avoided somehow. Also added a shader that does this, but always around the buffer's center.

## 250611

Added a new shader where such a rotation center moves around the buffer.

Added controls for speeding up or slowing down shader application. Very tricky due to the way shaders are implemented in general, because this should only change in the few instances where shaders are actually applied and the time input uniform changes.

Behavior of the shader settings in the control sketch and the actual list of active shaders in the main sketch was not quite working. Needs to remember the last used shader whenever no shader is used so it can continue correctly when they are reenabled. Looks like its working now?

## 250612

Implemented a globalSpeedDivisor that just divides the framerate up. Looks choppy but might come in handy for performing a bit.

Finally got around to experimenting with lerp() for all color changes. That way I could have control over the sketch's speed without affecting its framerate. Have a more "calm" looking mode. BUT it just does not work really. Everything is based on direct pixel manipulations. When the color's change gradually, it just looks wrong. The colors never really "catch up" so to speak. Need to roll all of this back.

Can now change the band pass filter manually as well. Not sure if I need this, but is nice for demonstration.

## 250613

Just experimenting with more shaders at this point. Added one called "GradientCellularAutomaton". Feels like I am hallucinating just as much as the AI I am vibe coding the shader with at this point.

## 250620

Second exhibition day. Photographer asked me if I could stop the sketch so he can take a photo. I never thought about that previously, but it was easy enough to implement quickly.

## 250911

Add some preliminary licenses. Thought about some other common licensing allowing use while mentioning me as an author, but for now I just wanted to secure my work at all.

## 250917

Separated into two display modes: one windowed, and one where the main sketch will be undecorated and movable like before, but also have some mapping handles for corner correction, and save all these parameters on a JSON so that on the same setup, even somebody else could start the program and just hit a button to reenable the mapping.

## 250921

Made the two tables on the bottom left be scrollable as one combined table, in case the window height is too small or there are more shaders in the future (need to test this with actually more shaders).

## 251009

The previous attempts at mapping controls where not correct. Now, the 4 corner handles are correct pins, and the buffer is now subdivided to apply bilinear interpolation.

## 251111

Was recently contemplating why all shaders kind of sound the same. The solution was that whenever a shader runs, the audio comes from the last buffer draw before switching to the shader. Added a method where the audio buffer will actually be updated with what the shaders are drawing in the main buffer every time a shader runs. Now the sound is corresponding to what is happening on screen at all times, which is incredibly noticable.