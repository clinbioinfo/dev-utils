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
@click.option('--verbose', is_flag=True, help=f"Will print more info to STDOUT - default is '{DEFAULT_VERBOSE}'")
@click.option('--outdir', help="The default is the current working directory - default is '{DEFAULT_OUTDIR}'")
@click.option('--file1', type=click.Path(exists=True), help=f"The first file")
@click.option('--file2', type=click.Path(exists=True), help=f"The second file")
@click.option('--outfile', help="The output final report file")
def main(verbose: bool, outdir: str, file1: str, file2: str, outfile: str):
    """Template command-line executable."""

    error_ctr = 0

    if file1 is None:
        print_red("--file1 was not specified")
        error_ctr += 1

    if file2 is None:
        print_red("--file2 was not specified")
        error_ctr += 1

    if error_ctr > 0:
        sys.exit(1)

    if outdir is None:
        outdir = DEFAULT_OUTDIR
        print_yellow(f"--outdir was not specified and therefore was set to '{outdir}'")

    assert isinstance(outdir, str)

    if not os.path.exists(outdir):
        pathlib.Path(outdir).mkdir(parents=True, exist_ok=True)

        print_yellow(f"Created output directory '{outdir}'")

    if not os.path.isfile(file1):
        print(f"'{file1}' is not a file")
        logging.error(f"'{file1}' is not a file")
        sys.exit(1)

    if not os.path.isfile(file2):
        print(f"'{file2}' is not a file")
        logging.error(f"'{file2}' is not a file")
        sys.exit(1)

    lines1 = get_lines_from_file(file1)
    write_lines_to_file(lines1, outdir, file1)

    lines2 = get_lines_from_file(file2)
    write_lines_to_file(lines2, outdir, file2)


if __name__ == "__main__":
    main()
