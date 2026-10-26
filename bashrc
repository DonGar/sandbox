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

# Default development root directory.  Override in bash setup to move.
export SANDBOXES_ROOT=${SANDBOXES_ROOT:-~/sand}

function sandbox_exists {
  [[ -n "${1}" && -d "${SANDBOXES_ROOT}/${1}" ]]
}

function g {
  # Try to enter a sandbox.
  if [ -z "${1}" ]; then
    echo 'Which sandbox do you want to enter?'
    return 1
  fi

  if ! sandbox_exists "${1}"; then
    echo "${SANDBOXES_ROOT}/${1} doesn't exist."
    return 1
  fi

  local name="${1}"
  shift

  if [ $# -eq 0 ]; then
    # Create a nested inner bash instance with SANDBOX set.
    SANDBOX="${name}" bash
  else
    # Run one command inside the sandbox, then exit with its status.
    # -i makes bash read ~/.bashrc, which sets up the sandbox. Arguments
    # are re-quoted so they reach the command exactly as given.
    SANDBOX="${name}" bash -ic "$(printf '%q ' "$@")"
  fi
}

_g()
{
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local dir
  local opts=()

  # After the sandbox name, complete a command and its arguments.
  if [ "${COMP_CWORD}" -gt 1 ]; then
    if declare -F _command_offset >& /dev/null; then
      _command_offset 2
    elif [ "${COMP_CWORD}" -eq 2 ]; then
      COMPREPLY=( $(compgen -c -- "${cur}") )
    else
      COMPREPLY=( $(compgen -f -- "${cur}") )
    fi
    return 0
  fi

  for dir in "${SANDBOXES_ROOT}"/*/; do
    [ -d "${dir}" ] && opts+=("$(basename "${dir}")")
  done

  COMPREPLY=( $(compgen -W "${opts[*]}" -- "${cur}") )
  return 0
}

# Setup command line completion for g
complete -F _g g

#
# Setup done once, in the nested shell started by 'g'.
#
if [[ -n "${SANDBOX}" && -z "${SANDBOX_DIR}" ]]; then

  if ! sandbox_exists "${SANDBOX}"; then
    echo "Sandbox '${SANDBOX}' doesn't exist in ${SANDBOXES_ROOT}."
  fi

  # SANDBOX_DIR is the root dir of the sandbox.
  # SANDBOX_DEFAULT is the default directory to jump to in sandbox.
  export SANDBOX_DIR="${SANDBOXES_ROOT}/${SANDBOX}"
  export SANDBOX_DEFAULT="${SANDBOX_DIR}"

  export PS1="($SANDBOX)\$"

  # Start in the sandbox root, so .sandbox can use relative paths.
  cd "${SANDBOX_DIR}"

  if type "sandbox_enter" >& /dev/null; then
    sandbox_enter
  fi

  if [ -e "${SANDBOX_DIR}/.sandbox" ]; then
    . "${SANDBOX_DIR}/.sandbox"
    # If .sandbox changes SANDBOX_DEFAULT, make sure its absolute.
    export SANDBOX_DEFAULT="$(_joinrel "${SANDBOX_DIR}" "${SANDBOX_DEFAULT}")"
  elif [ -e "${SANDBOX_DIR}/venv/bin/activate" ]; then
    # Enter a python virtual environment, if it exists.
    source "${SANDBOX_DIR}/venv/bin/activate"
  fi

  # Keep bash history per sandbox.
  HISTFILE="${SANDBOX_DIR}/.bash_history"

  # Start in the default directory.
  cd "${SANDBOX_DEFAULT}"
fi

#
# Inside a sandbox (including shells nested inside one), 'g' only changes
# directories.
#
if [ -n "${SANDBOX_DIR}" ]; then

  function g {
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
fi
