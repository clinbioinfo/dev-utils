import shutil
import sys
import os

infile = os.path.join(os.environ.get('HOME'), '.zshrc')
if not os.path.exists(infile):
  print(f"file '{infile}' does not exist")
  sys.exit(1)

bakfile = f"{infile }.bak"
print(f"Will attempt to move '{infile}' to '{bakfile}'")

os.rename(infile, bakfile)

of = open(infile, 'w')

print(f"Will attempt to update the plugins section in '{infile}'")

with open(bakfile, 'r') as f:
  for line in f:
    if line.startswith('plugins=(git)'):
      line = 'plugins=(git zsh-syntax-highlighting zsh-autosuggestions)'
    of.write(line)

of.close()

print(f"Please execute:\nsource {infile}")
