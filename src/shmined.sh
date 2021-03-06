#!/bin/bash

############################################################################
##                                                                        ##
## shMined - The minesweeper game, in Bash!                               ##
##                                                                        ##
## Copyright (C) 2011  Fabien LOISON <flo at flogisoft dot com>           ##
##                                                                        ##
## This program is free software: you can redistribute it and/or modify   ##
## it under the terms of the GNU General Public License as published by   ##
## the Free Software Foundation, either version 3 of the License, or      ##
## (at your option) any later version.                                    ##
##                                                                        ##
## This program is distributed in the hope that it will be useful,        ##
## but WITHOUT ANY WARRANTY; without even the implied warranty of         ##
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          ##
## GNU General Public License for more details.                           ##
##                                                                        ##
## You should have received a copy of the GNU General Public License      ##
## along with this program.  If not, see <http://www.gnu.org/licenses/>.  ##
##                                                                        ##
############################################################################


#Set some informations
APPNAME=shMined
VERSION=1.0
COPYRIGHT="Copyright (C) 2011  Fabien LOISON"


#Go to the scrip directory
cd "${0%/*}" 1> /dev/null 2> /dev/null


#Import
. tui.sh
. kbmouse.sh


COLOR_WIN_BG=237
COLOR_CELL=(253 255)
COLOR_FLAG_BG=(160 196)
COLOR_FLAG_FG=255
COLOR_WATER=(250 250)
COLOR_MINE_BG=52
COLOR_MINE_FG=207
COLOR_NUMB=(21 28 196 18 90 124 52 232)
COLOR_MSG_BG=255
COLOR_MSG_FG=88
COLOR_BTN_BG=255
COLOR_BTN_FG=88


NUMB_MINES=80
REM_FLAGS=0
GRID_SIZE=24
GRID=()
DISP_GRID=()
GRID_CB=""


copyright_screen() {
	## Display the copyright screen.

	tui_draw_rect 16 1 1 $(tui_window_get_width) $(tui_window_get_height)
	for color in {232..255} {254..232}; do
		tui_color_set_background 16
		tui_color_set_foreground $color
		tui_print_hcenter 5 "     _            _                _ "
		tui_print_hcenter 6 " ___| |__   /\/\ (_)_ __   ___  __| |"
		tui_print_hcenter 7 "/ __| '_ \ /    \| | '_ \ / _ \/ _\` |"
		tui_print_hcenter 8 "\__ \ | | / /\/\ \ | | | |  __/ (_| |"
		tui_print_hcenter 9 "|___/_| |_\/    \/_|_| |_|\___|\__,_|"
		tui_print_hcenter 12 'The minesweeper game, in Bash!'
		tui_print_hcenter $(($(tui_window_get_height)-1)) "${COPYRIGHT}"
		[ $color == 255 ] && sleep 3 || sleep .05
	done
	tui_draw_rect 16 1 1 $(tui_window_get_width) $(tui_window_get_height)
}


grid_init() {
	## Generates a grid with random mines.

	#Initialize grids
	for ((i=0 ; i<$(($GRID_SIZE**2)) ; i++)) ; do
		GRID[$i]="."
		DISP_GRID[$i]="."
	done

	#Put the mines
	mines=$NUMB_MINES
	while [ $mines -gt 0 ] ; do
		randpos=$(($RANDOM*$GRID_SIZE**2/32767))
		if [ ${GRID[$randpos]} == "." ] ; then
			GRID[$randpos]="O"
			mines=$(($mines-1))
		fi
	done
}


grid_xy_to_index() {
	## Convert the x and y position of the grid in the arry index.
	##
	## Args:
	##   $1 -- x
	##   $2 -- y

	echo $(($2*$GRID_SIZE+$1))
}


