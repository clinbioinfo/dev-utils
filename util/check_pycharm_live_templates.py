import filecmp
import os
import sys
import click
import json
import logging
import calendar
import time
import pathlib

from colorama import Fore, Style
from datetime import datetime

DEFAULT_TEMPLATE_FILE = os.path.join(os.getenv('HOME'), 'dev-utils', 'ide', 'pycharm', 'sundaram_pycharm_live_snippets.xml')
DEFAULT_INSTALLED_TEMPLATE_FILE = os.path.join(os.getenv('HOME'), '.config', 'JetBrains', 'PyCharmCE2021.1', 'templates', 'sundaram_pycharm_live_snippets.xml')
DEFAULT_OUTDIR = os.path.join("/tmp/", os.path.basename(__file__), str(datetime.today().strftime('%Y-%m-%d-%H%M%S')))

DEFAULT_VERBOSE = True


def write_lines_to_file(lines: list, outdir: str, infile: str) -> None:
    outfile = os.path.join(outdir, os.path.basename(infile))
    with open(outfile, 'w') as of:
        for line in lines:
            of.write(f"{line}\n")

    print(f"Wrote file '{outfile}'")


def get_lines_from_file(infile: str) -> list:
    line_ctr = 0
    content = []
    with open(infile, 'r') as f:
        for line in f:
            line_ctr += 1
            line = line.strip().replace('&quot;', '"')
            lines = line.split('&#10;')
            for l in lines:
                content.append(l)

    return content


def print_red(msg: str = None) -> None:
    """Print message to STDOUT in yellow text.
    :param msg: {str} - the message to be printed
    """
    if msg is None:
        raise Exception("msg was not defined")

    print(Fore.RED + msg)
    print(Style.RESET_ALL + "", end="")


def print_green(msg: str = None) -> None:
    """Print message to STDOUT in yellow text.
    :param msg: {str} - the message to be printed
    """
    if msg is None:
        raise Exception("msg was not defined")

    print(Fore.GREEN + msg)
    print(Style.RESET_ALL + "", end="")


def print_yellow(msg: str = None) -> None:
    """Print message to STDOUT in yellow text.
    :param msg: {str} - the message to be printed
    """
    if msg is None:
        raise Exception("msg was not defined")

    print(Fore.YELLOW + msg)
    print(Style.RESET_ALL + "", end="")


@click.command()
@click.option('--template_file', type=click.Path(exists=True), help=f"The Pycharm Live Template file in the local check out - default is '{DEFAULT_TEMPLATE_FILE}'")
@click.option('--installed_template_file', type=click.Path(exists=True), help=f"The installed Pycharm Live Template file - default is '{DEFAULT_INSTALLED_TEMPLATE_FILE}'")
def main(template_file: str, installed_template_file: str):
    """Check whether the installed Pycharm Live Template file is different from the one in the local checkout."""

    error_ctr = 0

    if template_file is None:
        template_file = DEFAULT_TEMPLATE_FILE
        print_yellow(f"--template_file was not specified and therefore was set to default '{template_file}'")

    if installed_template_file is None:
        installed_template_file = DEFAULT_INSTALLED_TEMPLATE_FILE
        print_yellow(f"--installed_template_file was not specified and therefore was set to default '{installed_template_file}'")

    if not os.path.exists(template_file):
        print_red(f"template file '{template_file}' does not exist")
        error_ctr += 1

    if not os.path.exists(installed_template_file):
        print_red(f"template file '{installed_template_file}' does not exist")
        error_ctr += 1

    if error_ctr > 0:
        sys.exit(1)

    if not filecmp.cmp(template_file, installed_template_file):
        print(f"The files are different")
        print("Try the following:")
        print(f"diff {template_file} {installed_template_file} | wc -l")
        print(f"diff {template_file} {installed_template_file} | less")
        print(f"cp {template_file} {installed_template_file}")
        print(f"cp {installed_template_file} {template_file}")
    else:
        print("The files have the same content")


if __name__ == "__main__":
    main()
