#!/bin/bash

ponto.sh
count=$[60*9 + 1 + RANDOM % 10]
# echo "Sleeping '${count}' minutes."
at -M -f "${HOME}/Applications/ponto.sh" "now + ${count} minutes" 2>/dev/null
python3 <<< "from datetime import datetime, timedelta; print(f'Ponto será batido as {(datetime.now() + timedelta(minutes=${count})).strftime(\"%H:%M\")}h')"
