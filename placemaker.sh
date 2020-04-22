# !/bin/bash
####
#### PLACEMAKER
####
## placemaker is a window manipulation tool
##
## Requires Xorg, wmutils/core, wmutils/opt
##
## Optional mkwm


####
#### LIVE VARIABLES
####
## These can be altered by arguments and during runtime

# X position of the monitor
GX0=$(wattr x $(lsw -r))

# Y position of the monitor
GY0=$(wattr y $(lsw -r))

# Width of the monitor
GX1=$(wattr w $(lsw -r))

# Height of the monitor
GY1=$(wattr h $(lsw -r))

# Gap applied to the windows requested geometry and displayed geometry
GAP=0

# Are all requested window geometries mirrored on the x axis
# 0 = False
# 1 = True
MIRROR=0

# Are all requested window geometries flipped on the y axis
# 0 = False
# 1 = True
FLIP=0


####
#### FUNCTIONS
####

# Update the geometry to work within
# Arugments are either an int or ' c '
# If an int, than set that value
# If ' c ' than the value is not updated
# Arguments: x0 y0 x1 y1
fn_geometry() {
	if [[ "$1" != "c" ]]; then
		GX0=$1
	fi
	if [[ "$2" != "c" ]]; then
		GY0=$2
	fi
	if [[ "$3" != "c" ]]; then
		GX1=$3
	fi
	if [[ "$4" != "c" ]]; then
		GY1=$4
	fi
}

# Get an attribute for the given window
# This is just a left over from when there were other attribute retrieval methods
# Attributes are:
# x = x
# y = y
# w = width
# h = height
# b = border
# o = override_redirect
# m = map
# Arguments: wid attribute
fn_getAttribute() {
	local wid=$(echo "$1" | cut -d : -f 1)
	wattr "$2" "$wid"
}

# Teleport a window to a given position and size
# A wid is an id or an 'id:adjust'
# Examples:
# 0x00000000
# 0x00000000:5,5,-5,-5
# x, y, w, or h are either an int or ' c '
# If an int, than set that value
# If ' c ' than the value is not updated
# Arguments: wid x y w h
fn_teleportWid() {
	local wid=$(echo "$1" | cut -d : -f 1)
	
	local ox=0
	local oy=0
	local ow=0
	local oh=0
	if [[ "$1" == *":"* ]]; then
		local ototal="$(echo "$1" | cut -d : -f 2)"
		ox=$(echo "$ototal" | cut -d , -f 1)
		oy=$(echo "$ototal" | cut -d , -f 2)
		ow=$(echo "$ototal" | cut -d , -f 3)
		oh=$(echo "$ototal" | cut -d , -f 4)
	fi

	local nx=$2
	local ny=$3
	local nw=$4
	local nh=$5
	if [[ "$2" == "c" ]]; then
		nx=$(fn_getAttribute "$wid" "x")	
	fi
	if [[ "$3" == "c" ]]; then
		ny=$(fn_getAttribute "$wid" "y")	
	fi
	if [[ "$4" == "c" ]]; then
		nw=$(fn_getAttribute "$wid" "w")	
	fi
	if [[ "$5" == "c" ]]; then
		nh=$(fn_getAttribute "$wid" "h")	
	fi
	
	# Mirror if set
	if [[ $MIRROR -eq 1 ]]; then
		nx=$(( $GX1 - ( $nx + $nw ) + $GX0 ))	
	fi
	# Flip if set
	if [[ $FLIP -eq 1 ]]; then
		ny=$(( $GY1 - ( $ny + $nh ) + $GY0 ))	
	fi

	# Alter sizing with gaps and borders
	local bor="$(fn_getAttribute "$wid" b)"
	nx=$(( $nx + $GAP + $ox ))
	ny=$(( $ny + $GAP + $oy ))
	nw=$(( $nw - $GAP - $GAP - $bor - $bor + $ow ))
	nh=$(( $nh - $GAP - $GAP - $bor - $bor + $oh ))

	# Move window
	wtp "$nx" "$ny" "$nw" "$nh" "$wid"
}

