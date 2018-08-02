#!/bin/sh

main() {
  CONFIG="${CONFIG:-./config.sh}"

  case $1 in
    -h | --help )
      show_help
      return
      ;;

    -c | --config )
      CONFIG="$2"
      shift; shift
      ;;
  esac

  TARGET="$1"
  . "$CONFIG"
  
  replace_values "Hostname" "$HOSTNAME" "$TARGET"
  replace_values "Username" "$USERNAME" "$TARGET"
  replace_values "Timezone" "$TIMEZONE" "$TARGET"
  replace_values "Persistence" "$PERSISTENCE" "$TARGET"
  replace_values "Week" "$(date +%V)" "$TARGET"
}

show_help() {
  cat <<EOF
Usage: $0 [-c CONFIG_FILE | --config CONFIG_FILE]

-c CONFIG_FILE, --config CONFIG_FILE
  Uses a custom configuration file. (./config.sh)

-h, --help
  Shows this help text.
EOF
}

replace_values() {
  KEY="$1"
  VALUE="$2"
  TARGET="${3:-.}"

  ESCAPED=$(
    echo "$VALUE" |
    sed -re "s/\/+/\\\\\//g" |
    sed -re "s/(\\\\)?\/$//g"
  )

  for file in $(grep -lr "$KEY" "$TARGET"); do
    sed -re "s/\{\{ $KEY \}\}/$ESCAPED/g" -i "$FILE"
  done
}

main $@

