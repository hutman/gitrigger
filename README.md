gitrigger
=========

A simple plugin to update git repositories and pull changes into redmine - borrowing heavily from http://mentalized.net/journal/2009/08/03/redmine_plugin_github_hook/

This assumes that your git repos are stored on a server with SSH access. It will work for github as well if you just set up an ssh key for the redmine server account on your machine. 

Setup Instructions: 

1. set up shared ssh key for the site. This allows your redmine server to pull from

    ssh-copy-id username@server

2. clone with --mirror (read only full mirror will grab tags and all branches)

    git clone --mirror ssh://user@server/path/to/project-name.git project-name.git

3. set up your repository in redmine - in the project settings add your repository

4. add a line to your post-receive hook to auto-update redmine with each commit

    wget --no-check-certificate https://your-redmine-server/trigger/project-name -o /dev/null