grid_refresh() {
	i=0
	x=1
	y=1
	c=0
	while [ $y -le $GRID_SIZE ] ; do
		#Go to the right line
		tui_cursor_move_to 1 $y
		while [ $x -le $GRID_SIZE ] ; do
			#Set the color variant
			test $((($i+$y)%2)) == 0 && c=1 || c=0
			#Draw a cell
			case ${DISP_GRID[$i]} in
				.) #Cell
					tui_color_set_background ${COLOR_CELL[$c]}
					#test ${GRID[$i]} == O && tui_color_set_background 213 #FIXME
					echo -n "  "
					;;
				f) #Flag
					tui_color_set_background ${COLOR_FLAG_BG[$c]}
					tui_color_set_foreground ${COLOR_FLAG_FG}
					echo -n '!!'
					;;
				w) #Water
					tui_color_set_background ${COLOR_WATER[$c]}
					echo -n "  "
					;;
				O) #Mine (game over)
					tui_color_set_background ${COLOR_MINE_BG}
					tui_color_set_foreground ${COLOR_MINE_FG}
					echo -n "()"
					;;
				1|2|3|4|5|6|7|8) #Number
					tui_color_set_background ${COLOR_WATER[$c]}
					tui_color_set_foreground ${COLOR_NUMB[$((${DISP_GRID[$i]}-1))]}
					echo -n "${DISP_GRID[$i]} "
					;;
			esac
			#Increment
			i=$(($i+1))
			x=$(($x+1))
		done
		#Increment
		x=1
		y=$(($y+1))
	done
}


grid_mouse_event_cb() {
	## Handle every mouse event on the grid.
	## <Button_Event> <Modifier> <x> <y>
	
	tui_window_set_title "${APPNAME}"

	#Calculate the cell
	x=$(($3/2+$3%2-1))
	y=$(($4-1))

	if [ $1 == MOUSE_BTN_LEFT_PRESSED ] && [ $2 == MODIFIER_NONE ] ; then     #==Discover
		index=$(grid_xy_to_index $x $y)
		if [ ${GRID[$index]} == "O" ] && [ ${DISP_GRID[$index]} == "." ] ; then #Mine!
			game_over
		elif [ ${DISP_GRID[$index]} == "." ] ; then #Water
			grid_cell_stats $x $y
			#Water or Number
			if [ $mines == 0 ] ; then 
				DISP_GRID[$index]="w"
			else
				DISP_GRID[$index]="${mines}"
			fi
			[ $mines == 0 ] && game_expand_water
			grid_refresh
			game_check_end
		fi
	elif [ $1 == MOUSE_BTN_MIDDLE_PRESSED ] || ( [ $1 == MOUSE_BTN_LEFT_PRESSED ] \
		&& [ $2 == MODIFIER_CONTROL ] ); then #==Flag
		game_toggle_flag $x $y
		grid_refresh
	fi
}


grid_cell_stats() {
	## Get the number of mine and water cell arround the giver cell.
	##
	## Args:
	##   $1 -- x
	##   $2 -- y
	##
	## Return:
	##   $mines $water

	index=$(grid_xy_to_index $1 $2)

	mines=0
	water=0
	for ((dy=$(($2-1)) ; dy<=$(($2+1)) ; dy++)) ; do
		for ((dx=$(($1-1)) ; dx<=$(($1+1)) ; dx++)) ; do
			#Check if the coordinate are in the grid
			[ $dx -lt 0 ] && continue
			[ $dy -lt 0 ] && continue
			[ $dx -ge $GRID_SIZE ] && continue
			[ $dy -ge $GRID_SIZE ] && continue
			#Count mines
			[ "${GRID[$(grid_xy_to_index $dx $dy)]}" == "O" ] && mines=$(($mines+1))
			#Count water
			[ "${DISP_GRID[$(grid_xy_to_index $dx $dy)]}" == "w" ] && water=$(($water+1))
		done
	done
}


