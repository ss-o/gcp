#!/usr/bin/env bash

_current_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0" || true)")" && pwd -P)"
_owner="${1:-user}"
readonly _current_dir _owner

say() {
  one_line='' col=''
  while [ -n "$1" ]; do
    case "$1" in
    -normal) col="\033[00m" ;;
    -black) col="\033[30;01m" ;;
    -red) col="\033[31;01m" ;;
    -green) col="\033[32;01m" ;;
    -yellow) col="\033[33;01m" ;;
    -blue) col="\033[34;01m" ;;
    -magenta) col="\033[35;01m" ;;
    -cyan) col="\033[36;01m" ;;
    -white) col="\033[37;01m" ;;
    -arrow1) col="\033[32;01m➜ \033[0m" ;;
    -arrow2) col="\033[32;01m» \033[0m" ;;
    -n)
      one_line=1
      shift
      continue
      ;;
    *)
      printf '%s' "${*}"
      shift
      continue
      ;;
    esac
    shift
    printf "%s${col}"
    printf "%s" "${*}"
    printf "\033[00m"
    shift
  done
  [ -z "${one_line}" ] && printf "\n"
}

err() {
  say -red "${@}" >&2
  exit 1
}

[[ $# -ne 0 ]] && [[ $_owner != 'user' ]] && [[ $_owner != 'system' ]] && {
  err "Usage: $0 [user|system]"
}

[[ $_owner == 'system' ]] && [[ $(id -u) -ne 0 ]] && {
  err "You must be root to install fonts to system"
}

_prepare() {
  if [[ $(uname) == 'Darwin' ]]; then
    # MacOS
    sys_font_dir="/Library/Fonts"
    usr_font_dir="$HOME/Library/Fonts"
  else
    # Linux
    sys_font_dir="/usr/local/share/fonts"
    usr_font_dir="$HOME/.local/share/fonts"
  fi
  sys_font_dir="${sys_font_dir}/NerdFonts"
  usr_font_dir="${usr_font_dir}/NerdFonts"

  if [[ "system" == "$_owner" ]]; then
    font_dir="${sys_font_dir}"
  else
    font_dir="${usr_font_dir}"
  fi

  if [[ ! -d ${font_dir} ]]; then
    command mkdir -p "${font_dir}"
  fi
}

_copy_fonts() {
  shopt -s globstar
  IFS="$(printf '\n\t')"

  say -n -arrow2 "Copying fonts to ${font_dir}…"

  for font in "${_current_dir}"/**/*.ttf; do
    command cp -f "${font}" "${font_dir}"
  done

  case $? in
  [0]) say -green " ✔" ;;
  *) err " ✘" ;;
  esac

  shopt -u globstar
}

_update_font_cache() {
  if [[ -n $(command -v mkfontdir) ]]; then

    say -n -arrow2 "Creating font index file for use by X server…"
    mkfontdir "${font_dir}" >/dev/null 2>&1
    case $? in
    [0]) say -green " ✔" ;;
    *) err " ✘" ;;
    esac
    say -n -arrow2 "Creating font index of scalable font files…"
    mkfontscale "${font_dir}" >/dev/null 2>&1
    case $? in
    [0]) say -green " ✔" ;;
    *) err " ✘" ;;
    esac
  fi

  if [[ -n $(command -v fc-cache) ]]; then

    say -n -arrow2 "Updating font cache…"
    fc-cache -f "${font_dir}" >/dev/null 2>&1

    case $? in
    [0-1]) say -green " ✔" ;;
    *) err " ✘" ;;
    esac
  fi
}

main() {
  _prepare
  _copy_fonts
  _update_font_cache
}

main "$@"
