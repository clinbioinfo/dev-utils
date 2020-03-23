#!/usr/bin/env bash
DIRNAME=$(dirname "$0")
source $DIRNAME/venv/bin/activate
python $DIRNAME/prepare_release_steps.py "$@"
