#!/usr/bin/env bash
set -o pipefail
shopt -s nullglob

DRY_RUN=true
[[ "${1:-}" == "--run" ]] && DRY_RUN=false

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (e.g. sudo kernel-cleanup.sh)." >&2
    exit 1
fi

# ─── Build keep list ──────────────────────────────────────────────────────────

declare -A KEEP

RUNNING=$(uname -r)
KEEP["$RUNNING"]=1

while IFS= read -r pkg; do
    if [[ "$pkg" =~ ([0-9]+\.[0-9]+\.[0-9]+-[0-9]+-[a-z]+)$ ]]; then
        KEEP["${BASH_REMATCH[1]}"]=1
    fi
done < <(dpkg -l | awk '/^ii[[:space:]]+linux-image-[0-9]/{print $2}')

# ─── Print keep list ──────────────────────────────────────────────────────────

echo "Kernel keep list:"
while IFS= read -r v; do
    if [[ "$v" == "$RUNNING" ]]; then
        echo "  $v (running)"
    else
        echo "  $v"
    fi
done < <(printf '%s\n' "${!KEEP[@]}" | sort -V)
echo

# ─── Find candidates ──────────────────────────────────────────────────────────

declare -A CANDIDATES
declare -A APT_PKGS    # version -> space-separated package names
declare -A MOD_DIRS    # version -> directory path
declare -A BOOT_FILES  # version -> newline-separated file paths
declare -A BOOT_SKIP   # version -> 1 if a /boot symlink targets one of its files

# apt: rc (removed but not purged) kernel packages
while IFS= read -r pkg; do
    if [[ "$pkg" =~ ([0-9]+\.[0-9]+\.[0-9]+-[0-9]+-[a-z]+)$ ]]; then
        v="${BASH_REMATCH[1]}"
        [[ -n "${KEEP[$v]+x}" ]] && continue
        CANDIDATES["$v"]=1
        if [[ -n "${APT_PKGS[$v]+x}" ]]; then
            APT_PKGS["$v"]+=" $pkg"
        else
            APT_PKGS["$v"]="$pkg"
        fi
    fi
done < <(dpkg -l | awk '/^rc[[:space:]]+linux-/{print $2}')

# /usr/lib/modules directories
for dir in /usr/lib/modules/*/; do
    v=$(basename "$dir")
    [[ -n "${KEEP[$v]+x}" ]] && continue
    CANDIDATES["$v"]=1
    MOD_DIRS["$v"]="${dir%/}"
done

# Collect /boot symlink targets to protect
declare -A SYMLINK_TARGETS
for link in /boot/vmlinuz /boot/initrd.img /boot/vmlinuz.old /boot/initrd.img.old; do
    if [[ -L "$link" ]]; then
        if target=$(readlink -f "$link" 2>/dev/null); then
            SYMLINK_TARGETS["$target"]=1
        fi
    fi
done

# /boot files
for f in /boot/*; do
    [[ -f "$f" ]] || continue
    [[ "$f" =~ ([0-9]+\.[0-9]+\.[0-9]+-[0-9]+-[a-z]+) ]] || continue
    v="${BASH_REMATCH[1]}"
    [[ -n "${KEEP[$v]+x}" ]] && continue

    CANDIDATES["$v"]=1

    if [[ -n "${SYMLINK_TARGETS[$f]+x}" ]]; then
        BOOT_SKIP["$v"]=1
        continue
    fi

    if [[ -n "${BOOT_FILES[$v]+x}" ]]; then
        BOOT_FILES["$v"]+=$'\n'"$f"
    else
        BOOT_FILES["$v"]="$f"
    fi
done

# ─── Report ───────────────────────────────────────────────────────────────────

if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
    echo "System is clean. No orphaned kernels found."
    exit 0
fi

echo "Candidates for removal:"
echo

while IFS= read -r v; do
    echo "  $v:"

    if [[ -n "${APT_PKGS[$v]+x}" ]]; then
        for pkg in ${APT_PKGS[$v]}; do
            echo "    [apt]   $pkg (rc)"
        done
    fi

    if [[ -n "${MOD_DIRS[$v]+x}" ]]; then
        echo "    [mod]   ${MOD_DIRS[$v]}"
    fi

    if [[ -n "${BOOT_FILES[$v]+x}" ]]; then
        while IFS= read -r bf; do
            echo "    [boot]  $bf"
        done <<< "${BOOT_FILES[$v]}"
    fi

    if [[ -n "${BOOT_SKIP[$v]+x}" ]]; then
        echo "    [warn]  /boot file(s) for $v are symlink targets — boot removal skipped"
    fi

    echo
done < <(printf '%s\n' "${!CANDIDATES[@]}" | sort -V)

if $DRY_RUN; then
    echo "Run with --run to remove the above."
    exit 0
fi

# ─── Execute removal ──────────────────────────────────────────────────────────

echo "Removing orphaned kernels..."
echo

while IFS= read -r v; do
    echo "Processing $v..."

    if [[ -n "${APT_PKGS[$v]+x}" ]]; then
        echo "  Purging apt packages..."
        # shellcheck disable=SC2086
        apt-get purge -y ${APT_PKGS[$v]} || echo "  [warn] apt-get purge reported errors for $v"
    fi

    if [[ -n "${MOD_DIRS[$v]+x}" ]]; then
        echo "  Removing ${MOD_DIRS[$v]}..."
        rm -rf "${MOD_DIRS[$v]}" || echo "  [warn] Failed to remove ${MOD_DIRS[$v]}"
    fi

    if [[ -n "${BOOT_FILES[$v]+x}" ]]; then
        echo "  Removing /boot files..."
        while IFS= read -r bf; do
            echo "    $bf"
            rm -f "$bf" || echo "    [warn] Failed to remove $bf"
        done <<< "${BOOT_FILES[$v]}"
    fi

    if [[ -n "${BOOT_SKIP[$v]+x}" ]]; then
        echo "  [warn] Skipped /boot removal for $v — file(s) are symlink targets"
    fi

    echo "  Done."
    echo
done < <(printf '%s\n' "${!CANDIDATES[@]}" | sort -V)

echo "Cleanup complete."
