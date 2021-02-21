import os
import sys

DEFAULT_OUTFILE = os.path.join('/tmp', os.path.basename(__file__) + '.sh')
outfile = None
infile = sys.argv[1]

if len(sys.argv) == 3:
    outfile = sys.argv[2]

if infile is None:
    print("Usage: python __file__ [input text file with commands] [output bash shell script file]")
    sys.exit(1)

if not os.path.exists(infile):
    raise Exception(f"File '{infile}' does not exist")

if outfile is None:
    basename = os.path.basename(infile)
    if basename.endswith('.txt'):
        basename = basename.replace('.txt', '')
    outfile = os.path.join('/tmp', basename + '.sh')
    print(f"outfile was not specified and therefore was set to '{outfile}'")

with open(outfile, 'wt') as of:
    of.write("#!/bin/sh\n\n")
    with open(infile, 'r') as f:
        for line in f:
            line = line.strip()
            if 'reference' in line.lower():
                of.write(f"{line}\n")
            else:
                of.write(f'echo "Will attempt to execute: {line}"\n')
                of.write(f"{line}\n\n")

    print(f"Wrote shell script '{outfile}'")