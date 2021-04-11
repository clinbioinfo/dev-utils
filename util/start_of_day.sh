#!/usr/bin/env bash
DIRNAME=$(dirname "$0")
. ${DIRNAME}/../venv/bin/activate
python ${DIRNAME}/start_of_day.py