# Slam a window in a specified direction
# Directions are:
# up	|	north
# right	|	east
# down	|	south
# left	|	west
# Arguments: wid directions...
fn_slamWid() {
	local wid="$1"
	shift 1;

	# Get starting geometry
	local nx=$(fn_getAttribute "$wid" "x")
	local ny=$(fn_getAttribute "$wid" "y")
	local nw=$(fn_getAttribute "$wid" "w")
	local nh=$(fn_getAttribute "$wid" "h")

	# Slam the window in the appropriate directions
	while :
	do
		case "$1" in
			"up" | "north")
				ny="$GY0"
				shift 1;;
			"right" | "east")
				nx=$(( $GX1 - $nw ))
				shift 1;;
			"down" | "south")
				ny=$(( $GY1 - $nh ))
				shift 1;;
			"left" | "west")
				nx="$GX0"
				shift 1;;
			*)
				break;;
		esac
	done

	# Move wid
	fn_teleportWid "$wid" "$nx" "$ny" "$nw" "$nh"
}

# Place a window into a specified corner
# Corners are
# upperleft		|	northwest
# upperright	|	northeast
# lowerleft		|	southwest
# lowerright	|	southeast
# Arguments: corner wid
fn_cornerWid() {
	# Check input and pass job to fn_slamWid
	case "$1" in
		"upperleft" | "northwest" ) fn_slamWid "$2" "north" "west";;
		"upperright" | "northeast" ) fn_slamWid "$2" "north" "east";;
		"lowerleft" | "southwest" ) fn_slamWid "$2" "south" "west";;
		"lowerright" | "southeast" ) fn_slamWid "$2" "south" "east";;
	esac
}

# Center a window
# Arguments: wid
fn_centerWid() {
	# Get starting geometry
	local nx=$(fn_getAttribute "$1" "x")
	local ny=$(fn_getAttribute "$1" "y")
	local nw=$(fn_getAttribute "$1" "w")
	local nh=$(fn_getAttribute "$1" "h")

	# Get center of work area
	local gcx=$(( ( $GX1 - $GX0 ) / 2 ))
	local gcy=$(( ( $GY1 - $GY0 ) / 2 ))
	local gcx=$(( $gcx + $GX0 ))
	local gcy=$(( $gcy + $GY0 ))

	# Adjust x and y to centered
	nx=$(( $gcx - ( $nw / 2 ) ))
	ny=$(( $gcy - ( $nh / 2 ) ))

	# Move wid
	fn_teleportWid "$1" "$nx" "$ny" "$nw" "$nh"

}

# Parse a Grid expression and return the requested variable
# Definition of Grid is with fn_gridWid
# x = x
# y = y
# Arguments: [x|y] grid
fn_parseGrid() {
	local out="Not valid argument"
	# Return x
	if [[ "$1" == "x" ]]; then
		out=$(echo "$2" | cut -d x -f 1)
	# Return y
	elif [[ "$1" == "y" ]]; then
		out=$(echo "$2" | cut -d x -f 2)
	fi
	echo "$out"
}

# Parse a Position expression and return the requested variable (or interpretation of said variable)
# Definition of Position is with fn_gridWid
# x  = x
# y  = y
# xs = xscale
# ys = yscale
# Arguments: [x|y|xs|ys] position
fn_parsePosition() {
	local out="Not valid argument"
	# Return x
	if [[ "$1" == "x" ]]; then
		out=$(echo "$2" | cut -d , -f 1)
	# Return y
	elif [[ "$1" == "y" ]]; then
		out=$(echo "$2" | cut -d , -f 2 | cut -d _ -f 1 | cut -d + -f 1)
	# Return xs
	# If there is no value in $2 than return 1
	elif [[ "$1" == "xs" ]]; then
		case "$2" in 
			*+*) out=$(echo "$2" | cut -d + -f 2 | cut -d , -f 1);;
			*) out=1;;
		esac
	# Return ys
	# If there is no value in $2 than return 1
	elif [[ "$1" == "ys" ]]; then
		case "$2" in 
			*+*) out=$(echo "$2" | cut -d + -f 2 | cut -d , -f 2);;
			*) out=1;;
		esac
	fi
	echo "$out"
}

