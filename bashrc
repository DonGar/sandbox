#!/bin/bash

# Default deveopment root directory.  Override in bash setup to move.
export SANDBOXES_ROOT=${SANDBOXES_ROOT:-~/sand}

# Add sandbox/bin to end of path.
export PATH="$PATH:$(dirname "${BASH_SOURCE}")/bin"

function g {

  # If a new sandbox was specified, set up the environment.
  if [ -n "${1}" ]; then

    if [ ! -e "${SANDBOXES_ROOT}/${1}" ]; then
      echo "${SANDBOXES_ROOT}/${1} doesn't exist."
      return 1
    fi

    # SANDBOX is a unique ID for the sandbox.
    # SANDBOX_DIR is the root dir of the sandbox.
    # SANDBOX_DEFAULT is the default directory to jump to in sandbox.
    export SANDBOX=${1}
    export SANDBOX_DIR="${SANDBOXES_ROOT}/${1}"
    export SANDBOX_DEFAULT="${SANDBOX_DIR}"

    if [ -e "${SANDBOX_DIR}/.sandbox" ]; then
      . "${SANDBOX_DIR}/.sandbox"
    fi
  fi

  # If we still don't have a sandbox, error out.
  if [ -z "${SANDBOX_DIR}" ]; then
    return 1
  fi

  #
  cd "${SANDBOX_DIR}"
  cd "${SANDBOX_DEFAULT}"
}

_g()
{
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts=`ls "${SANDBOXES_ROOT}"`

  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
  return 0
}

# Setup command line completion for g
complete -F _g g
