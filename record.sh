#!/bin/bash
# A simple Linux-only pure-shell showterm client for those without Ruby.
#
# Mac users (and Linux users with Ruby installed) should use the ruby client:
#   (sudo) gem install showterm
#
# Dependencies (please let me know if you don't have them all already)
#   mktemp (coreutils)
#   script (util-linux)
#   tput   (ncurses)
#   bash
#   curl
#
# To install. Just copy this file to your computer, and chmod +x showterm.
#
#   curl showterm.io/showterm > ~/bin/showterm
#   chmod +x ~/bin/showterm
#
# Otherwise you can run this file without installing:
#
#   bash <(curl record.showterm.io)
#
set -e

record_base_url="record.showterm.io"
upload_base_url="showterm.io"

if ! tty >/dev/null
then
    echo "Usage: bash <(curl $record_base_url)"
    exit 1
fi

if [ "-d" = "$1" -o "--delete" = "$1" ]
then
    url="${2?-Usage showterm --delete <url>}"
    curl --fail "$url" -X "DELETE" --data-urlencode "secret@$HOME/.showterm"
    exit
fi

scriptfile="$(mktemp /tmp/XXXXX.script)"
timingfile="$(mktemp /tmp/XXXXX.timing)"

cols="$(tput cols)"
lines="$(tput lines)"

server="${SHOWTERM_SERVER-$upload_base_url}"
url="${server%/}/scripts"

if [ "$*" ]
then
    echo "$*"
    args=-c "$*"
fi

if [ ! -f "$HOME/.showterm" ]
then
    echo -n $(openssl rand -hex 16) > "$HOME/.showterm"
fi

echo "showterm recording. (Exit shell when done.)"
script $args -q -t"$timingfile" "$scriptfile"
echo "Uploading..."

if curl --fail "$url" --data-urlencode "cols=$cols" --data-urlencode "lines=$lines" --data-urlencode "scriptfile@$scriptfile" --data-urlencode "timingfile@$timingfile" "secret@$HOME/.showterm" | grep http
then
    echo ""
    rm "$scriptfile" "$timingfile"
    exit 0
else
    echo "Uploading failed, but don't worry! Your work is safe. You can try uploading again with:"
    echo curl "$url" --data-urlencode "cols=$cols" --data-urlencode "lines=$lines" --data-urlencode "scriptfile@$scriptfile" --data-urlencode "timingfile@$timingfile" "secret@$HOME/.showterm"
fi
