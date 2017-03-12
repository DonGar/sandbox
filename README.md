# sandbox

##What It Does

This project lets you quickly and easily switch to, and setup your bash
environment for many different software projects.

The environment for each project is called a sandbox.

##Setup

* Create a directory to hold your projects. By default ~/sand
* Create a directory for each project. The directory name is the sandbox name.
* Create a sandbox for this project.
```
cd ~/sand
git clone https://github.com/DonGar/sandbox.git
```
* Add this line as the final line in ~/.bashrc
```. "${HOME}/sand/sandbox/bashrc"```
* Start a new shell, and enter the sandbox for this project.
```g sandbox```

##Usage

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

####Alternative Usage

Setting SANDBOX to a valid sandbox name and starting bash is equivalent to "go
*sandbox*". This allows you do do things like:

```SANDBOX=name gnome-terminal```

##Customize a Sandbox with .sandbox

When a sandbox is entered, the file '.sandbox' in it's root directory will be
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

Since you exit the shell when you exit the sandbox, none of these changes will
stick around longer than needed.


##General Customization

Set these in your .bashrc before importing the sandbox/bashrc.

* SANDBOX_DIR: If set, this changes the sandbox root directory from the ~/sand
               default.
* sandbox_enter: This function or script is invoked (if it exists) when entering
                 any sandbox. This example makes bash history sandbox
                 specific, and preserves some of my special prompt formatting
                 inside sandboxes.

```
export HISTFILE="${HISTFILE}.${SANDBOX}"
export PS1="\[\e]0;\u@\h: \w\a\](\$SANDBOX)\$"
```

##Emacs

Emacs desktops save/restore the list of open files. Add this block to your
.emacs file do to this on a per-sandbox basis. Usually requires "M-x desktop-
save" once in each sandbox to start auto save/restore.

```
(setq desktop-dirname "~"
      desktop-base-file-name (concat ".emacs.desktop." (getenv "SANDBOX"))
      desktop-base-lock-name (concat desktop-base-file-name ".lock")
      desktop-load-locked-desktop nil
      desktop-save 'if-exists)
(desktop-save-mode 1)
```

##Sublime

This project adds a script into your path named "sublime". This starts the
sublime editor. If started inside a sandbox, it uses a project file specific to
that project. If no project file exists, it creates a minimal one.

Configuration:

* SUBLIME: Name of sublime executable. Only needed if it's not in your path.
           Default 'sublime_text'.

* SUBLIME_LIB_DIR: Directory in which to store project files for sandboxes.
                   Default ~/lib/sublime
