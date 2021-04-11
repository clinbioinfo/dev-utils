import click
import logging
import os
import pathlib
import pyfiglet
import subprocess
import sys

from colorama import Fore, Style
from datetime import datetime

DEFAULT_OUTDIR = os.path.join(
    "/tmp",
    os.path.splitext(os.path.basename(__file__))[0],
    str(datetime.today().strftime("%Y-%m-%d-%H%M%S")),
)

LOGGING_FORMAT = "%(levelname)s : %(asctime)s : %(pathname)s : %(lineno)d : %(message)s"

LOG_LEVEL = logging.INFO

DEFAULT_VERBOSE = True


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


def _execute_cmd(cmd, outdir: str = DEFAULT_OUTDIR, stdout_file=None, stderr_file=None):
    """Execute a command via system call using the subprocess module
    :param cmd: {str} - the executable to be invoked
    :param outdir: {str} - the output directory where STDOUT, STDERR and the shell script should be written to
    :param stdout_file: {str} - the file to which STDOUT will be captured in
    :param stderr_file: {str} - the file to which STDERR will be captured in
    """
    if cmd is None:
        raise Exception("cmd was not specified")

    logging.info(f"Will attempt to execute '{cmd}'")

    if outdir is None:
        outdir = '/tmp'
        logging.info(f"outdir was not defined and therefore was set to default '{outdir}'")

    if stdout_file is None:
        stdout_file = os.path.join(outdir, os.path.basename(__file__) + '.stdout')
        logging.info(f"stdout_file was not specified and therefore was set to '{stdout_file}'")

    if stderr_file is None:
        stderr_file = os.path.join(outdir, os.path.basename(__file__) + '.stderr')
        logging.info(f"stderr_file was not specified and therefore was set to '{stderr_file}'")

    if os.path.exists(stdout_file):
        logging.info(f"STDOUT file '{stdout_file}' already exists so will delete it now")
        os.remove(stdout_file)

    if os.path.exists(stderr_file):
        logging.info(f"STDERR file '{stderr_file}' already exists so will delete it now")
        os.remove(stderr_file)

    p = subprocess.Popen(cmd, shell=True)

    (stdout, stderr) = p.communicate()

    pid = p.pid

    logging.info(f"The child process ID is '{pid}'")

    p_status = p.wait()

    p_returncode = p.returncode

    if p_returncode is not None:
        logging.info(f"The return code was '{p_returncode}'")
    else:
        logging.info("There was no return code")

    if p_status == 0:
        logging.info(f"Execution of cmd '{cmd}' has completed")
    else:
        raise Exception(f"Received status '{p_status}'")

    if stdout is not None:
        logging.info("stdout is: " + stdout)

    if stderr is not None:
        logging.info("stderr is: " + stderr)

    return stdout_file


@click.command()
@click.option('--logfile', help="The log file")
@click.option('--outdir', help="The default is the current working directory - default is '{DEFAULT_OUTDIR}'")
@click.option('--verbose', is_flag=True, help=f"Will print more info to STDOUT - default is '{DEFAULT_VERBOSE}'")
def main(logfile: str, outdir: str, verbose: bool):
    """Run Start of Day scripts"""

    print(pyfiglet.figlet_format("Start of Day"))

    error_ctr = 0

    if error_ctr > 0:
        sys.exit(1)

    if outdir is None:
        outdir = DEFAULT_OUTDIR
        print_yellow(f"--outdir was not specified and therefore was set to '{outdir}'")

    assert isinstance(outdir, str)

    if not os.path.exists(outdir):
        pathlib.Path(outdir).mkdir(parents=True, exist_ok=True)

        print_yellow(f"Created output directory '{outdir}'")

    if logfile is None:
        logfile = outdir + '/' + os.path.basename(__file__) + '.log'
        print_yellow(f"--logfile was not specified and therefore was set to '{logfile}'")

    assert isinstance(logfile, str)

    logging.basicConfig(filename=logfile, format=LOGGING_FORMAT, level=LOG_LEVEL)

    cmd = f"bash {os.path.join(os.getenv('HOME'), 'pycharm-utils', 'util', 'install_pycharm_live_template.sh')}"
    print(f"\n\nNow attempting to execute {cmd}")
    _execute_cmd(cmd)
    print("Have a great day!!")
    

if __name__ == "__main__":
    main()
