#!/bin/bash

# Default deveopment root directory.  Override in bash setup to move.
export SANDBOXES_ROOT=${SANDBOXES_ROOT:-~/sand}

# Add sandbox/bin to end of path.
export PATH="$PATH:$(dirname "${BASH_SOURCE}")/bin"

function _joinrel {
    local base="$1"
    local rel="$2"

    if [[ "${rel}" == /* ]] ; then
	echo "${rel}"
    else
	echo "${base%/}/${rel}"
    fi
}

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

    # If .sandbox defines SANDBOX_DEFAULT as a relative path, make it absolute.
    export SANDBOX_DEFAULT="$(_joinrel "${SANDBOX_DIR}" "${SANDBOX_DEFAULT}")"
  fi

  # If we still don't have a sandbox, error out.
  if [ -z "${SANDBOX_DIR}" ]; then
    return 1
  fi

  # We get here after entering a sandbox, or on a bare 'g'.

  # Toggle between default directory, and root directory of sandbox.
  if [ "${PWD}" = "${SANDBOX_DEFAULT}" ]; then
    cd "${SANDBOX_DIR}"
  else
    cd "${SANDBOX_DEFAULT}"
  fi
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
