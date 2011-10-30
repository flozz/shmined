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


## kbmouse.sh -- Mouse and keyboard input support.


_ESC=$(echo -en "\e")


kbmouse_terminal_init() {
	## Initialize the terminal for mouse tracking

	stty -echo -icanon   #No echo, no line buffering
	echo -en "\e[?25l"   #Hide cursor
	echo -en "\e[?1001h" #Mouse tracking (all events)
}


kbmouse_terminal_release() {
	## Restaure the "normal" retting of the terminal

	echo -en "\e[?1001l" #No mouse tracking (all events)
	echo -en "\e[?25h"   #Show cursor
	stty echo icanon     #Echo, line buffering
}


kbmouse_raw_input_read() {
	## Return a raw input sequence composed of 1, 2, 3 or 6 Bytes.

	read -n1 seq0
	if [ "${seq0}" == "${_ESC}" ] ; then   # ^[
		read -n1 -t1 seq1
		if [ "${seq1}" == "[" ] ; then     # [
			read -n1 -t1 seq2
			if [ "${seq2}" == "M" ] ; then # M
				read -n3 -t1 seq3
				echo -n "${seq0}${seq1}${seq2}${seq3}"
			else
				echo -n "${seq0}${seq1}${seq2}"
			fi
		else
			echo -n "${seq0}${seq1}"
		fi
	else
		echo -n "${seq0}"
	fi
}


kbmouse_raw_input_get_type() {
	## Get the event type.
	##
	## Args:
	##   $1 -- The raw input sequence
	##
	## Returns:
	##   One of the following value:
	##     INPUT_TYPE_NULL (Enter, Space, Tab)
	##     INPUT_TYPE_MOUSE
	##     INPUT_TYPE_KB_UP
	##     INPUT_TYPE_KB_DOWN
	##     INPUT_TYPE_KB_RIGHT
	##     INPUT_TYPE_KB_LEFT

	#Sequence length
	len=${#1}

	if [ $len == 0 ] ; then
		echo INPUT_TYPE_NULL
	elif [ $len == 1 ] ; then
		echo INPUT_TYPE_CHAR
	else
		[ "${1:0:3}" == "${_ESC}[M" ] && echo INPUT_TYPE_MOUSE
		[ "${1:0:3}" == "${_ESC}[A" ] && echo INPUT_TYPE_KB_UP
		[ "${1:0:3}" == "${_ESC}[B" ] && echo INPUT_TYPE_KB_DOWN
		[ "${1:0:3}" == "${_ESC}[C" ] && echo INPUT_TYPE_KB_RIGHT
		[ "${1:0:3}" == "${_ESC}[D" ] && echo INPUT_TYPE_KB_LEFT
	fi
}


_kbmouse_mouse_event_decode() {
	## Decode the mouse events.
	##
	## Args:
	##   $1 -- The raw mouse sequence
	##
	## Returns:
	##   The decoded mouse event: "Button_Event Modifier y x"

	#Sequence length
	len=${#1}

	#Button and modifier
	btn=(MOUSE_BTN_LEFT_PRESSED MODIFIER_NONE)
	if [ $len == 6 ] ; then
		raw_btn=${1:3:1}
		[ "${raw_btn}" == "0" ] && btn=(MOUSE_BTN_LEFT_PRESSED   MODIFIER_CONTROL     )
		[ "${raw_btn}" == "8" ] && btn=(MOUSE_BTN_LEFT_PRESSED   MODIFIER_CONTROL_ALT )
		[ "${raw_btn}" == '!' ] && btn=(MOUSE_BTN_MIDDLE_PRESSED MODIFIER_NONE        )
		[ "${raw_btn}" == '1' ] && btn=(MOUSE_BTN_MIDDLE_PRESSED MODIFIER_CONTROL     )
		[ "${raw_btn}" == '9' ] && btn=(MOUSE_BTN_MIDDLE_PRESSED MODIFIER_CONTROL_ALT )
		[ "${raw_btn}" == "#" ] && btn=(MOUSE_BTN_RELEASED       MODIFIER_NONE        )
		[ "${raw_btn}" == "3" ] && btn=(MOUSE_BTN_RELEASED       MODIFIER_CONTROL     )
		[ "${raw_btn}" == ";" ] && btn=(MOUSE_BTN_RELEASED       MODIFIER_CONTROL_ALT )
		[ "${raw_btn}" == '`' ] && btn=(MOUSE_SCROLL_UP          MODIFIER_NONE        )
		[ "${raw_btn}" == "p" ] && btn=(MOUSE_SCROLL_UP          MODIFIER_CONTROL     )
		[ "${raw_btn}" == "x" ] && btn=(MOUSE_SCROLL_UP          MODIFIER_CONTROL_ALT )
		[ "${raw_btn}" == "a" ] && btn=(MOUSE_SCROLL_DOWN        MODIFIER_NONE        )
		[ "${raw_btn}" == "q" ] && btn=(MOUSE_SCROLL_DOWN        MODIFIER_CONTROL     )
		[ "${raw_btn}" == "y" ] && btn=(MOUSE_SCROLL_DOWN        MODIFIER_CONTROL_ALT )
	fi

	#Mouse position
	[ $len == 5 ] && raw_pos=${1:3:2} || raw_pos=${1:4:2}
	posx=$(printf "%u" "'${raw_pos:0:1}")
	posx=$(($posx - 32))
	posy=$(printf "%u" "'${raw_pos:1:1}")
	posy=$(($posy - 32))

	#Result
	echo ${btn[0]} ${btn[1]} $posy $posx
}


kbmouse_mouse_event_get_button() {
	## Get the mouse button from a raw mouse event.
	##
	## Args:
	##   $1 -- The raw mouse sequence
	##
	## Returns:
	##   One of the following values:
	##     MOUSE_BTN_LEFT_PRESSED
	##     MOUSE_BTN_MIDDLE_PRESSED
	##     MOUSE_BTN_RELEASED
	##     MOUSE_SCROLL_UP
	##     MOUSE_SCROLL_DOWN

	_kbmouse_mouse_event_decode "$1" | cut -d " " -f 1
}


kbmouse_mouse_event_get_modifier() {
	## Get the modifier from a raw mouse event.
	##
	## Args:
	##   $1 -- The raw mouse sequence
	##
	## Returns:
	##   One of the following values:
	##     MODIFIER_NONE
	##     MODIFIER_CONTROL
	##     MODIFIER_CONTROL_ALT

	_kbmouse_mouse_event_decode "$1" | cut -d " " -f 2
}


kbmouse_mouse_event_get_posy() {
	## Get the x mouse position from a raw mouse event.
	##
	## Args:
	##   $1 -- The raw mouse sequence
	##
	## Returns:
	##   The x mouse position

	_kbmouse_mouse_event_decode "$1" | cut -d " " -f 3
}


kbmouse_mouse_event_get_posx() {
	## Get the y mouse position from a raw mouse event.
	##
	## Args:
	##   $1 -- The raw mouse sequence
	##
	## Returns:
	##   The y mouse position

	_kbmouse_mouse_event_decode "$1" | cut -d " " -f 4
}
