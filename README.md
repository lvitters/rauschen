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

	/* GitHub-style table borders */
	table {
		border-collapse: collapse !important;
		border-spacing: 0 !important;
		border: 1px solid #d0d7de !important;
		margin: 1em 0 !important;
	}

	th, td {
		border: 1px solid #d0d7de !important;
		padding: 6px 13px !important;
		text-align: left !important;
	}

	th {
		background-color: #f6f8fa !important;
		font-weight: 600 !important;
	}
</style>
-->

# RAUSCHEN

<img src="./markdown_assets/20250620-RAUSCHEN-15-MikaStoerkel-rotated_resized.jpg" alt="RAUSCHEN projection 15">

<table>
<tr>
<td><img src="./markdown_assets/20250620-RAUSCHEN-3-MikaStoerkel_cut_resized.jpg" alt="RAUSCHEN projection 3"></td>
<td><img src="./markdown_assets/20250620-RAUSCHEN-2-MikaStoerkel_cut_resized.jpg" alt="RAUSCHEN projection 2"></td>
<td><img src="./markdown_assets/20250620-RAUSCHEN-5-MikaStoerkel_cut_resized.jpg" alt="RAUSCHEN projection 5"></td>
</tr>
</table>
<em>photos: <a href="https://mikastoerkel.com/">Mika Störkel</a></em>

<br>
<br>
<br>
<br>

RAUSCHEN ("noise") is a real-time emergent media system exploring the probability space of a 1,000×1,000 image. It generates textures through a variety of techniques such as white or Perlin noise to recursively feed into a modular palette of per-pixel algorithms. Running in quick succession, their results are continuously merged to synthesise exponentially random patterns. While contemporary image generation models use training data to impose meaning onto the noise, RAUSCHEN aims to chart new areas hidden within it. In the end, a human decides what is worth keeping.

<br>

*How can we find meaning within all this noise?*

<br>