game_expand_water() {
	## Discover a water area.

	tui_window_set_title "${APPNAME} [Please wait...]"

	#Display a message
	tui_color_set_background $COLOR_MSG_BG
	tui_color_set_foreground $COLOR_MSG_FG
	tui_print_xy 8 11 " ╭───────────────────────────────╮ "
	tui_print_xy 8 12 " │  P L E A S E   W A I T . . .  │ "
	tui_print_xy 8 13 " ╰───────────────────────────────╯ "

	change=1
	while [ $change == 1 ] ; do
		change=0
		for ((gy=0 ; gy<$GRID_SIZE ; gy++)) ; do
			for ((gx=0 ; gx<$GRID_SIZE ; gx++)) ; do

				[ ${DISP_GRID[$(grid_xy_to_index $gx $gy)]} != "." ] && continue

				grid_cell_stats $gx $gy

				if [ $water -gt 0 ] ; then
					change=1
					#Water or Number
					[ $mines == 0 ] && DISP_GRID[$(grid_xy_to_index $gx $gy)]="w" \
						            || DISP_GRID[$(grid_xy_to_index $gx $gy)]="${mines}"
				fi

			done
		done

		[ $change == 0 ] && break || change=0

		for ((gy=$(($GRID_SIZE-1)) ; gy>=0 ; gy--)) ; do
			for ((gx=$(($GRID_SIZE-1)) ; gx>=0 ; gx--)) ; do

				[ ${DISP_GRID[$(grid_xy_to_index $gx $gy)]} != "." ] && continue

				grid_cell_stats $gx $gy

				if [ $water -gt 0 ] ; then
					change=1
					#Water or Number
					[ $mines == 0 ] && DISP_GRID[$(grid_xy_to_index $gx $gy)]="w" \
						            || DISP_GRID[$(grid_xy_to_index $gx $gy)]="${mines}"
				fi
			done
		done
	done

	tui_window_set_title "${APPNAME}"
}


game_toggle_flag() {
	## Toggle the flag at the (x,y) position.
	##
	## Args:
	##   $1 -- x
	##   $2 -- y

	index=$(grid_xy_to_index $1 $2)

	if [ ${DISP_GRID[$index]} == "." ] ; then
		if [ $REM_FLAGS -gt 0 ] ; then
			DISP_GRID[$index]="f"
			REM_FLAGS=$(($REM_FLAGS-1))
		fi
	elif [ ${DISP_GRID[$index]} == "f" ] ; then
		DISP_GRID[$index]="."
		REM_FLAGS=$(($REM_FLAGS+1))
	fi

	draw_remaining_flags
}


game_check_end() {
	## Check if the player win.

	win=1
	for ((i=0 ; i<$(($GRID_SIZE**2)) ; i++)) ; do
		if [ ${DISP_GRID[$i]} == "." ] && [ ${GRID[$i]} != "O" ] ; then
			win=0
			break
		elif [ ${DISP_GRID[$i]} == "f" ] && [ ${GRID[$i]} != "O" ] ; then
			win=0
			break
		fi
	done

	if [ $win == 1 ] ; then #Game finished
		game_end
		tui_window_set_title "${APPNAME} [Good Game]"
		#Display a message
		tui_color_set_background $COLOR_MSG_BG
		tui_color_set_foreground $COLOR_MSG_FG
		tui_print_xy 8 11 " ╭───────────────────────────────╮ "
		tui_print_xy 8 12 " │       G O O D   G A M E       │ "
		tui_print_xy 8 13 " ╰───────────────────────────────╯ "
	fi
}


game_over() {
	## Display the Game Over screen.

	game_end
	tui_window_set_title "${APPNAME} [Game Over]"
	for ((i=0 ; i<$(($GRID_SIZE**2)) ; i++)) ; do
		[ ${GRID[$i]} == "O" ] && DISP_GRID[$i]=O
	done
	grid_refresh
	#Display a message
	tui_color_set_background $COLOR_MSG_BG
	tui_color_set_foreground $COLOR_MSG_FG
	tui_print_xy 8 11 " ╭───────────────────────────────╮ "
	tui_print_xy 8 12 " │       G A M E   O V E R       │ "
	tui_print_xy 8 13 " ╰───────────────────────────────╯ "
	draw_smiley_dead
}


