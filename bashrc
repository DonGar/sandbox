#!/bin/bash

# Helper function.
function _joinrel {
  local base="$1"
  local rel="$2"

  if [ -z "${rel}" ]; then
    echo "${base}"
  elif [[ "${rel}" == /* ]] ; then
    echo "${rel}"
  else
    echo "${base%/}/${rel}"
  fi
}

# Adjust path
export PATH="$PATH:$(dirname "${BASH_SOURCE}")/bin"

# Default deveopment root directory.  Override in bash setup to move.
export SANDBOXES_ROOT=${SANDBOXES_ROOT:-~/sand}

function g {
  # Try to enter a sandbox.
  if [ -z "${1}" ]; then
    echo 'Which sandbox do you want to enter?'
    return 1
  fi

  if [ ! -e "${SANDBOXES_ROOT}/${1}" ]; then
    echo "${SANDBOXES_ROOT}/${1} doesn't exist."
    return 1
  fi

  if [ ! -e "${SANDBOXES_ROOT}/${1}" ]; then
    echo "${SANDBOXES_ROOT}/${1} doesn't exist."
    return 1
  fi

  # Create a nested inner bash instance with SANDBOX set.
  SANDBOX=${1} bash
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

#
# Setup used inside a SANDBOX specific nested shell.
#
if [ -n "${SANDBOX}" -a -z "${SANDBOX_DIR}" ]; then

  function g {
    # If we are inside a sandbox, all we do is change directories.
    if [ -n "${1}" ]; then
      echo 'Exit current sandbox before entering a new one.'
      return 1
    fi

    # Toggle between default directory, and root directory of sandbox.
    if [ "${PWD}" = "${SANDBOX_DEFAULT}" ]; then
      cd "${SANDBOX_DIR}"
    else
      cd "${SANDBOX_DEFAULT}"
    fi
  }

  # SANDBOX_DIR is the root dir of the sandbox.
  # SANDBOX_DEFAULT is the default directory to jump to in sandbox.
  export SANDBOX_DIR="${SANDBOXES_ROOT}/${SANDBOX}"
  export SANDBOX_DEFAULT="${SANDBOX_DIR}"

  export PS1="($SANDBOX)\$"

  if type "sandbox_enter" >& /dev/null; then
    sandbox_enter
  fi

  if [ -e "${SANDBOX_DIR}/.sandbox" ]; then
    . "${SANDBOX_DIR}/.sandbox"
    # If .sandbox changes SANDBOX_DEFAULT, make sure its absolute.
    export SANDBOX_DEFAULT="$(_joinrel "${SANDBOX_DIR}" "${SANDBOX_DEFAULT}")"
  fi

  # Start in the default directory.
  cd "${SANDBOX_DEFAULT}"
fi
