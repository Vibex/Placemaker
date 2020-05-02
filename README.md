# placemaker

placemaker is a powerful wrapper for wmutils. It is designed to simplify the process of managing windows and allow users to easily create tiling/stacking patterns.

## Requirements
- wmutils/core
- bash (also works with my zsh configuration, though your mileage may vary)

## Usage
Commands follow the format <code>placemaker [SETTINGS] [MODE]</code>
### Settings
Used to alter the default behavior of placemaker.
+ <code>--geometry X0 Y0 X1 Y1</code> : Set the geometry boundaries for window placement. <code>X0</code>, <code>Y0</code>, <code>X1</code>, and <code>Y1</code> are all either an integer value or the character <code>c</code>. If they are set to <code>c</code> than the will use the currently stored value (which defaults to the bounds of the root window).
  + <code>X0</code> = The left most x boundary to use.
  + <code>Y0</code> = The top most y boundary to use.
  + <code>X1</code> = The right most x boundary to use.
  + <code>Y1</code> = The bottom most y boundary to use.
+ <code>--gap GAP</code> : Set a gap that separates windows from the geometry. <code>GAP</code> is an 
+ <code>--flip</code> : Flip the y placement of windows.
+ <code>--mirror</code> : Mirror the x placement of windows.
+ <code>--ignore-bor</code> : Don't use the output of <code>wattr b WID</code> to adjust window placement.
+ <code>--print</code> : Don't move windows, only print adjustments to stdout.
+ <code>--quiet</code> : Don't print window adjustments to stdout. 
+ <code>-h, --help</code> : Print help text to stdout.

### Mode

Used to position windows based on their id value, <code>WID</code>.

- `-P, --place X Y W H WID` :  Place a window at the specified <code>X</code> and <code>Y</code> coordinates, with a width of <code>W</code> and a height of <code>H</code>. <code>X</code>, <code>Y</code>, <code>W</code>, and <code>H</code> are all either an integer value or the character <code>c</code>. If they are set to <code>c</code> than the will use the windows current value.

- <code>-V, --save [ATOM] WID</code> : Save a windows current geometry to an <code>ATOM</code>. If no <code>ATOM</code> is specified, the string <code>PLACEMAKER_SAVE</code> is used.

  - <code>ATOM</code> is a string representing the X atom that the geometry will be saved to. The only restrictions on an <code>ATOM</code> are that they can not begin with the characters <code>0x</code> or be the string <code>--erase</code> as these are used for other functionality.

- <code>-R, --restore [ATOM] [--erase] WID</code> : Restore a window to a saved geometry. If no <code>ATOM</code> is specified, the string <code>PLACEMAKER_SAVE</code> is used. The definition of an <code>ATOM</code> can be found with the <code>--save</code> argument. If the <code>--erase</code> argument is passed before the <code>WID</code> the atom will be set to an empty string after the window is positioned.

- <code>-C, --center WID</code> : Center a given window within the set geometry. <code>--gap 0</code> is automatically set when <code>--center</code> is called.

- <code>-S, --slam S_DIR WID</code> :  Move the window to the geometry bounds in a specified direction.

  - <code>S_DIR</code> is one of:
    - <code>up</code> or <code>north</code> : Move the window to the top bound of the geometry.
    - <code>right</code> or <code>east</code> : Move the window to the right bound of the geometry.
    - <code>down</code> or <code>south</code> : Move the window to the bottom bound of the geometry.
    - <code>left</code> or <code>west</code> : Move the window to the left bound of the geometry.
    - <code>upperleft</code> or <code>northwest</code> : Move the window to the top and left bounds of the geometry.
    - <code>upperright</code> or <code>northeast</code> : Move the window to the top and right bounds of the geometry.
    - <code>lowerleft</code> or <code>southwest</code> : Move the window to the bottom and left bounds of the geometry.
    - <code>lowerright</code> or <code>southeast</code> : Move the window to the top and left bounds of the geometry.