game_new() {
	## New game.

	REM_FLAGS=$NUMB_MINES
	grid_init
	grid_refresh
	kbmouse_mouse_event_add_callback 1 1 $(($GRID_SIZE*2)) $GRID_SIZE grid_mouse_event_cb
	GRID_CB=$(kbmouse_mouse_event_get_latest_callback)
	tui_window_set_title "${APPNAME} [New Game]"
	draw_smiley_alive
	draw_remaining_flags
}


game_end() {
	## Must be called when the game is finished.

	kbmouse_mouse_event_rm_callback "${GRID_CB}"
	GRID_CB=""
}


draw_remaining_flags() {
	## Draw the number of remaining flags.

	tui_draw_rect 240 51 15 78 15 
	tui_color_set_background 240
	tui_color_set_foreground 255
	_text="$((${NUMB_MINES}-${REM_FLAGS})) / ${NUMB_MINES}"
	tui_print_xy $(((78+51)/2-${#_text}/2+1)) 15 "${_text}"
}


draw_smiley_alive() {
	## Draw the alive smile.

	tui_draw_rect 240 51 2 78 13
	tui_draw_rect 255 55 3 58 4
	tui_draw_rect 255 71 3 74 4
	tui_draw_rect 255 53 10 54 10
	tui_draw_rect 255 75 10 76 10
	tui_draw_rect 255 55 11 74 11
}


draw_smiley_dead() {
	## Draw the dead smile.

	tui_draw_rect 240 51 2 78 13

	tui_draw_rect 255 53 3 54 3
	tui_draw_rect 255 57 3 58 3
	tui_draw_rect 255 71 3 72 3
	tui_draw_rect 255 75 3 76 3

	tui_draw_rect 255 55 4 56 4
	tui_draw_rect 255 73 4 74 4

	tui_draw_rect 255 53 5 54 5
	tui_draw_rect 255 57 5 58 5
	tui_draw_rect 255 71 5 72 5
	tui_draw_rect 255 75 5 76 5

	tui_draw_rect 255 55 9 74 9
	tui_draw_rect 255 53 10 54 10
	tui_draw_rect 255 75 10 76 10

	tui_draw_rect 255 65 10 66 10
	tui_draw_rect 255 70 10 71 10
	tui_draw_rect 255 65 11 66 11
	tui_draw_rect 255 70 11 71 11
	tui_draw_rect 255 67 12 69 12
}


btn_quit_cb() {
	## Handle every mouse event on the quit button.
	## <Button_Event> <Modifier> <x> <y>

	if [ $1 == MOUSE_BTN_LEFT_PRESSED ] ; then
		game_quit
	fi
}


btn_new_game_cb() {
	## Handle every mouse event on the new game button.
	## <Button_Event> <Modifier> <x> <y>

	if [ $1 == MOUSE_BTN_LEFT_PRESSED ] ; then
		game_end
		game_new
	fi
}


game_quit() {
	## Quit the game (restore the normal state of the terminal).

	tui_color_set_background
	kbmouse_terminal_release
	exit 0
}



#== Main ==

kbmouse_terminal_init
trap game_quit INT
tui_window_set_title "${APPNAME}"
copyright_screen

#Clear the screen
tui_draw_rect $COLOR_WIN_BG 1 1 $(tui_window_get_width) $(tui_window_get_height)

#Quit button
tui_draw_text_rect $COLOR_BTN_BG $COLOR_BTN_FG 51 21 78 23 "Quit"
kbmouse_mouse_event_add_callback 51 21 78 23 btn_quit_cb

#New Game button
tui_draw_text_rect $COLOR_BTN_BG $COLOR_BTN_FG 51 17 78 19 "New Game"
kbmouse_mouse_event_add_callback 51 17 78 19 btn_new_game_cb

game_new

#Main loop
while : ; do
	event=$(kbmouse_raw_input_read)
	kbmouse_mouse_event_check_callback "$event"
done

