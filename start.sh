#!/bin/bash
set -e # fail on error
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR
screen -dm -S GeneralIOC -c screenrc
echo "Screen session with name GeneralIOC started."