- <code>-M, --max M_DIR WID</code> : Maximize a window in a specified direction.

  - <code>M_DIR</code> is one of:
    - <code>up</code> or <code>north</code> : Move the top bound of the window to the top bound of the geometry, without changing the position of the windows bottom bound.
    - <code>right</code> or <code>east</code> : Move the right bound of the window to the right bound of the geometry, without changing the position of the windows left bound.
    - <code>down</code> or <code>south</code> : Move the bottom bound of the window to the bottom bound of the geometry, without changing the position of the windows top bound.
    - <code>left</code> or <code>west</code> : Move the left bound of the window to the left bound of the geometry, without changing the position of the windows right bound.
    - <code>horizontal</code> : Maximize the window to fill the full horizontal geometry.
    - <code>vertical </code>: Maximize the window to fill the full vertical geometry.
    - <code>full</code> : Maximize the window to fill the full geometry.

- <code>-L, --scale PERCENT WID</code> : Scale a windows size by a given percentage. <code>--ignore-bor</code> is automatically set when <code>--scale</code> is called.

- <code>-G, --grid GRID [POSITION] WIDS</code> :  Places a windows in virtual grid cells, starting at a specified position. If no <code>POSITION</code> is passed, it defaults to <code>0,0</code>.

  - <code>GRID</code> is two integers connected by the character <code>x</code>.

    - Example: <code>2x3</code> will create the following virtual grid.

      ```
      +----------------+----------------+
      |                |                |
      |                |                |
      |                |                |
      +----------------+----------------+
      |                |                |
      |                |                |
      |                |                |
      +----------------+----------------+
      |                |                |
      |                |                |
      |                |                |
      +----------------+----------------+
      ```

  - <code>POSITION</code> is two integers connected by the character <code>,</code>.

    - Example: <code>1,2</code> will place a window in the middle leftmost cell in a <code>2x3</code> grid.

      ```
      +----------------+----------------+
      |                |                |
      |                |                |
      |                |                |
      +----------------+----------------+
      |                |                |
      |                |       wid      |
      |                |                |
      +----------------+----------------+
      |                |                |
      |                |                |
      |                |                |
      +----------------+----------------+
      ```

- <code>-T, --tile RATIO PATTERN WIDS</code> : Tile windows with a specified pattern, and master ratio. If only a single window is passed in, the <code>monocle</code> pattern will always be used.

  - <code>RATIO</code> is two integers connected by an <code>/</code> representing the size of the master window.

    - Example:  <code>2/3</code> will produce the following master and sub placements with a <code>hstack</code> pattern.

      ```
      +---------------------------------+
      |                                 |
      |                                 |
      |                                 |
      |              master             |
      |                                 |
      |                                 |
      |                                 |
      +---------------------------------+
      |                                 |
      |               sub               |
      |                                 |
      +---------------------------------+
      ```

  - <code>PATTERN</code> is one of:

    - <code>monocle</code> or <code>max</code> or <code>m</code> :  All tiled windows are the maximum geometry size. This ignores <code>RATIO</code>, though a variable must still be passed for it.
    - <code>rstack</code> or <code>vstack</code> or <code>r</code> : The master window is on the left of the screen, and sub windows stack vertically on the right of the screen.
    - <code>lstack</code> or <code>l</code> : The master window is on the right of the screen, and sub windows stack vertically on the left of the screen.
    - <code>bstack</code> or <code>hstack</code> or <code>b</code> : The master window is on the top of the screen, and sub windows stack horizontally on the bottom of the screen.
    - <code>tstack</code> or <code>t</code> : The master window is on the bottom of the screen, and sub windows stack horizontally on the top of the screen.

## Advanced Usage

#### Direct Window Adjustments

By appending additional information to a <code>WID</code> you can adjust a window after it has been processed by placemakers other functions. Any number of adjustments can be appended in any order to a <code>WID</code>.

