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


## tui.sh -- Various function for drawing and handling a TUI.


tui_window_set_title() {
	## Set the title of the terminal's window.
	##
	## Args:
	##   $1 -- The window's title

	echo -en "\e]0;$1\a"
}


tui_window_get_height() {
	## Get the height of the terminal's window.

	stty size | cut -d " " -f 1
}


tui_window_get_width() {
	## Get the height of the terminal's window.

	stty size | cut -d " " -f 2
}


tui_cursor_move_to() {
	## Move the cursor to the specified position
	##
	## Args:
	##   $1 -- x
	##   $2 -- y

	echo -en "\e[${2};${1}H"
}


tui_color_set_background() {
	## Set the background color.
	##
	## Args:
	##   $1 -- The background color
	##
	## NOTE: If no argument are given, the color is reset all (background,
	##       foreground and formatting) to the default.

	if [ $# == 0 ] ; then
		echo -en "\e[0m"
	else
		if [ $1 -le 7 ] ; then    # 8 colors mode
			echo -en "\e[4${1}m"
		elif [ $1 -le 15 ] ; then # 16 colors mode
			echo -en "\e[10$(($1-8))m"
		else                      # 88/256 colors mode
			echo -en "\e[48;5;${1}m"
		fi
	fi
}


tui_color_set_foreground() {
	## Set the foreground color.
	##
	## Args:
	##   $1 -- The foreground color
	##
	## NOTE: If no argument are given, the color is reset all (background,
	##       foreground and formatting) to the default.

	if [ $# == 0 ] ; then
		echo -en "\e[0m"
	else
		if [ $1 -le 7 ] ; then    # 8 colors mode
			echo -en "\e[3${1}m"
		elif [ $1 -le 15 ] ; then # 16 colors mode
			echo -en "\e[9$(($1-8))m"
		else                      # 88/256 colors mode
			echo -en "\e[38;5;${1}m"
		fi
	fi
}


tui_print_xy() {
	## Print a text at the specified position.
	##
	## Args:
	##   $1 -- x
	##   $2 -- y
	##   $3 -- The text to print

	tui_cursor_move_to $1 $2
	echo -n "$3"
}


tui_print_hcenter() {
	## Print a text horizontally centered.
	##
	## Args:
	##   $1 -- y
	##   $2 -- The text to print

	posx=$(($(tui_window_get_width)/2-${#2}/2))
	tui_print_xy $posx $1 "$2"
}


tui_draw_rect() {
	## Draw a rectangle.
	##
	## Args:
	##   $1 -- Background color (0-255)
	##   $2 -- x1
	##   $3 -- y1
	##   $4 -- x2
	##   $5 -- y2

	line=""
	for ((i=$2 ; i<=$4 ; i++)) ; do
		line=" ${line}"
	done
	for ((i=$3 ; i<=$5 ; i++)) ; do
		tui_cursor_move_to $2 $i
		tui_color_set_background $1
		echo -n "${line}"
	done
	tui_color_set_background
}


tui_draw_text_rect() {
	## Draw a rectangle with a text inside.
	##
	## Args:
	##   $1 -- Background color (0-255)
	##   $2 -- Foreground color (0-255)
	##   $3 -- x1
	##   $4 -- y1
	##   $5 -- x2
	##   $6 -- y2
	##   $7 -- The text

	tui_draw_rect $1 $3 $4 $5 $6
	txtx=$(($3+(($5-$3)/2)-${#7}/2+1))
	txty=$(($4+(($6-$4)/2)))
	tui_cursor_move_to $txtx $txty
	tui_color_set_background $1
	tui_color_set_foreground $2
	echo -n "$7"
	tui_color_set_background
}