# Place a window in a specified grid slot
# Note: All windows before the last square have there values floored, the last square will simply reach as far as is left avaliable
# A grid is an ' intxint '
# Example:
# 3x3		creates 9 cells
# A position is an ' int,int ' or ' int,int+int,int '
# Examples:
# 1,2		window placed in middle bottom cell in a 3,3 grid
# 1,0+1,1	window stretches from middle top cell through right middle cell in a 3,3 grid
# Arguments: grid position wid
fn_gridWid() {
	# Get Grid
	local xgrid=$(fn_parseGrid "x" "$1")
	local ygrid=$(fn_parseGrid "y" "$1")

	# Get position
	local xpos=$(fn_parsePosition "x" "$2")
	local ypos=$(fn_parsePosition "y" "$2")
	local xscale=$(fn_parsePosition "xs" "$2")
	local yscale=$(fn_parsePosition "ys" "$2")

	# Get dimensions for cells
	local xcell=$(( ( $GX1 - $GX0 ) / $xgrid ))
	local ycell=$(( ( $GY1 - $GY0 ) / $ygrid ))

	# Get x and y positions for the set cell
	local nx=$(( ( $xcell * $xpos ) + $GX0 ))
	local ny=$(( ( $ycell * $ypos ) + $GY0 ))

	# If the wid is in the last x cell of the grid, than adjust to compensate for rounding errors in cell size
	if [[ $(( $xpos + $xscale )) -eq $xgrid ]]; then
		local nw=$(( $GX1 - $nx ))
	else
		local nw=$(( $xscale * $xcell ))
	fi

	# If the wid is in the last y cell of the grid, than adjust to compensate for rounding errors in cell size
	if [[ "$(( $ypos + $yscale ))" -eq "$ygrid" ]]; then
		local nh=$(( $GY1 - $ny ))
	else
		local nh=$(( $yscale * $ycell ))
	fi

	# Move wid
	fn_teleportWid "$3" "$nx" "$ny" "$nw" "$nh"
}

# Check a parsed position expressions output, if the output was o use the override value
# Definition of Position is with fn_gridWid
# x  = x
# y  = y
# Arguments: [x|y] position override value
fn_checkPosition() {
	local out="$(fn_parsePosition $1 $2)"
	if [[ "$out" == "o" ]]; then
		out="$3"
	fi
	echo "$out"
}

# Place a list of windows in a grid automatically (can switch behavior or specify specific positions as well)
# Definition of Position and Grid is with fn_gridWid
# A behavior is:
# --x-shift = windows are placed along the x axis, followed by the y axis
# --y-shift = windows are placed along the y axis, followed by the x axis - DEFAULT
# --no-auto = windows are not automatically place, and will use the same coordinates until a new one is given
# Arguments: grid [ behavior position wid | behavior wid | position wid | wid ]
# NOTE: position behavior wid is INVALID INPUT
fn_gridMany() {
	# Get grid
	local xcalcgrid=$(fn_parseGrid "x" "$1")
	local ycalcgrid=$(fn_parseGrid "y" "$1")
	local madegrid="$1"
	shift 1

	# Check to see if the second arg was a behavior
	# If it was than deal with it
	# this needs to be handled differently so that the next check can run properly
	local sorder=0
	if [[ "$1" == "--x-shift" ]]; then
		sorder=1
		shift 1
	elif [[ "$1" == "--y-shift" ]]; then
		sorder=0
		shift 1
	elif [[ "$1" == "--no-auto" ]]; then
		sorder=2
		shift 1
	fi

	# If the arg was a wid than set default position
	local cxpos=$(fn_parsePosition "x" "$1")
	if [[ -z "$fxpos" ]]; then
		cxpos=0
		local cypos=0
	# If arg was a position than set it as the current position
	else
		local cypos=$(fn_parsePosition "y" "$1")
	fi

	# Loop through all remaining args
	while :
	do
		# Reset this value, it stores if a window was moved, and the cxpos and cypos
		local moved=0
		local xshift=1
		local yshift=1
		case "$1" in
			# If the arg was a behavior switches
			"--x-shift" )
				sorder=1
				shift 1;;
			"--y-shift" )
				sorder=0
				shift 1;;
			"--no-auto" )
				sorder=2
				shift 1;;

			# If the arg  was a wid
			0x* )
				# Move window
				moved=1
				fn_gridWid "$madegrid" "$cxpos,$cypos" "$1"
				# Initialize values for update
				shift 1;;
			# If the arg was a position
			*,* )
				# Initialize values for update
				cxpos=$(fn_checkPosition "x" "$1" $cxpos) # Keep using cxpos if o was set
				cypos=$(fn_checkPosition "y" "$1" $cypos) # Keep using cypos if o was set
				xshift=$(fn_parsePosition "xs" "$1")
				yshift=$(fn_parsePosition "ys" "$1")
				# Move window
				moved=1
				fn_gridWid "$madegrid" "$cxpos,$cypos+$xshift,$yshift" "$2"
				shift 2;;
			*) break;;
		esac

		# If a window was moved update the next positon
		if [[ "$moved" -eq 1 ]]; then
			# If --y-next is set than shift on y axis
			if [[ "$sorder" -eq 0 ]]; then
				cypos=$(( $cypos + $yshift ))
				# If reach end, cycle on x
				if [[ "$cypos" -ge "$ycalcgrid" ]]; then
					cypos=0
					cxpos=$(( $cxpos + $xshift ))
					# If reached end, cycle
					if [[ "$cxpos" -ge "$xcalcgrid" ]]; then
						cxpos=0
					fi
				fi
			# If --x-next is set than shift on y axis
			elif [[ "$sorder" -eq 1 ]]; then
				cxpos=$(( $cxpos + $xshift ))
				# If reach end, cycle on y
				if [[ "$cxpos" -ge "$xcalcgrid" ]]; then
					cxpos=0
					cypos=$(( $cypos + $yshift ))
					# If reach end, cycle
					if [[ "$cypos" -ge "$ycalcgrid" ]]; then
						cypos=0
					fi
				fi
			# If --no-auto is set, than don't update anything
			#elif [[ "$sorder" -eq 2 ]]; then
			fi
		fi
	done
}

