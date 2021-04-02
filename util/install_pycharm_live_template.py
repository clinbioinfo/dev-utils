import os
import shutil

dev_utils_dir = os.path.join(os.getenv('HOME'), 'dev-utils')
dev_utils_template_file = os.path.join(dev_utils_dir, 'ide', 'pycharm', 'sundaram_pycharm_live_snippets.xml')
if not os.path.exists(dev_utils_template_file):
    raise Exception(f"'{dev_utils_template_file}' does not exist")


pycharm_templates_dir = os.path.join(os.getenv('HOME'), '.config', 'JetBrains', 'PyCharmCE2020.3', 'templates')
if not os.path.exists(pycharm_templates_dir):
    raise Exception(f"'{pycharm_templates_dir}' does not exist")

pycharm_template_file = os.path.join(pycharm_templates_dir, os.path.basename(dev_utils_template_file))
if os.path.exists(pycharm_template_file):
    bakfile = f"{pycharm_template_file}.bak"
    shutil.copy(pycharm_template_file, bakfile)
    print(f"Backed up '{pycharm_template_file}' to '{bakfile}'")

shutil.copy(dev_utils_template_file, pycharm_template_file)
print(f"Copied '{dev_utils_template_file}' to '{pycharm_template_file}'")
print("Restart Pycharm to refresh the Live Templates!")
print(f"Remember: if you develop any new Live Templates- be sure to copy the template file back to '{dev_utils_template_file}' and then git add and git commit")
print("Enjoy!")


