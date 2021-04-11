#!/usr/bin/env bash
DIRNAME=$(dirname "$0")
. ${DIRNAME}/../venv/bin/activate
python ${DIRNAME}/create_ssh_key.py "$@"