# Alternate the state of MIRROR
# Arguments: 
fn_setMirror() {
	if [[ $MIRROR -eq 0 ]]; then
		MIRROR=1
	else
		MIRROR=0
	fi
}

# Alternate the state of FLIP
# Arguments: 
fn_setFlip() {
	if [[ $FLIP -eq 0 ]]; then
		FLIP=1
	else
		FLIP=0
	fi
}

# Parse a ratio expression and return the requested variable
# Definition of Ratio is with fn_tile
# c = master count
# m = master
# t = total
# Arguments: [c|m|t] ratio
fn_parseRatio() {
	local out="Not valid argument"
	# Return m
	if [[ "$1" == "c" ]]; then
		out=$(echo "$2" | cut -d / -f 1)
	# Return m
	elif [[ "$1" == "m" ]]; then
		out=$(echo "$2" | cut -d / -f 1)
	# Return t
	elif [[ "$1" == "t" ]]; then
		out=$(echo "$2" | cut -d / -f 2)
	fi
	echo "$out"
}

# Take an arbitrary list on windows and tile them in a given pattern
# A ratio is the representation of the master window size to the total monitor size, master/total
# A ratio is a ' int/int ' or ' int-int/int '
# Examples:
# 6/10 		master window takes up 6/10 of the screen and sub windows take up 4/10
# 2-3/4		2 master windows take up 3/4 of the screen and a sub windows take up 1/4
# A pattern is one of:
# monocle	| max		| m = single window displayed filling all of given area
# rstack	| vstack	| r = main window displayed on the left with the stack on the right
# lstack	| 			| l = main window displayed on the right with the stack on the left
# bstack	| hstack	| b = main window displayed on the top with the stack on the bottom
# tstack	| 			| t = main window displayed on the bottom with the stack on the top
# Arguments: ratio pattern wid...
fn_tile() {
	# Get the ratios
	mastercount=$(fn_parseRatio "c" "$1")
	mratio=$(fn_parseRatio "m" "$1")
	tratio=$(fn_parseRatio "t" "$1")
	shift 1

	# Set the pattern
	pattern="$1"
	shift 1
	
	# If the pattern is monocle or the list of wids is less than or equal to 1, than use monocle tiling
	if [[ "$pattern" == "monocle" ]] || [[ "$pattern" == "max" ]] || [[ "$pattern" == "m" ]] || [[ "$#" -le 1 ]]; then
		fn_gridMany "1x1" "--no-auto" $@;
	else
		# Set the master
		master="$1"
		shift 1
	
		# Use appropriate tiling
		case "$pattern" in
			# rstack tiling
			"rstack" | "vstack" | "r" | "lstack" | "l" )
				if [[ "$pattern" == "l"* ]]; then
					fn_setMirror
				fi
				
				# Calculate the grid
				shiftmode="--y-shift"
				tilexgrid="$tratio"
				tileygrid="$#"

				# Calculate Master window
				masterpos="0,0+$mratio,$tileygrid"
				
				# Initialize sub 
				subpos0=$mratio
				subpos1="o"
				subpos2=$(( $tratio - $mratio ))
				subpos3="1";;
			"bstack" | "hstack" | "b" | "tstack" | "t" )
				if [[ "$pattern" == "t"* ]]; then
					fn_setFlip
				fi
				
				# Calculate the grid
				shiftmode="--x-shift"
				tilexgrid="$#"
				tileygrid="$tratio"

				# Calculate Master window
				masterpos="0,0+$tilexgrid,$mratio"
				
				# Initialize sub 
				subpos0="o"
				subpos1=$mratio
				subpos2="1"
				subpos3=$(( $tratio - $mratio ));;
			*) echo "$pattern is no a valid pattern"; exit;;
		esac
		# Loop through all subs and give them the appropriate 
		sub=""
		while :
		do
			case "$1" in
				0x* )
					# Calculate the position for this sub
					subpos="$subpos0,$subpos1+$subpos2,$subpos3"
					sub="$sub$subpos $1 "
					shift 1;;
				* ) break;;
			esac
		done
		tilegrid="$(echo $tilexgrid)x$tileygrid"
		fn_gridMany "$tilegrid" "$shiftmode" "$masterpos" "$master" $sub
	fi
}

