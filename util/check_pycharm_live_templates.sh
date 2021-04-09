#!/usr/bin/env bash
DIRNAME=$(dirname "$0")
. ${DIRNAME}/../venv/bin/activate
python ${DIRNAME}/check_pycharm_live_templates.py
