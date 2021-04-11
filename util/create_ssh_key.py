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

DEFAULT_LOGGING_FORMAT = "%(levelname)s : %(asctime)s : %(pathname)s : %(lineno)d : %(message)s"

DEFAULT_LOG_LEVEL = logging.INFO

DEFAULT_VERBOSE = True

DEFAULT_GITHUB_SETTINGS_KEY_URL = 'https://github.com/settings/keys'


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
@click.option('--email_address', help="The email address to associate with the account")
@click.option('--logfile', help="The log file")
@click.option('--name', help="The first and last name to associate with the account - default is environemnt variable GIT_CONFIG_NAME")
@click.option('--outdir', help="The default is the current working directory - default is '{DEFAULT_OUTDIR}'")
@click.option('--verbose', is_flag=True, help=f"Will print more info to STDOUT - default is '{DEFAULT_VERBOSE}'")
def main(email_address: str, logfile: str, name: str, outdir: str, verbose: bool):
    """Create ssh key by executing ssh-keygen"""

    print(pyfiglet.figlet_format("SSH Keygen"))

    error_ctr = 0

    if email_address is None:
        print_red(f"--email_address was not specified")
        error_ctr += 1

    if name is None:
        name = os.getenv('GIT_CONFIG_NAME', None)
        if name is None:
            print_red(f"--name was not specified and environment variable GIT_CONFIG_NAME was not defined")
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

    if logfile is None:
        logfile = outdir + '/' + os.path.basename(__file__) + '.log'
        print_yellow(f"--logfile was not specified and therefore was set to '{logfile}'")

    assert isinstance(logfile, str)

    logging.basicConfig(filename=logfile, format=DEFAULT_LOGGING_FORMAT, level=DEFAULT_LOG_LEVEL)

    basename = email_address
    basename = basename.split('@')[0].replace('.', '_')
    privatekey_filepath = os.path.join(os.getenv('HOME'), '.ssh', 'id_ed25519_' + basename)

    cmd = f"ssh-keygen -t ed25519 -C '{email_address}' -f {privatekey_filepath}"
    print(cmd)
    _execute_cmd(cmd)

    pubkey_filepath = privatekey_filepath + '.pub'
    if not os.path.exists(pubkey_filepath):
        error_msg = f"file '{pubkey_filepath}' does not exist"
        logging.error(error_msg)
        raise Exception(error_msg)
    logging.info(f"Will read file '{pubkey_filepath}'")

    print(f"Please add the new key to your Github account at '{DEFAULT_GITHUB_SETTINGS_KEY_URL}':")
    with open(pubkey_filepath, 'r') as f:
        for line in f:
            line = line.strip()
            print(line)


if __name__ == "__main__":
    main()
