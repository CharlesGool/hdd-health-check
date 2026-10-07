#!/usr/bin/env bash
# Install the prebuilt local Web UI on a Debian systemd host.
set -Eeuo pipefail
umask 077

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
app_dir=/root/apps/hdd-health-check
unit_file=/etc/systemd/system/hdd-health-web.service
service=hdd-health-web.service
stamp=$(date +%Y%m%d-%H%M%S)-$$
stage=
old_app=
old_unit=
old_active=0
old_enabled=0
had_unit=0
install_started=0
app_swapped=0
unit_swapped=0

say() { printf '%s\n' "$*"; }
die() {
    say "Error: $*" >&2
    if (( install_started )); then rollback 1; fi
    exit 1
}

rollback() {
    local code=$1
    trap - ERR
    if (( install_started )); then
        say "Installation failed; restoring the previous service and files." >&2
        systemctl stop "$service" >/dev/null 2>&1 || true
        if (( app_swapped )); then
            if [[ -d $app_dir ]]; then mv -- "$app_dir" "${app_dir}.failed-${stamp}"; fi
            if [[ -n $old_app && -d $old_app ]]; then mv -- "$old_app" "$app_dir"; fi
        fi
        if (( unit_swapped )); then
            if (( had_unit )); then
                if [[ -n $old_unit && -f $old_unit ]]; then cp -a -- "$old_unit" "$unit_file"; fi
            else
                rm -f -- "$unit_file"
            fi
        fi
        if (( ! old_enabled )); then systemctl disable "$service" >/dev/null 2>&1 || true; fi
        systemctl daemon-reload >/dev/null 2>&1 || true
        if (( old_active )); then systemctl start "$service" >/dev/null 2>&1 || true; fi
    fi
    exit "$code"
}
trap 'rollback $?' ERR
trap 'rollback 130' INT
trap 'rollback 143' TERM
trap 'if [[ -n $stage && -d $stage ]]; then rm -rf -- "$stage"; fi' EXIT

