#!/usr/bin/env bash

_current_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0" || true)")" && pwd -P)"
_download_url='https://github.com/ryanoasis/nerd-fonts/releases/latest/download'
_fonts=(NerdFontsSymbolsOnly JetBrainsMono FiraCode Meslo Hack Noto)
readonly _download_url _current_dir _fonts

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

_cleanup() {
  say -n -arrow2
  say -red "Cleaning up…"
  shopt -s globstar

  IFS="$(printf '\n\t')"
  for file in "${_current_dir}"/**/*.md; do
    [[ -e ${file} ]] && command rm -rf "${file}"
  done
  for file in "${_current_dir}"/**/*.txt; do
    [[ -e ${file} ]] && command rm -rf "${file}"
  done
  for file in "${_current_dir}"/*.zip; do
    [[ -e ${file} ]] && command rm -rf "${file}"
  done

  shopt -u globstar
}

err() {
  _cleanup
  say -red "${@}" >&2
  exit 1
}

main() {
  for font in "${_fonts[@]}"; do
    say -n -arrow2
    say -cyan "Downloading $font…"
    command curl -s -LO "${_download_url}/${font}.zip"
    say -n -arrow2
    say -yellow "Extracting $font…"
    command unzip -o "${font}.zip" -d "${font}" >/dev/null 2>&1
  done
  _cleanup
  say -n -arrow2
  say -green "Done!"
}

main "${@}"
