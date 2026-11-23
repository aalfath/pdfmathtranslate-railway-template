#!/bin/sh
# Start PDFMathTranslate's web UI behind a login, with its state on the volume.
set -eu

DATA="${PDF2ZH_DATA_DIR:-/data}"
PORT="${PORT:-7860}"
USER_NAME="${WEB_USERNAME:-admin}"

if [ -z "${WEB_PASSWORD:-}" ]; then
  echo "WEB_PASSWORD is empty: refusing to start an open web UI." >&2
  exit 1
fi
case "$USER_NAME$WEB_PASSWORD" in
  *,*) echo "WEB_USERNAME and WEB_PASSWORD must not contain a comma." >&2; exit 1 ;;
esac

mkdir -p "$DATA/config" "$DATA/cache" "$DATA/files" /root/.config /root/.cache

# Saved settings (~/.config/PDFMathTranslate) and the translation cache
# (~/.cache/pdf2zh) live on the volume. The models and fonts baked into the
# image (~/.cache/babeldoc) stay in the image, so nothing is downloaded.
link() { # link <path> <target>
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    cp -a "$1/." "$2/" 2>/dev/null || true
    rm -r "$1"
  fi
  ln -sfn "$2" "$1"
}
mkdir -p "$DATA/config/PDFMathTranslate" "$DATA/cache/pdf2zh"
link /root/.config/PDFMathTranslate "$DATA/config/PDFMathTranslate"
link /root/.cache/pdf2zh "$DATA/cache/pdf2zh"
link /app/pdf2zh_files "$DATA/files"

# Uploaded and translated PDFs are kept for PDF2ZH_KEEP_DAYS days (default 7).
KEEP_DAYS="${PDF2ZH_KEEP_DAYS:-7}"
find "$DATA/files" -type f -mtime +"$KEEP_DAYS" -delete 2>/dev/null || true

# Login file for Gradio (one "user,password" line), rebuilt on every start
# so a changed WEB_PASSWORD takes effect on the next deploy.
AUTH_FILE=/tmp/pdf2zh-users.txt
umask 077
printf '%s,%s\n' "$USER_NAME" "$WEB_PASSWORD" > "$AUTH_FILE"

cd /app
echo "Starting PDFMathTranslate on port $PORT (login user: $USER_NAME)"
python /usr/local/lib/pdf2zh-railway/lowmem.py -i --serverport "$PORT" --authorized "$AUTH_FILE" &
pid=$!
stopping=0
trap 'stopping=1; kill -TERM "$pid" 2>/dev/null' TERM INT
set +e
wait "$pid"
code=$?
# wait returns early when a signal arrives; wait again for the real exit code
if kill -0 "$pid" 2>/dev/null; then wait "$pid"; code=$?; fi
# A stop we were asked for (redeploy, shutdown) ends cleanly. Any other exit
# is unexpected for a server, so never report success: Railway's ON_FAILURE
# restart policy then brings it back.
if [ "$stopping" -eq 1 ]; then exit 0; fi
if [ "$code" -eq 0 ]; then code=1; fi
echo "pdf2zh exited with code $code" >&2
exit "$code"
