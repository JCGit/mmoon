#!/bin/bash

if [ "$1" == "tmux" ]; then
	tmux split-window -h sh $0 console
	cd src
	lua FullStack.lua

	if [ $? -gt 0 ]; then
		bash
	fi
elif [ "$1" == "console" ]; then
	function ctrl_c()
	{
		tmux kill-session
	}
	trap ctrl_c INT
	sleep 1
	rlwrap nc localhost 4444
else
	tmux new-session sh $0 tmux
fi