[[ $# -eq 0 ]] || die "Usage: sudo bash deploy/install.sh"
(( EUID == 0 )) || die "Run with sudo: sudo bash deploy/install.sh"
[[ -r /etc/os-release ]] || die "Cannot identify the operating system"
# shellcheck disable=SC1091
. /etc/os-release
[[ ${ID:-} == debian ]] || die "This installer supports Debian; found ${PRETTY_NAME:-unknown}"
command -v apt-get >/dev/null || die "apt-get is required"
command -v dpkg-query >/dev/null || die "dpkg-query is required"
command -v systemctl >/dev/null || die "systemd is required"
[[ -d /run/systemd/system ]] || die "systemd is not running as the system manager"

for file in src/checker/hdd-health-check.sh src/web/server.py dist/web/index.html deploy/hdd-health-web.service doc/CHANGELOG.md; do
    [[ -f $source_dir/$file && ! -L $source_dir/$file ]] || die "Missing or linked package file: $file"
done
[[ -z $(find "$source_dir/dist/web" -type l -print -quit) ]] || die "dist/web contains a symbolic link"
[[ ! -L /root/apps && ! -L $app_dir && ! -L $unit_file ]] || die "An installation path is a symbolic link"

if [[ -f $unit_file ]]; then
    grep -Fq 'ExecStart=/usr/bin/python3 /root/apps/hdd-health-check/web/server.py --port 8765' "$unit_file" ||
        die "$unit_file exists but is not this project's service"
    had_unit=1
    if systemctl is-active --quiet "$service"; then old_active=1; fi
    if systemctl is-enabled --quiet "$service"; then old_enabled=1; fi
elif [[ -e $unit_file ]]; then
    die "$unit_file is not a regular file"
fi

declare -a missing=()
for package in python3 smartmontools util-linux coreutils e2fsprogs procps; do
    if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -qx 'install ok installed'; then
        missing+=("$package")
    fi
done
if ((${#missing[@]})); then
    say "Installing missing Debian packages: ${missing[*]}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends "${missing[@]}"
fi

python3 -c 'import sys; sys.exit(sys.version_info < (3, 10))' || die "Python 3.10 or newer is required"
for executable in smartctl lsblk blockdev dd badblocks pkill; do
    command -v "$executable" >/dev/null || die "Missing executable after package installation: $executable"
done

if (( ! old_active )); then
    python3 -c 'import socket; s=socket.socket(); s.bind(("0.0.0.0", 8765)); s.close()' ||
        die "TCP port 8765 is already in use"
fi

mkdir -p /root/apps
stage=$(mktemp -d /root/apps/.hdd-health-check.new.XXXXXX)
install -m 0755 "$source_dir/src/checker/hdd-health-check.sh" "$stage/hdd-health-check.sh"
install -d -m 0755 "$stage/web" "$stage/doc"
install -m 0644 "$source_dir/src/web/server.py" "$stage/web/server.py"
cp -a -- "$source_dir/dist/web" "$stage/web/dist"
if [[ -f $app_dir/web-password && ! -L $app_dir/web-password ]]; then
    install -m 0600 "$app_dir/web-password" "$stage/web-password"
else
    python3 -c 'import pathlib, secrets, sys; pathlib.Path(sys.argv[1]).write_text(secrets.token_urlsafe(32) + "\n")' "$stage/web-password"
    chmod 0600 "$stage/web-password"
fi
install -m 0644 "$source_dir/doc/CHANGELOG.md" "$stage/doc/CHANGELOG.md"
for language in ar en es fr hi zh-HK zh-TW; do
    [[ -f $source_dir/doc/$language/CHANGELOG.md && ! -L $source_dir/doc/$language/CHANGELOG.md ]] ||
        die "Missing or linked update record: doc/$language/CHANGELOG.md"
    install -d -m 0755 "$stage/doc/$language"
    install -m 0644 "$source_dir/doc/$language/CHANGELOG.md" "$stage/doc/$language/CHANGELOG.md"
done
find "$stage/web/dist" -type d -exec chmod 0755 {} +
find "$stage/web/dist" -type f -exec chmod 0644 {} +
verify_output=$(systemd-analyze verify "$source_dir/deploy/hdd-health-web.service" 2>&1) ||
    die "Service unit validation failed: $verify_output"
if [[ $verify_output == *hdd-health-web.service* ]]; then say "$verify_output"; fi

say "Installing to $app_dir"
install_started=1
if (( old_active )); then systemctl stop "$service"; fi
if [[ -e $app_dir ]]; then
    [[ -d $app_dir ]] || die "$app_dir exists but is not a directory"
    old_app="${app_dir}.backup-${stamp}"
    mv -- "$app_dir" "$old_app"
    app_swapped=1
fi
mv -- "$stage" "$app_dir"
app_swapped=1
stage=
if (( had_unit )); then
    old_unit="${unit_file}.backup-${stamp}"
    cp -a -- "$unit_file" "$old_unit"
fi
unit_swapped=1
install -m 0644 "$source_dir/deploy/hdd-health-web.service" "$unit_file"
systemctl daemon-reload
systemctl enable --now "$service"

ready=0
for ((attempt=0; attempt<10; attempt++)); do
    if python3 -c 'import json, pathlib, urllib.request; password=pathlib.Path("/root/apps/hdd-health-check/web-password").read_text().strip(); request=urllib.request.Request("http://127.0.0.1:8765/api/auth/login", data=json.dumps({"password":password}).encode(), headers={"Content-Type":"application/json", "X-HDD-CSRF":"1"}); response=urllib.request.urlopen(request, timeout=3); data=json.load(response); assert data["authenticated"] and any(cookie.startswith("hdd_session=") for cookie in response.headers.get_all("Set-Cookie", []))' 2>/dev/null; then
        ready=1
        break
    fi
    sleep 1
done
(( ready )) || die "Service started but its API did not respond; run journalctl -u $service"
systemctl is-active --quiet "$service" || die "Service is not active"

install_started=0
say "Installed and running: $service"
say "Open from the LAN: http://<NAS-IP>:8765"
say "Read the password on the NAS: sudo cat /root/apps/hdd-health-check/web-password"
say "Do not forward port 8765 to the Internet; LAN HTTP does not encrypt credentials."
if [[ -n $old_app ]]; then say "Previous files: $old_app"; fi
if [[ -n $old_unit ]]; then say "Previous unit: $old_unit"; fi
