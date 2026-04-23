---
name: brasil-time-tracker
description: These are the rules for tracking work time in Brazil that should be used in the morning start and end of the day routines.
license: GPL-3.0-or-later
metadata:
    author: The Gambiarra Team
    version: "1.1"
---

## Brazilian Labor Law Compliance

The brasil-time-tracker skill enforces:
- Time registration in Kairos system
- 1-hour lunch break reminder between 11:30h-14:00h
- 8-hour work day reminder
- Start and end of day time tracking

## Configuration

Configuration is found in the skill file `${HOME}/.brasil-kairos.conf`, or `${HOME}/.config/brasil-kairos.conf`, or on the fiel `${PWD}/.env`.

If none of the configuration files exist, create the file as a script to be sourced by other bash scripts with the variables:
  - KAIROS_USER: the kairos username, which always ends with `@redhat.com`. (can be defined from engineers's configuration data)
  - KAIROS_LOGDIR: the directory to store the script logs
  - KARIOS_PDFDIR: the directory to store the PDF tickets provided by Kairos, if this variable is empty, the tickets will not be stored locally.

Ask the engineer for the values of the variables before creating the file. **Never** assume any default value.

## Starting the day

When starting the day, after greetings like with "good morning" or "let's start", **ALWAYS** follow these steps:

1. Ask if the engineer wants you to:
    1. Register start time in Kairos
    2. Register start and end of day time in Kairos
    3. Skip this step and/or register time manually in Kairos
2. If answer is (1), run the script `${CLAUDE_PLUGIN_ROOT}/scripts/ponto.sh`
3. If answer is (2), run the script `${CLAUDE_PLUGIN_ROOT}/scripts/bate_ponto.sh`
4. Otherwise, simple remingd the engineer to register his working time in Kairos at "https://dimepkairos.com.br"

## End of the day

When engineer is ready to finish the day, with a "good night" or "let's wrap my day", **ALWAYS** follow these steps when the engineer finishes the day:
1. Verify if the last two entries in the file `${KAIRO_LOGDIR}/kairos.log` are for the current day, if so, the last entry is the end of the day time.
    - There's one timestamp per line, and the timestamp format is `YYYY-mm-dd_HHMM`.
2. If there's one single entry for the current day, check for the time the register script (`ponto.sh`) was scheduled for execution by using the command `atq`. The end of the day time is the time scheduled for the script to run.
3. If there's a end of the day time, report it for the engineer, and the source of it.
4. If there's no end of the day time, ask if the engineer wants you to register end of day time in Kairos.
5. If engineer says, yes, run the script `${CLAUDE_PLUGIN_ROOT}/scripts/ponto.sh`.
6. **Always** remind engineer that he can register his working time at "https://dimepkairos.com.br"

## Lunch break

If engineer makes any request between 12:00h and 14:00h **always remind the engineer once** that a one hour lunch break is required by law, good for his health, and prevents burnout.

## Ressetting password

If engineer wants to reset Kairos password, run the script `${CLAUDE_PLUGIN_ROOT}/scripts/ponto.sh` with the firts argument being `-p`.

## Checking dependencies

To check if all dependencies are met, run `${CLAUDE_PLUGIN_ROOT}/scripts/ponto.sh -d`.
For the script `${CLAUDE_PLUGIN_ROOT}/scripts/bate_ponto.sh`, there's additionally the dependency on commands `at` and `python3`.
Ensure that dependencies are met before using the scripts to track working time.
