# sandbox

## What It Does

This project lets you quickly and easily switch to, and setup your bash
environment for many different software projects.

The environment for each project is called a sandbox.

## Setup

* Create a directory to hold your projects. By default ~/sand
* Create a directory for each project. The directory name is the sandbox name.
* Create a sandbox for this project.
```
cd ~/sand
git clone https://github.com/DonGar/sandbox.git
```
* Add this line as the final line in ~/.bashrc
```
. "${HOME}/sand/sandbox/bashrc"
```
* Start a new shell, and enter the sandbox for this project.
```
g sandbox
```

## Usage

* g *tab* will autocomplete against all valid sandbox names.
* g *sandbox_name* will switch to that project.
  * This starts a new bash shell 'inside' that sandbox.
  * The following variables are set, and can be used by scripts, prompts, etc.
    * SANDBOX: The name of the sandbox.
    * SANDBOX_DIR: The root directory of the sandbox.
    * SANDBOX_DEFAULT: The 'preferred' subdirectory of the sandbox (more below).
  * While inside the sandbox 'g' will cd to SANDBOX_DIR or SANDBOX_DEFAULT
    alternatively.
  * Exiting the shell ('exit' or Ctrl-D) will exit the shell, restoring your
    starting environment.

* g *sandbox_name* *command* [*args*...] runs a single command inside that
  sandbox, then exits. The sandbox is set up exactly as it would be for an
  interactive shell (.sandbox, venv, sandbox_enter), and the command starts in
  SANDBOX_DEFAULT. The exit status is the command's.
  * Example: ```g ansible ls -l```
  * Arguments are passed through exactly, so for pipes or multiple commands
    use: ```g ansible bash -c 'make && ls'```
  * This only works from outside a sandbox.

#### Alternative Usage

Setting SANDBOX to a valid sandbox name and starting bash is equivalent to "g
*sandbox*". This allows you to do things like:

```
SANDBOX=name gnome-terminal
```

## Customize a Sandbox with .sandbox

When a sandbox is entered, the file '.sandbox' in its root directory will be
sourced (if present).

Example .sandbox:

```
export GOPATH="${SANDBOX_DIR}"
export SANDBOX_DEFAULT="src/github.com/DonGar/go-timeglob"
```

This sets up the GOPATH environmental variable needed for this Go project, and
changes the initial directory to be the one I'm usually interested in for the
project.

.sandbox can also be used for things like activating python virtualenvs.

## Automatic Behavior

* Python: If there is no .sandbox file, and the sandbox contains
  venv/bin/activate, that virtualenv is activated automatically.
* History: Bash history is kept per sandbox, in SANDBOX_DIR/.bash_history.
  You may want to add .bash_history to the project's .gitignore.

Since you exit the shell when you exit the sandbox, none of these changes will
stick around longer than needed.


## General Customization

Set these in your .bashrc before importing the sandbox/bashrc.

* SANDBOXES_ROOT: If set, this changes the directory holding all sandboxes
                  from the ~/sand default. (Don't set SANDBOX_DIR yourself; it
                  is set automatically inside a sandbox.)
* sandbox_enter: This function or script is invoked (if it exists) when entering
                 any sandbox. This example preserves some of my special prompt
                 formatting inside sandboxes.

```
export PS1="\[\e]0;\u@\h: \w\a\](\$SANDBOX)\$"
```

## Emacs

Emacs desktops save/restore the list of open files. Add this block to your
.emacs file to do this on a per-sandbox basis. Usually requires "M-x desktop-
save" once in each sandbox to start auto save/restore.

```
(setq desktop-dirname "~"
      desktop-base-file-name (concat ".emacs.desktop." (getenv "SANDBOX"))
      desktop-base-lock-name (concat desktop-base-file-name ".lock")
      desktop-load-locked-desktop nil
      desktop-save 'if-exists)
(desktop-save-mode 1)
```
