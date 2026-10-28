#!/usr/bin/env bash
# Emit GPU snapshot for QuickShell GpuWidget.
# Sections separated by --- :
#   kind
#   stats          intel: "<rc6_ms> <epoch_ms>"  amd/nvidia: "<busy_pct>"
#   freqs          "<act_mhz> <max_mhz>"
#   name
#   engines
#   vram           "<used_bytes> <total_bytes>" or "- -"

set -euo pipefail

emit() {
    local kind=$1 stats=$2 freqs=$3 name=$4 engines=$5 vram=$6
    printf '%s\n---\n%s\n---\n%s\n---\n%s\n---\n%s\n---\n%s\n' \
        "$kind" "$stats" "$freqs" "$name" "$engines" "$vram"
}

if command -v nvidia-smi >/dev/null 2>&1; then
    line=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,name \
        --format=csv,noheader,nounits 2>/dev/null | head -1 || true)
    if [[ -n ${line:-} ]]; then
        IFS=',' read -r busy memused memtotal name <<<"$line"
        busy=${busy// /}
        memused=${memused// /}
        memtotal=${memtotal// /}
        name=${name# }
        emit nvidia "$busy" "0 0" "$name" "" \
            "$((memused * 1024 * 1024)) $((memtotal * 1024 * 1024))"
        exit 0
    fi
fi

card=
for c in /sys/class/drm/card[0-9]*; do
    [[ -d $c/device ]] || continue
    if [[ -f $c/gt/gt0/rc6_residency_ms ]] \
        || [[ -f $c/device/gpu_busy_percent ]] \
        || [[ -f $c/device/gt_busy_percent ]]; then
        card=$c
        break
    fi
done

if [[ -z ${card:-} ]]; then
    echo none
    exit 0
fi

dev=$(readlink -f "$card/device")
slot=$(basename "$dev")
slot=${slot#0000:}
name=$(lspci -s "$slot" 2>/dev/null | sed -n 's/.*\[\(.*\)\].*/\1/p' || true)
if [[ -z ${name:-} ]]; then
    name=$(lspci -s "$slot" 2>/dev/null | sed -n 's/.*: //p' | sed 's/ (rev .*)$//' || true)
fi
engines=$(ls "$card/engine" 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]*$//' || true)

if [[ -f $card/gt/gt0/rc6_residency_ms ]]; then
    rc6=$(cat "$card/gt/gt0/rc6_residency_ms")
    ts=$(date +%s%3N)
    act=$(cat "$card/gt/gt0/rps_act_freq_mhz" 2>/dev/null || echo 0)
    max=$(cat "$card/gt/gt0/rps_max_freq_mhz" 2>/dev/null || echo 0)
    emit intel "$rc6 $ts" "$act $max" "$name" "$engines" "- -"
    exit 0
fi

busy=$(cat "$card/device/gpu_busy_percent" 2>/dev/null \
    || cat "$card/device/gt_busy_percent" 2>/dev/null \
    || echo 0)
act=$(cat "$card/device/gt_cur_freq_mhz" 2>/dev/null || echo 0)
max=$(cat "$card/device/gt_max_freq_mhz" 2>/dev/null || echo 0)
vu=$(cat "$card/device/mem_info_vram_used" 2>/dev/null || echo -)
vt=$(cat "$card/device/mem_info_vram_total" 2>/dev/null || echo -)
emit amd "$busy" "$act $max" "$name" "$engines" "$vu $vt"