# Print Usage information
# Arguments: 
fn_usageMore() {
	echo ""
	echo "WID"
	echo "  WID is the id of the window you wish to manipulate."
	echo "  You can also attach ':x,y,w,h' to your id to add additional manipulation to a window"
	echo "    Example: $(pfw)"
	echo "    Example: $(pfw):5,10,-5,-10"
	echo ""
	echo "WIDS"
	echo "  A list of an arbitrary number of WID." 
	echo ""
	echo "Gap    --gap GAP"
	echo "  GAP is an int representing a border between the window and the geometry." 
	echo ""
	echo "Geometry    --geometry X0 Y0 X1 Y1"
	echo "  X0 = the left most x boundary to use"
	echo "  Y0 = the left most y boundary to use"
	echo "  X1 = the right most x boundary to use"
	echo "  Y1 = the right most y boundary to use"
	echo "X0 Y0 X1 and Y1 can be set to 'c' to use their current value."
	echo ""
	echo "Corner    -C, --corner CORNER WID"
	echo "  CORNER is one of:"
	echo "    upperleft  | northwest"
	echo "    upperright | northeast"
	echo "    lowerleft  | southwest"
	echo "    lowerright | southeast"
	echo ""
	echo "Grid    -G, --grid GRID [BEHAVIOR POSITION WIDS | BEHAVIOR WIDS | POSITION WIDS | WIDS]..."
	echo "  GRID is two ints connected by an 'x'"
	echo "    Example: 3x3"
	echo "      +-----------------------------+"
	echo "      |         |         |         |"
	echo "      |         |         |         |"
	echo "      |         |         |         |"
	echo "      |---------+---------+---------|"
	echo "      |         |         |         |"
	echo "      |         |         |         |"
	echo "      |         |         |         |"
	echo "      |---------+---------+---------|"
	echo "      |         |         |         |"
	echo "      |         |         |         |"
	echo "      |         |         |         |"
	echo "      +-----------------------------+"
	echo ""
	echo "  BEHAVIOR is one of the follwing args"
	echo "    --x-shift = The window after the next one will be shifted on the x axis"
	echo "    --y-shift = The window after the next one will be shifted on the y axis. This is the Default setting."
	echo "    --no-auto = The windows will not be shifted at all, and only be placed in specified positions"
	echo "  BEHAVIOR does not effect the placement of the current window, instead it adjusts where placemaker thinks the following window should be put"
	echo ""
	echo "  POSITION is two ints connected by an ','"
	echo "    Example: 0,0	This will place the window in the top left cell of a 3x3 grid"
	echo "      +-----------------------------+"
	echo "      |         |         |         |"
	echo "      |   wid   |         |         |"
	echo "      |         |         |         |"
	echo "      |---------+---------+---------|"
	echo "      |         |         |         |"
	echo "      |         |         |         |"
	echo "      |         |         |         |"
	echo "      |---------+---------+---------|"
	echo "      |         |         |         |"
	echo "      |         |         |         |"
	echo "      |         |         |         |"
	echo "      +-----------------------------+"
	echo "  Or you can specify the number of cells that will be filled by connecting two pos with a '+'"
	echo "    Example: 0,0+2,3	This will place the window in the top left cell through the middle bottom cell of a 3x3 grid"
	echo "      +-----------------------------+"
	echo "      |                   |         |"
	echo "      |                   |         |"
	echo "      |                   |         |"
	echo "      |                   +---------|"
	echo "      |                   |         |"
	echo "      |        wid        |         |"
	echo "      |                   |         |"
	echo "      |                   +---------|"
	echo "      |                   |         |"
	echo "      |                   |         |"
	echo "      |                   |         |"
	echo "      +-----------------------------+"
	echo ""
	echo "Place    -p, --place WID X Y W H"
	echo "  X = the x position of the window"
	echo "  Y = the y position of the window"
	echo "  W = the width of the window"
	echo "  H = the height of the window"
	echo "X Y Y and H can be set to 'c' to use their current value."
	echo ""
	echo "Slam    -S, --slam WID DIRECTIONS..."
	echo "  DIRECTION is one of:"
	echo "  upperleft  | northwest"
	echo "  upperright | northeast"
	echo "  lowerleft  | southwest"
	echo "  lowerright | southeast"
	echo ""
	echo "Tile    -T, --tile RATIO PATTERN WIDS"
	echo "  RATIO is two ints connected by an '/'"
	echo "    The first int is the number of cells for the master window."
	echo "    The second int is the total number of cells"
	echo "    Example: 3/5	The master window takes up 3 cell while the sub windows take up 2"
	echo "  PATTERN is one of:"
	echo "    monocle | max    | m = single window displayed filling all of given area"
	echo "    rstack  | vstack | r = main window displayed on the left with the stack on the right"
	echo "    lstack  |        | l = main window displayed on the right with the stack on the left"
	echo "    bstack  | hstack | b = main window displayed on the top with the stack on the bottom"
	echo "    tstack  |        | t = main window displayed on the bottom with the stack on the top"
	echo ""
}