- Geometry Adjustment
  - By appending <code>+X,Y,W,H</code> to a <code>WID</code> you can adjust the windows position after placemaker has processed the window, but before it has been moved.
    - Example: <code>0x00000000+10,20,-10,-20</code> will move 0x00000000 10 pixels to the right and 20 pixels down, and decrease its width by 10 pixels and its height by 20 pixels. This will occur regardless of what function processes the window.
- Position Adjustment
  - By appending <code>+S_DIR</code> (the parameter for the <code>--slam</code> function) to a <code>WID</code> you can position a window within its determined geometry. When this is done the windows width and height will be their current value. This can be used in conjunction with <code>--tile</code> to produce a psuedo tiled mode, where windows are positioned in their tiled locations, but are free to be any size.
    - Example: <code>0x00000000+upperright</code> will position 0x00000000 in the upper right hand corner of its set geometry.
- Reflection Adjustment
  - By appending <code>+mirror</code> or <code>+flip</code> you can toggle the mirror or flip state for the window.
- WID Adjustment
  - By appending <code>+WID</code> you can change what window will actually be effected by the movement. This can be used to "steal" the position of a window and apply it to something else.
    - Example: <code>0x00000000+0x00000001</code> will use 0x00000000 for all of the window calculations, but move 0x00000001.

#### Grid Placement

<code>--grid</code> is the most complex function in placemaker, as it is designed to allow others to create there own tiling patterns to fit their own needs. Its true argument syntax is

 <code>--grid GRID [BEHAVIOR POSITION WIDS | BEHAVIOR WIDS | POSITION WIDS | WIDS]...</code>

and it can take any number of these arguments, dynamically adjusting window placement on the way.

##### Behavior

By default <code>--grid</code> will automatically place all windows after the first <code>WID</code> one cell lower. This behavior can be altered by passing a <code>BEHAVIOR</code>. 

<code>BEHAVIOR</code> is one of:

- <code>--x-shift</code> : <code>WIDS</code> after this one will be placed one cell to the right.
- <code>--y-shift</code> : <code>WIDS</code> after this one will be placed one cell lower. This the default.
- <code>--no-auto</code> : All <code>WIDS</code> will be placed in this location.

##### Position

In addition to the format specified in the Usage section, a position can also be two sets of integers connected by the character <code>,</code>, connected by the character <code>+</code>. The first set of integers represents a standard  <code>POSITION</code>. The second set is the number of cells that the <code>WID</code> will occupy.

Example: <code>0,0+1,2</code> will place a window in the top left cell, through the middle left cell of a <code>2x3</code> grid.

```
+----------------+----------------+
|                |                |
|                |                |
|                |                |
|      wid       +----------------+
|                |                |
|                |                |
|                |                |
+----------------+----------------+
|                |                |
|                |                |
|                |                |
+----------------+----------------+
```

#### Internal Functions

In addition to the Modes listed in the Usage section, there is also <code>-I, --internal</code>. This mode exposes the internal functions of placemaker to the user. This allows for the usage of things like the built in data parsers when creating new patterns. When calling an internal function fn_ is automatically prepended to the call.

Example: <code>-I parseGrid x 3x4</code> will call the fn_parseGrid function, and return 3.

A complete list of functions and documentation can be found in the source code, but the key functions are:

- <code>getAttribute</code> : Get an internal window attribute, ignoring direct window adjustments if they are present.
- <code>parseGrid</code> : Return a requested value from a <code>GRID</code>.
- <code>parsePosition</code> : Return a requested value from a <code>POSITION</code>.
- <code>checkPosition</code> : If <code>parsePosition</code> returns the character <code>o</code> set an override value
- <code>parseRatio</code> : Return a requested value from a <code>RATIO</code>.

## Todo

* Add column and row patterns.
* Add dwindle pattern variants to lstack, rstack, bstack, and tstack.
* Add ability to read from stdin.
* Add inverted behaviors to Grid.
* Add example patterns to allow users to jumpstart their own patterns.
* Possibly rewrite in C++ (though there are pros and cons to this).