[luccavitters.de/works/rauschen](https://luccavitters.de/works/rauschen)

<br>

## RAUSCHEN_processing

*RAUSCHEN* is driven by a *Processing 4.3.2* application running on *macOS* that creates a buffer of custom dimensions and fills it with randomly colored cells of pixels each frame, called *rauschen_processing*.

<br>

### colors

The color of the cells is determined by a range of pseudo random number generators that determine their RGB values:

- individual random number for each value and each cell

- a leading color determined by a custom Noise class, with each cell having a slight offset from that leading color that is also calculated by a custom Noise class

- a leading color determined by a custom Noise class, with each cell having a slight offset from that leading color that is calculated by a random one of the Noise types from the [FastNoiseLite](https://github.com/Auburn/FastNoiseLite) lib

- the entire grid of cells determined by a random one of the Noise types from [FastNoiseLite](https://github.com/Auburn/FastNoiseLite) lib

<br>

### cells

The cells can range in dimensions from 1 up to the dimensions of the buffer, and can be either square or rectangular. The dimensions of the cells, called **xStep** and **yStep**, are determined by a custom Noise class. All cells always have the same dimensions in a single frame.

<br>

### noise class

For many operations, a custom Noise class is used that can return either a Noise value from 0 to 1, a Boolean determined by Noise, a Noise range from a custom low and high value, a Noise range from a custom low value range and a custom high value range, or each of those with a custom bias. The Noise class uses Processing's built in Perlin Noise. The increment with which they are computed can be set on initialization.

Noises are added to a list of Noises so they can be send to the control application.

<br>

### shaders

Occasionally, instead of displayed the grid of cells, *RAUSCHEN* will apply a random shader from a list of shaders to the buffer. The shaders take a texture called tempBuffer as an input that is either the last grid of cells OR the last shader output. Depending on which event has fired last, this can be either the same shader multiple consecutive frames in a row, or a random different shader each frame, effectively mixing their outputs together.

<br>

### events

**Random Mode**

A random event happens every X seconds if **Random Mode** **(isRandomMode)** is active. These include:

- setting up new dimensions for the grid of cells **setNewGridWithNoise()**

- switch between the grid of cells' colors being determined by the options described in "colors" **isNoiseColorRandomOffset** / **isNoiseColorRandomOffset** / **isFastNoiseColor** / **isFastNoiseColorFastNoiseOffset**

- switch to applying shaders instead of displaying the grid of cells **isApplyingShaders**

- switch between using the same shader in consecutive frames or using a random different shader each frame **isRandomShaderEachFrame**

The time between two events can either be set manually, or be picked at random between each frame and a maximum interval.

<br>

**Chance Mode**

If **Chance Mode** **(!isRandomMode)** is active, an event is fired every X seconds from three categories determined by their chance values from 0 to 1:

- stepChance

- pixelColorModeChance

- shaderChance

<br>

**Auto Mode**

If **Auto Mode** **(isAutoMode)** is active, the time interval for the above events to happen is determined by another Noise object. If it is inactive, the **switchTime** can be controlled manually. For **Chance Mode**, if **Auto Mode** is active, the chance values themselves are determined by another Noise object each. If it is inactive, the chance values can be controlled manually.

<br>

### sound

Each frame, a thread-safe copy is made of the buffer. Using the digital signal processing in [**Wellen**](https://github.com/dennisppaul/wellen), a sound sample is created from the buffer's pixels. The sample consists of a either horizontal, vertical or diagonal line of pixels, whose average color channel values ((R + G + B) / 3) are mapped to a frequency range. The sample is then passed through a band pass filter, where frequency and bandwidth are determined by - you guessed it - the custom Noise class.

<br>

### screenshots

At a set interval, *RAUSCHEN* will create a new thread in order to save the display buffer as a screenshot, with a timestamp in its file name. If the screenshot folder (**'temp'**) exceeds a set number of screenshot, the oldest one will be deleted.

<table>
<tr>
<td><img src="./markdown_assets/rauschen-20250611-164109-577.png" alt="RAUSCHEN screenshot"></td>
<td><img src="./markdown_assets/rauschen-20250602-180127-227.png" alt="RAUSCHEN screenshot"></td>
<td><img src="./markdown_assets/rauschen-20250530-171029-416.png" alt="RAUSCHEN screenshot"></td>
</tr>
<tr>
<td><img src="./markdown_assets/rauschen-20250422-155733-347.png" alt="RAUSCHEN screenshot"></td>
<td><img src="./markdown_assets/rauschen-20250529-165834-148.png" alt="RAUSCHEN screenshot"></td>
<td><img src="./markdown_assets/rauschen-20250613-154959-102.png" alt="RAUSCHEN screenshot"></td>
</tr>
<tr>
<td><img src="./markdown_assets/rauschen-20250407-165205-809.png" alt="RAUSCHEN screenshot"></td>
<td><img src="./markdown_assets/rauschen-20250522-205038-804.png" alt="RAUSCHEN screenshot"></td>
<td><img src="./markdown_assets/rauschen-20250602-131859-168.png" alt="RAUSCHEN screenshot"></td>
</tr>
</table>

<br>

### controls

Although there is a separate application to control *RAUSCHEN*, there are some rudimentary controls available:

- **'F' key:** show rudimentary debug info

- **'P' key:** print debug info to console

- **'A' key:** toggle *Auto Mode*
  
- **'Q' key:** toggle between *Random Mode* and *Chance Mode*

- **'S' key:** choose a random event now

- **'N' key:** toggle audio
  
- **SPACE:** halt the entire application (good for photos)
  
<br>

In order to map the application to a surface with a projector, the window's menu bar can be disabled by setting the **displayMode** to 1. The buffer can then be resized with the **'+'** and **'-' keys**, and moved around the screen with the **arrow keys**. 
<br><br>
The **'C' key** will enable corner pins that can be moved around with the mouse to transform the buffer's edges. 
<br><br>
The **'X' key** will reset the current corners to their default positions. 
<br><br>
The corner pin positions, as well as the buffer's dimensions and position on the screen can be saved to a *JSON* using the **'K' key**. 
<br><br>
The last saved setup can be loaded via the **'L' key**.

<br><br>

## RAUSCHEN_processing_controls

*RAUSCHEN* is controlled by another *Processing 4.3.2* application running on *macOS* called *RAUSCHEN_processing_controls*.


<img src="./markdown_assets/250613_control_screenshot_resized.png" alt="RAUSCHEN controls">

<br>

### screenshots

*RAUSCHEN_processing_controls* scans the folder that *RAUSCHEN* saves screenshots to (**'temp'**) in a set interval. It displays the latest 4 a row of screenshots. When clicked on, it will save the corresponding screenshot to a permanent folder (**'saved'**).

### displayed data

*RAUSCHEN_processing_controls* receives a set of data from *RAUSCHEN_processing* via *OSC* messages:

- **'/noises'** contains the values of all the Noises from the list of Noises, in this case mapped from 0 to 1, and is displayed as differently colored graphs

- **'/info'** contains the variable names and their values, which are determined manually or by events, plus some debug information, and is displayed as a list of variable names and their values

- **'/shaderNames'** contains the names of the shaders added to the main application and is displayed as a list of available shaders, highlighting which one is currently in use

<br>

### controls

The variables present in the **'/info'** message can be set by *RAUSCHEN_processing_controls* sending *OSC* messages containing the corresponding key and value pairs back to *RAUSCHEN*. These variables will be overridden by the events from **Random Mode** or **Chance Mode** if either is active.

The list of shaders displayed in *RAUSCHEN_Processing_controls* contains buttons to **SOLO** and **MUTE** them, similar to audio tracks in a DAW. This enables to mix and match shaders freely when **isRandomShaderEachFrame** is active, or determine which random shaders can be chosen for consecutive frames when it is not active.

<br>

### midi-controller

*RAUSCHEN_processing_controls* uses the *Intech Studio Grid PBF4* midi controller. Its buttons and potentiometers are assigned to *MIDI* channels with the *Intech Studio Grid Editor 1.5.7*. *RAUSCHEN_processing_controls* listens to the set up *MIDI* channels, assigns their values to the corresponding variables and sends those pairs back to *RAUSCHEN_processing* via *OSC* messages.

<table>
<tr>
<td><img src="./markdown_assets/250802_Intech_Studio_Grid_PBF4_resized.jpg" alt="Intech Studio Grid PBF4"></td>
<td><img src="./markdown_assets/250802_Intech_Studio_Grid_Editor_1_resized.png" alt="Intech Studio Grid Editor"></td>
</tr>
</table>

Some logic, mainly for enabling short and long presses, is applied and saved directly to the controller in the form of *LUA* scripts.

<table>
<tr>
<td><img src="./markdown_assets/250802_Intech_Studio_Grid_Editor_2_resized.png" alt="Intech Studio Grid Button"></td>
<td><img src="./markdown_assets/250802_Intech_Studio_Grid_Editor_3_resized.png" alt="Intech Studio Grid Potientometer"></td>
</tr>
</table>

<br><br>

## setup

*RAUSCHEN* can either run on a screen in **AUTO MODE** or a performance station can be set up to manually control events and parameters or monitor and save screenshots.

<table>
<tr>
<td><img src="./markdown_assets/20250620-RAUSCHEN-22-MikaStoerkel_cut_resized.jpg" alt="monitoring station"></td>
<td><img src="./markdown_assets/20250620-RAUSCHEN-14-MikaStoerkel_cut_resized.jpg" alt="midi controller performing"></td>
</tr>
</table>
<em>photos: <a href="https://mikastoerkel.com/">Mika Störkel</a></em>

<br><br>

## RAUSCHEN_prints

*RAUSCHEN_prints* contains some *SvelteKit* components that produce a multi-page PDF for printing screenshots in batches. The screenshots will have their filenames printed on the bottom right in order to provide a unique timestamp as an identifier.


<img src="./markdown_assets/PXL_20250619_113636889_cut_resized.jpg" alt="RAUSCHEN prints">

A similar technique was used to produce the following graphics:

<table>
<tr>
<td><img src="./markdown_assets/250605_sharepic34_resized.png" alt="RAUSCHEN poster 3:4"></td>
<td><img src="./markdown_assets/250605_square_resized.png" alt="RAUSCHEN sharepic square"></td>
</tr>
</table>

<br><br>

## _other

*_other* contains some files from early tests, such as the initial *p5.js* version of *RAUSCHEN*.
