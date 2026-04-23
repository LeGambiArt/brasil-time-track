#!/bin/bash

# SPDX: GPL-3.0-or-later

set -euo pipefail

KAIROS_DATE="$(date +"%d-%m-%Y %H:%M:00" | tr ' ' '+' | sed -e 's/:/%3A/g')"
LOGDIR="${KAIROS_LOGDIR:-"$(pwd)"}"
LOGFILE="${LOGDIR}/kairos.log"
TODAY="$(date +"%Y-%m-%d_%H%M")"

USER_AGENT='Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0'

URL="https://www.dimepkairos.com.br/Dimep/Account/Marcacao"
COOKIE=/tmp/kairos.cookie

die() {
  echo "## ERRO: ${*}" >&2
  rm -f "${COOKIE}"
  exit 1
}

usage() {
  printf 'Uso: %s [-h] [-p|-d] [USERNAME]\n' "$(basename ${0})" >&2
  cat <<EOF >&2

Argumentos:

    USERNAME     Nome do usuário Kairos.

Opções:
    -h           Show this message and exit

    -d           Verificar dependencias.
    -p           Resetar senha.

EOF
}

quiet() {
    "$@" >/dev/null 2>&1
}

check_dependencies() {
    FAILED=""
    for dep in curl secret-tool
    do
        if ! quiet command -v secret-tool
        then
            echo "Dependencia '$dep' não encontrada."
            FAILED="YES"
        fi
    done
    [[ -z "${FAILED}" ]] || return 1
    echo "Todas as dependencias satisfeitas."
}

if [[ $# -lt 1 ]]
then
    usage
    exit 1
fi

if [[ "$1" == "-h" ]]
then
    usage
    exit 0
fi

if [[ "$1" == "-d" ]]
then
    check_dependencies
    exit $?
fi

if [[ "$1" == "-p" ]]
then
    shift
    RESET_PASS="yes"
fi

[[ $# -gt 1 ]] && usage

check_dependencies

if [[ -f "${HOME}/.brasil-kairos" ]]
then
    . "${HOME}/.brasil-kairos"
elif [[ -f "${HOME}/.config/brasil-kairos" ]]
    . "${HOME}/.config/brasil-kairos"
elif  [[ -f '.env' ]]
    source '.env'
fi

KAIROS_USER="${1:-${KAIROS_USER:-}}"

[[ -z "${KAIROS_USER}" ]] && die "Usuário Kairos não definido."

# Ensure entry exists in keyring or is updated upon request
if [[ "${RESET_PASS:-}" == "yes" ]] \
    || ! grep -Fq attribute.label < <(secret-tool search label "KAIROS:${KAIROS_USER}" 2>&1)
then
    secret-tool store --label="KAIROS:${KAIROS_USER}" \
        label "KAIROS:${KAIROS_USER}" \
        uuid $(uuidgen) create "$(date)"
fi

KAIROS_PASS="$(secret-tool lookup label "KAIROS:${KAIROS_USER}")"

if [ -z "${KAIROS_USER}" ] || [ -z "${KAIROS_PASS}" ]; then
  usage
fi

curl -sL -c "${COOKIE}" -e "${URL}" -A "${USER_AGENT}" "${URL}" > /dev/null

curl -sL -b "${COOKIE}" -e "${URL}" -A "${USER_AGENT}" \
     -d "UserName=${KAIROS_USER}" --data-urlencode "Password=${KAIROS_PASS}" \
     -d "DateMarking=${KAIROS_DATE}" -d "Ip=false" \
     "${URL}" > "/tmp/kairos-${TODAY}.html" \
        || die "Falha ao bater o ponto"

if [[ -n "${KAIROS_PDFDIR:-}" ]]
then
    [[ -d "${KAIROS_PDFDIR}" ]] || quiet mkdir -p "${KAIROS_PDFDIR}"

    PDF_URL="$(sed -n 's#.*>\(https://storage.*dimepbr-comprovanteponto.*pdf\).*$#\1#p' < "/tmp/kairos-${TODAY}.html")"
    curl -so "${HOME}/Documents/holerites/ponto/kairos-${TODAY}.pdf" "${PDF_URL}" || die "Falha ao salvar comprovante"
fi

rm -f "${COOKIE}"

[[ -d "${LOGDIR}" ]] || quiet mkdir -p "${LOGDIR}"
echo "${TODAY}" >> "${LOGFILE}"
