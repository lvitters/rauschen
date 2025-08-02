# RAUSCHEN

*RAUSCHEN* is an emergent performance installation exploring the possibility space of a 1000x1000 pixel image. It generates a random, but orderly grid of pixels or cells according to a range of RNG and noise algorithms. These regular textures are fed into a modular shader system, consisting of contributions from conversations with currently popular LLMs.<br>
*RAUSCHEN* then freely mixes and recursively feeds back their results into emergent textures of visual patterns and auditory noise, flashing by in quick succession. A control application constantly monitors its output in numbers and parameters, is able to save the generated textures to disk and provides the option to influence the pattern generation in order to perform a more curated visual experience.<br>
While current image generation models denoise their random input textures using techniques under the broad term diffusion, *RAUSCHEN* uses procedural generation methods in order to achieve the opposite effect, infusing its fundamental noise textures with structural patterns for now only recognisable by the viewer.

<br>

*Is this what being trained must feel like to an AI?*

<br>

# RAUSCHEN_processing

*RAUSCHEN* is driven by a Processing 4.3.2 application running on macOS that creates a buffer of custom dimensions and fills it with randomly colored cells of pixels each frame.

<br>

## Colors

The color of the cells is determined by a range of pseudo random number generators that determine their RGB values:

<br>

- individual random number for each value and each cell

- a leading color determined by a custom Noise class, with each cell having a slight offset from that leading color that is also calculated by a custom Noise class

- a leading color determined by a custom Noise class, with each cell having a slight offset from that leading color that is calculated by a random one of the Noise types from the [FastNoiseLite](https://github.com/Auburn/FastNoiseLite) lib

- the entire grid of cells determined by a random one of the Noise types from [FastNoiseLite](https://github.com/Auburn/FastNoiseLite) lib

<br>

## Cells

The cells can range in dimensions from 1 up to the dimensions of the buffer, and can be either square or rectangular. The dimensions of the cells, called xStep and yStep, are determined by a custom Noise class. All cells always have the same dimensions in a single frame.

<br>

## Noise class

For many operations, a custom Noise class is used that can return either a Noise value from 0 to 1, a Boolean determined by Noise, a Noise range from a custom low and high value, a Noise range from a custom low value range and a custom high value range, or each of those with a custom bias. The Noise class uses Processing's built in Perlin Noise. The increment with which they are computed can be set on initialization.

<br>

Noises are added to a list of Noises so they can be send to the control application.

<br>

## Shaders

Occasionally, instead of displayed the grid of cells, *RAUSCHEN* will apply a random shader from a list of shaders to the buffer. The shaders take a texture called tempBuffer as an input that is either the last grid of cells OR the last shader output. Depending on which event has fired last, this can be either the same shader multiple consecutive frames in a row, or a random different shader each frame, effectively mixing their outputs together.

<br>

## Events

A random event happens every X seconds. These include:

<br>

- setting up new dimensions for either the grid of cells or the buffer

- switch to applying shaders instead of displaying the grid of cells

- switch between the grid of cells' colors being determined by the options described above ("Colors")

- switch between using the same shader in consecutive frames or using a random different shader each frame

<br>

The time between two events can either be set manually, or be picked at random between each frame and a maximum interval.

<br>

## Sound

Each frame, a thread-safe copy is made of the buffer. Using the digital signal processing in [Wellen](https://github.com/dennisppaul/wellen), a sound sample is created from the buffer's pixels. The sample consists of a either horizontal, vertical or diagonal line of pixels, whose average color channel values ((R + G + B) / 3) are mapped to a frequency range. The sample is then passed through a band pass filter, where frequency and bandwidth are determined by - you guessed it - the custom Noise class.

<br>

## Screenshot

At a set interval, *RAUSCHEN* will create a new thread in order to save the display buffer as a screenshot, with a timestamp in its file name. If the screenshot folder exceeds a set number of screenshot, the oldest one will be deleted.

<br>

## Controls

Although there is a separate application to control *RAUSCHEN*, there are some rudimentary controls available:

<br>

**'F' key** - show rudimentary debug info

**'P' key** - print debug info to console

**'A' key** - toggle *Auto Mode* (enable automatic *events* or not)

**'S' key** - choose a random event now

**'N' key** - toggle audio

**SPACE** - halt the entire application (good for photos)

<br>

In order to map the application to a surface with a projector, the window's menu bar can be disabled by the toggle *isUndecorated*. The window can then be resized with the **'+'** and **'-'** keys, and moved around the screen with the **arrow keys**.

<br>