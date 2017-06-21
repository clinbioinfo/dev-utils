# Synopsis

This project contains convenience scripts and programs for software developers/engineers.

# Motivation

Many software development/engineering actions and activities are repetitive.
The scripts and programs are aimed at reducing repetition and increasing automation. 

# Assets

#### util/aliases_checker.pl 

* Checks which aliases exist in the ~/aliases.txt file and compares against contents of the one in doc/aliases.txt
* Prompts user whether should transfer/install new aliases

#### util/apache_error_log_analyzer.pl

* Parses the Apache HTTP Server error log file and displays all entries corresponding with the most recent activity

#### util/delete_files.pl

* Reads a simple text file containing a list of files and deletes those files (be mindful of relative paths)

#### util/end_of_day.pl

* Program for executing housekeeping activities/actions at end-of-business day

#### util/git_checkout.pl

* Interactive program for cloning git projects

#### util/git_commit_and_update_jira.pl

* Interactive program for committing staged, unstaged, untracked assets; pushing to origin and adding corresponding comment to a JIRA issue

#### util/git_commit.pl

* Interactive program for committing staged, unstaged, untracked assets; pushing to origin 

#### util/git_create_next_build_tag.pl

* Interactive program for establishing a new build tag (format: v1.1.3 where 3 is the next build were the previous had been 2) for a git project

#### util/git_determine_commit_hash_url.pl

* Convenience program for determining the full hash key and the corresponding Git Stash URL

#### util/git_determine_current_branches.pl

* Interactive program for determining the remote development branches 

#### util/git_determine_current_tags.pl

* Interactive program for determining the remote tags/builds 

#### util/git_determine_next_build_tag.pl

* Interactive program for determining/recommending the next tag/build

#### util/git_determine_next_dev_branch.pl

* Interactive program for determining/recommending the next development branch 

#### util/git_project_archiver.pl

* Interactive program for archiving (tar -zcvf) a git project (local cloned project)
* Will determine and report whether there are uncommitted assets (staged, not staged, not tracked)

#### util/git_project_remover.pl

* Interactive program for deleting a git project (local cloned project)
* Will determine and report whether there are uncommitted assets (staged, not staged, not tracked)

#### util/git_projects_inspector.pl

* Interactive program for scanning all git projects under the ~/projects directory
* Will determine and report whether there are uncommitted assets (staged, not staged, not tracked)
* Will prompt user whether should delete directories that are empty or do not have any uncommitted assets

#### util/logfile_viewer.pl

* Program for parsing a Log4perl log file

#### util/perl_compare_module_files.pl

* Script for comparing the contents of modules that have the same namespace but exist in two different directories

#### util/perl_module_syntax_checker.pl

*

#### util/perl_module_users.pl

*

#### util/project_archive_stasher.pl

*

#### util/scp_assets_by_list_file.pl

*

#### util/scp_assets.pl

* Interactive program for secure copying files to remote machine

#### util/selenium_remote_webdriver_installer.pl

* Script for installing Selenium Remote Webdriver and dependencies on Ubuntu (tested on 16.10)

#### util/ssh_util.pl

* Interactive program for ssh-related actions

#### util/sublime_snippets_checker.pl

* Program for determining whether new Sublime snippets exist in ~/.config/sublime/Packages/User
* Copies new snippets to sublime-snippets/snippets and advises user to commit to this Git repository

#### util/sublime_snippets_installer.pl

* Program for copying snippet files from this Git repository to the ~/.config/sublime/Packages/User directory

#### util/webapp_install_checker.pl

*

#### util/webapp_last_session_instance_analyzer.pl


*

# License

MIT