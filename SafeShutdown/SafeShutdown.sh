#!/bin/bash

# Better GPi Safe Shutdown - 2022 Sliver X
# Based on multi_switch.sh by crcerror
# https://github.com/crcerror/ES-generic-shutdown
# -----------------------------------------------

# This function is called until all childPIDs are found.
# ------------------------------------------------------
function get_childpids() {
local CPIDS="$(pgrep -P $1)"
for cpid in $CPIDS; do
pidarray+=($cpid)
get_childpids $CPIDS
done
}

# Watchdog to kill emu-processes with sig 9 level after 2.0s
# If emulator PID is active after 5.0s, return to call.
# Prevents ES from being termed with level 9 for sake of safe shutdown.
# ---------------------------------------------------------------------
function wait_forpid() {
local PID=$1
[[ -z $PID ]] && return 1
local RC_PID=$(check_emurun)
local watchdog=0
while [[ -e /proc/$PID ]]; do
sleep 0.10
watchdog=$((watchdog+1))
[[ $watchdog -eq 30 ]] && [[ $RC_PID -gt 0 ]] && kill -9 $PID
[[ $watchdog -eq 50 ]] && [[ $RC_PID -gt 0 ]] && return
done
}

# This will reverse ${pidarray} and close all emulators.
# This function needs a valid pidarray.
# ------------------------------------------------------
function close_emulators() {
for ((z=${#pidarray[*]}-1; z>-1; z--)); do
kill ${pidarray[z]}
wait_forpid ${pidarray[z]}
done
unset pidarray
}

# Emulator currently running?
# If yes return PID from runcommand.sh
# -------------------------------------
function check_emurun() {
local RC_PID="$(pgrep -f -n runcommand.sh)"
echo $RC_PID
}

# Emulationstation currently running?
# If yes return PID from ES binary
# -----------------------------------
function check_esrun() {
local ES_PID="$(pgrep -f "/opt/retropie/supplementary/.*/emulationstation([^.]|$)")"
echo $ES_PID
}

# A Logo!
# ------------------------------------------------------
function shutdownlogo() {
clear
echo > /dev/tty1
echo '  ███████╗██╗  ██╗██╗   ██╗████████╗  ' > /dev/tty1
echo '  ██╔════╝██║  ██║██║   ██║╚══██╔══╝  ' > /dev/tty1
echo '  ███████╗███████║██║   ██║   ██║     ' > /dev/tty1
echo '  ╚════██║██╔══██║██║   ██║   ██║     ' > /dev/tty1
echo '  ███████║██║  ██║╚██████╔╝   ██║     ' > /dev/tty1
echo '  ╚══════╝╚═╝  ╚═╝ ╚═════╝    ╚═╝     ' > /dev/tty1
echo ' ██████╗  ██████╗ ██╗    ██╗███╗   ██╗' > /dev/tty1
echo ' ██╔══██╗██╔═══██╗██║    ██║████╗  ██║' > /dev/tty1
echo ' ██║  ██║██║   ██║██║ █╗ ██║██╔██╗ ██║' > /dev/tty1
echo ' ██║  ██║██║   ██║██║███╗██║██║╚██╗██║' > /dev/tty1
echo ' ██████╔╝╚██████╔╝╚███╔███╔╝██║ ╚████║' > /dev/tty1
echo ' ╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝' > /dev/tty1
}

# Important variables!
RC_PID=$(check_emurun)
ES_PID=$(check_esrun)

shutdownlogo

# Closes running Emulators/EmulationStation/Shuts Down.
# -------------------------
if [[ -n $RC_PID ]]; then
get_childpids $RC_PID
close_emulators
wait_forpid $RC_PID
shutdownlogo
echo > /dev/tty1
echo 'Closing emulators...' > /dev/tty1
if [ $? -eq 0 ]; then echo [OK] > /dev/tty1; else echo [FAIL] > /dev/tty1; fi
fi

# Initiate Shutdown and give control back to ES.
# If ES isn't running, just do a graceful shutdown!
# -------------------------------------------------
if [[ -n $ES_PID ]]; then
echo > /dev/tty1
echo 'Closing EmulationStation...' > /dev/tty1
touch /tmp/es-shutdown
chown pi:pi /tmp/es-shutdown
kill $ES_PID
if [ $? -eq 0 ]; then echo [OK] > /dev/tty1; else echo [FAIL] & sudo shutdown -h now > /dev/tty1; fi
echo > /dev/tty1
echo 'Shutting Down...' > /dev/tty1
else
echo > /dev/tty1
echo 'Shutting Down...' > /dev/tty1
sudo shutdown -h now
fi


