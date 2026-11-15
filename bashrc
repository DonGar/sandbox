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
# Wrapper for starting Claude Code sessions: update first, then start. Inside
# a sandbox, name the session after the sandbox and turn on Remote Control
# under that name.
#
# Subcommands ('claude mcp ...', 'claude update', ...) and non-interactive
# runs (--print, --help, --version) go to claude unchanged.
#
function claude {
  local arg
  local remote=()

  case "${1}" in
    agents|attach|auth|auto-mode|doctor|gateway|import|install|logs|mcp|\
    plugin|plugins|purge|respawn|rm|setup-token|stop|kill|ultrareview|\
    update|upgrade)
      command claude "$@"
      return
      ;;
  esac

  for arg in "$@"; do
    case "${arg}" in
      -p|--print|-h|--help|-v|--version)
        command claude "$@"
        return
        ;;
    esac
  done

  command claude update || return

  if [ -z "${SANDBOX}" ]; then
    command claude "$@"
    return
  fi

  # Leave Remote Control alone if it was asked for explicitly.
  remote=(--remote-control "${SANDBOX}")
  for arg in "$@"; do
    case "${arg}" in
      --remote-control|--remote-control=*) remote=() ;;
    esac
  done

  CLAUDE_SESSION_TITLE="${SANDBOX}" command claude "${remote[@]}" "$@"
}

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

  # Each sandbox has one tmux session, named after it. 'tmux', 'tmux attach'
  # and 'tmux new' (with no other arguments) attach to that session, creating
  # it first if needed. Anything else is passed to tmux unchanged.
  function tmux {
    # Inside tmux already, there is nothing to attach to: act as plain tmux.
    if [ -n "${TMUX}" ]; then
      command tmux "$@"
      return
    fi

    if [ $# -gt 1 ]; then
      command tmux "$@"
      return
    fi

    case "${1}" in
      ''|a|at|att|atta|attac|attach|attach-session|new|new-session)
        # The tmux server may have been started from another sandbox (or
        # none), so say which sandbox this session is for. The empty
        # SANDBOX_DIR makes each shell in the session set itself up.
        command tmux new-session -A -s "${SANDBOX}" -c "${SANDBOX_DIR}" \
          -e "SANDBOX=${SANDBOX}" -e "SANDBOX_DIR="
        ;;
      *)
        command tmux "$@"
        ;;
    esac
  }
fi
