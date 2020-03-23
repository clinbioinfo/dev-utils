import csv
import os
import sys
import click
import pathlib
import json
import logging
import calendar
import time
from colorama import Fore, Style
from datetime import datetime

today = str(datetime.today().strftime('%Y-%m-%d'))

DEFAULT_BITBUCKET_CONFIG_FILE = os.environ.get('HOME') + '/.config/my_bitbucket/git_clone_lookup.txt'

DEFAULT_OUTDIR = "/tmp/" + os.path.basename(__file__) + '/' + str(datetime.today().strftime('%Y-%m-%d-%H%M%S'))

LOGGING_FORMAT = "%(levelname)s : %(asctime)s : %(pathname)s : %(lineno)d : %(message)s"

LOG_LEVEL = logging.INFO


def get_git_lookup(infile):
    """Parse the bitbucket lookup file
    :param infile: {str} file containing the listing of the Bitbucket repo
    :return git_lookup: {dict} 
    """
    lookup = {}

    with open(infile) as f:
        row_ctr = 0
        for line in f:
            parts = line.split()
            row_ctr += 1
            lookup[parts[0]] = parts[1]

        logging.info("Processed '{}' records in tab-delimited file '{}'".format(row_ctr, infile))

    return lookup


@click.command()
@click.option('--git_lookup_file', help="The default is '{}'".format(DEFAULT_BITBUCKET_CONFIG_FILE))
@click.option('--logfile', help="The log file")
@click.option('--code_base', help="The code-base")
@click.option('--version', help="The version")
@click.option('--jira_issue', help="The JIRA issue identifier")
@click.option('--outdir', help="The output directory")
def main(git_lookup_file, logfile, code_base, version, jira_issue, outdir):
    """Generate the release steps
    """

    error_ctr = 0

    if jira_issue is None:
        print(Fore.RED + "--jira_issue was not specified")
        print(Style.RESET_ALL + '', end='')
        error_ctr += 1

    if error_ctr > 0:
        sys.exit(1)
    
    assert isinstance(jira_issue, str)

    if git_lookup_file is None:
        git_lookup_file = DEFAULT_BITBUCKET_CONFIG_FILE
        print(Fore.YELLOW + "--git_lookup_file was not specified and therefore was set to default '{}'".format(git_lookup_file))
        print(Style.RESET_ALL + '', end='')

    if not os.path.exists(git_lookup_file):
        print(Fore.RED + "git_lookup_file '{}' does not exist".format(git_lookup_file))
        print(Style.RESET_ALL + '', end='')
        sys.exit(1)

    if outdir is None:
        outdir = '/tmp/jira/' + jira_issue
        print(Fore.YELLOW + "--outdir was not specified and therefore was set to '{}'".format(outdir))
        print(Style.RESET_ALL + '', end='')

    assert isinstance(outdir, str)

    if not os.path.exists(outdir):
        pathlib.Path(outdir).mkdir(parents=True, exist_ok=True)
        print(Fore.YELLOW + "Created output directory '{}'".format(outdir))
        print(Style.RESET_ALL + '', end='')

    if logfile is None:
        logfile = outdir + '/' + os.path.basename(__file__) + '.log'
        print(Fore.YELLOW + "--logfile was not specified and therefore was set to '{}'".format(logfile))
        print(Style.RESET_ALL + '', end='')

    assert isinstance(logfile, str)

    logging.basicConfig(filename=logfile, format=LOGGING_FORMAT, level=LOG_LEVEL)

    git_lookup = get_git_lookup(git_lookup_file)
    number_to_code_base_lookup = {}
    number = 0

    if code_base is None or code_base == '' or code_base not in git_lookup:
        for code_base in git_lookup:
            number += 1
            print("{}. {}".format(number, code_base))
            number_to_code_base_lookup[str(number)] = code_base

        selection = input("Please choose the code-base: ")
        selection = selection.strip()
        if selection not in number_to_code_base_lookup:
            raise Exception("Invalid select: '{}'".format(selection))

        code_base = number_to_code_base_lookup[selection]

    if version is None or version == '':
        version = input("Please specify the software version: ")
        version = version.strip()
        if version is None or version == '':
            raise Exception("Invalid version '{}'".format(version))

    repo = git_lookup[code_base]

    logging.info("The code-base is '{}'".format(code_base))
    logging.info("The software version is '{}'".format(version))
    logging.info("The repository is '{}'".format(repo))

    print("\nExecute the following steps:\n\n")
    print("mkdir -p {}".format(outdir))
    print("cd {}".format(outdir))
    print("git clone {}".format(repo))
    print("cd {}".format(code_base))
    print("git merge origin/release/{}".format(version))
    print("git checkout devel")
    print("git merge origin/release/{}".format(version))
    print("git checkout master")
    print("git push")
    print("git tag -a {} -m 'Establishing {} annotated tag on {}.  Reference: {}'".format(version, version, today, jira_issue))
    print("git push origin {}".format(version))


if __name__ == "__main__":
    main()