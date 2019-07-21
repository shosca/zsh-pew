RED="\e[31m"
GREEN="\e[32m"
PURPLE="\e[35m"
BOLD="\e[1m"
NORMAL="\e[0m"

if ! type "pew" > /dev/null; then
  export DISABLE_PEW_AUTOACTIVATE="1"
  printf "${BOLD}${RED}"
  printf "pew required to auto activate virtualenvs.!\n\n"
  printf "${NORMAL}"
  printf "If pew is already installed but you are still seeing this message, \n"
  printf "then make sure the ${BOLD}pew${NORMAL} command is in your PATH.\n"
  printf "\n"
else
  . $(pew shell_config)
fi

function mkvirtualenv() {
  if [[ -f ".venv" ]]; then
    printf ".venv file already exists.\n"
    return
  fi
  local virtualenv_name="$(basename $PWD)"
  printf "Creating ${PURPLE}%s${NORMAL} virtualenv\n" "$virtualenv_name"

  params=("${@[@]}")

  if [[ -n "$PEW_DEFAULT_PYTHON" && ${params[(I)--python*]} -eq 0 ]]; then
    params+="--python=$PEW_DEFAULT_PYTHON"
  fi

  if [[ -f "$PWD/Pipfile" ]]; then
    pipenv install -d
    local virtualenv_name="$(basename $(pipenv --venv))"
  else
    pew new -d $params $virtualenv_name
  fi

  printf "$virtualenv_name\n" > ".venv"
  chmod 600 .venv

  install_requirements
}

function workon() {
  local virtualenv_name=$(_check_venv "$PWD")
  if ! [[ -n "$virtualenv_name" ]]; then
    printf "Couldn't find a configured virtualenv. Please create a virtualenv using mkvirtualenv in project root.\n"
    return
  fi
  if [[ -n "$VIRTUAL_ENV" ]]; then
    printf "Already in a virtualenv.\n"
    return
  fi
  pew workon $virtualenv_name
}

function inve() {
  local virtualenv_name=$(_check_venv "$PWD")
  if ! [[ -n "$virtualenv_name" ]]; then
    printf "Couldn't find a configured virtualenv. Please create a virtualenv using mkvirtualenv in project root.\n"
    return
  fi
  pew in $virtualenv_name "$@"
}

function install_requirements() {
  local virtualenv_name=$(_check_venv "$PWD")
  if ! [[ -n "$virtualenv_name" ]]; then
    printf "Couldn't find a configured virtualenv. Please create a virtualenv using mkvirtualenv in project root.\n"
    return
  fi
  if [[ -f "$PEW_DEFAULT_REQUIREMENTS" ]]; then
    printf "Install default requirements? (${PURPLE}$PEW_DEFAULT_REQUIREMENTS${NORMAL}) [y/N]: "
    read ans
    if [[ "$ans" = "y" || "$ans" == "Y" ]]; then
      pew in $virtualenv_name pip install -r "$PEW_DEFAULT_REQUIREMENTS"
    fi
  fi
  if [[ -f "$PWD/setup.py" ]]; then
    printf "Found a ${PURPLE}setup.py${NORMAL} file. Install dependencies? [y/N]: "
    read ans

    if [[ "$ans" = "y" || "$ans" = "Y" ]]; then
      pew in $virtualenv_name pip install -e .
    fi
  fi

  setopt nullglob
  for requirements in **/*requirements.txt; do
    printf "Found a ${PURPLE}%s${NORMAL} file. Install? [y/N]: " "$requirements"
    read ans

    if [[ "$ans" = "y" || "$ans" = "Y" ]]; then
      pew in $virtualenv_name pip install -r "$requirements"
    fi
  done
}

function rmvirtualenv() {
  local virtualenv_name=$(_check_venv "$PWD")
  if ! [[ -n "$virtualenv_name" ]]; then
    printf "No virtualenv setup for current directory!\n"
    return
  fi
  printf "Removing ${PURPLE}%s${NORMAL}...\n" "$virtualenv_name"
  if pew rm $virtualenv_name > /dev/null; then
    /bin/rm ".venv"
  fi
}

function _check_venv_path() {
  local check_dir="$1"

  if [[ -f "${check_dir}/.venv" ]]; then
    printf "${check_dir}/.venv"
    return
  else
    # Abort search at file system root or HOME directory (latter is a perfomance optimisation).
    if [[ "$check_dir" = "/" || "$check_dir" = "$HOME" ]]; then
      return
    fi
    _check_venv_path "$(dirname "$check_dir")"
  fi
}

function _check_venv() {
  local venv_path=$(_check_venv_path "$PWD")
  if [[ -n "$venv_path" ]]; then
    stat --version &> /dev/null
    if [[ $? -eq 0 ]]; then   # Linux, or GNU stat
      file_owner="$(stat -c %u "$venv_path")"
      file_permissions="$(stat -c %a "$venv_path")"
    else                      # macOS, or FreeBSD stat
      file_owner="$(stat -f %u "$venv_path")"
      file_permissions="$(stat -f %OLp "$venv_path")"
    fi

    if [[ "$file_owner" != "$(id -u)" ]]; then
      printf "AUTOSWITCH WARNING: Virtualenv will not be activated\n\n"
      printf "Reason: Found a .venv file but it is not owned by the current user\n"
      printf "Change ownership of ${PURPLE}$venv_path${NORMAL} to ${PURPLE}'$USER'${NORMAL} to fix this\n"
    elif ! [[ "$file_permissions" =~ ^[64][04][04]$ ]]; then
      printf "AUTOSWITCH WARNING: Virtualenv will not be activated\n\n"
      printf "Reason: Found a .venv file with weak permission settings ($file_permissions).\n"
      printf "Run the following command to fix this: ${PURPLE}\"chmod 600 $venv_path\"${NORMAL}\n"
    fi
    printf "$(<"$venv_path")"
  fi
}

function check_pew() {
  local virtualenv_name=$(_check_venv "$PWD")
  if ! [[ -n "$VIRTUAL_ENV" ]]; then
    if [[ -n "$virtualenv_name" ]]; then
      pew workon $virtualenv_name
    elif [[ -f "$PWD/requirements.txt" || -f "$PWD/setup.py" || -f "$PWD/Pipfile.lock" ]]; then
      printf "Python project detected. "
      printf "Run ${PURPLE}mkvirtualenv${NORMAL} to setup autoswitching\n"
    fi
  fi
}

function enable_pew_autoactivate() {
  autoload -Uz add-zsh-hook
  disable_pew_autoswitch
  add-zsh-hook chpwd check_pew
}

function disable_pew_autoactivate() {
  add-zsh-hook -D chpwd check_pew
}

if [[ -z "$DISABLE_PEW_AUTOACTIVATE" ]]; then
  enable_pew_autoactivate
  check_pew
fi