# Print Usage information
# Arguments: 
fn_usage() {	
	echo "Usage: placemaker [SETTINGS] [MODE]"
	echo "Place windows at specified positions throughout a geometry."
	echo ""
	echo "SETTINGS"
	echo "  --flip			flip the window placement along the y axis"
	echo "  --gap GAP			specify placement bounds"
	echo "  --geometry X0 Y0 X1 Y1	specify placement bounds"
	echo "  --mirror			mirror the window placement along the x axis"
	echo ""
	echo "  -h, --help			display this help text"
	echo "  --more-help			additional help text" 
	echo ""
	echo "MODE"
	echo "  -c, --center WID		center a window"
	echo "  -C, --corner CORNER WID	place a window in a corner"
	echo "  -G, --grid GRID POSITION WIDS	place windows in a grid cells"
	echo "  -p, --place WID X Y W H	place windows in a given position"
	echo "  -S, --slam WID DIRECTIONS	send a window in a direction"
	echo "  -T, --tile RATIO PATTERN WIDS	place windows using a pattern"
}

while :
do
	case "$1" in 
		"-h" | "--help" ) 
			fn_usage
			exit;;
		"--more-help" ) 
			fn_usage
			fn_usageMore
			exit;;
		"--flip" )
			fn_setFlip
			shift 1;;
		"--gap" )
			GAP=$2
			shift 2;;
		"--geometry" )
			fn_geometry $2 $3 $4 $5
			shift 5;;
		"--mirror" )
			fn_setMirror
			shift 1;;
		"-c" | "--center" )
			shift 1
			fn_centerWid $@
			exit;;
		"-C" | "--corner" )
			shift 1
			fn_cornerWid $@
			exit;;
		"-G" | "--grid" )
			shift 1
			fn_gridMany $@
			exit;;
		"-p" | "--place" )
			shift 1
			fn_teleportWid $@
			exit;;
		"-S" | "--slam" )
			shift 1
			fn_slamWid $@
			exit;;
		"-T" | "--tile" )
			shift 1
			fn_tile $@
			exit;;
		*) break;;
	esac
done
