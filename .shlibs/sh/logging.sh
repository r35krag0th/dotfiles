function r35_log_critical() {
  __r35_log "critical" "$1"
}

function r35_log_error() {
  __r35_log "error" "$1"
}

function r35_log_warn() {
  __r35_log "warn" "$1"
}

function r35_log_info() {
  __r35_log "info" "$1"
}

function r35_log_debug() {
  __r35_log "debug" "$1"
}

function r35_log_header() {
  local caller_origin="${BASH_SOURCE[1]:-}"
  if [ -n "${caller_origin}" ]; then
    caller_origin="\033[38;5;237m[\033[38;5;244m$caller_origin\033[38;5;237m]\033[0m "
  fi

  echo -e "${caller_origin}\033[1;36m󰓘 \033[0m ${1}"
}

function r35_log_ok() {
  local caller_origin="${BASH_SOURCE[1]:-}"
  if [ -n "${caller_origin}" ]; then
    caller_origin="\033[38;5;237m[\033[38;5;244m$caller_origin\033[38;5;237m]\033[0m "
  fi

  echo -e "${caller_origin}\033[1;32m \033[0m ${1}"
}

function __r35_log() {
  # $1 = level
  # $2 = message
  local level_prefix=""
  local level_color="37"
  local level_id=0 # 30=info, 20=warn, 10=error
  local target_log_level_id=10

  # if target is 30 (info) and level is 20, show
  # if target is 10 (error) and level is 30,

  case "${R35_LOG_LEVEL:-info}" in
  critical) target_log_level_id=50 ;;
  error) target_log_level_id=40 ;;
  warn) target_log_level_id=30 ;;
  info) target_log_level_id=20 ;;
  debug) target_log_level_id=10 ;;
  esac

  case "${1}" in
  critical)
    level_icon=" "
    level_color="162"
    level_prefix="[FTL]"
    level_id=50
    ;;
  error)
    level_icon=" "
    level_color="124"
    level_prefix="[ERR]"
    level_id=40
    ;;
  warn)
    level_icon=" "
    level_color="220"
    level_prefix="[WRN]"
    level_id=30
    ;;
  info)
    level_icon=" "
    level_color="35"
    level_prefix="[INF]"
    level_id=20
    ;;
  debug)
    level_icon=" "
    level_color="30"
    level_prefix="[DBG]"
    level_id=10
    ;;
  esac

  if [ $target_log_level_id -gt $level_id ]; then
    return 1
  fi

  # Origin
  local caller_origin="${BASH_SOURCE[1]:-}"
  if [ -n "${caller_origin}" ]; then
    caller_origin="\033[38;5;237m[\033[38;5;244m$caller_origin\033[38;5;237m]\033[0m "
  fi

  echo -e "${caller_origin}\033[1m\033[38;5;${level_color}m${level_icon} ${level_prefix}\033[0m ${1} ${2}"
}
