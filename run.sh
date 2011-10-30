#!/bin/bash


#Go to the scrip directory
cd "${0%/*}" 1> /dev/null 2> /dev/null

#Launch shMined
./src/shmined.sh

exit 0
