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


#Main
kbmouse_terminal_init
tui_window_set_title "${APPNAME}"
copyright_screen
kbmouse_terminal_release
