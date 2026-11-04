#!/bin/bash
# Find MocaccinoOS ISO files below a directory and write a merged package list
# next to each one: <name>.iso -> <name>.pkglist
#
# Usage: mocaccino-packagelist.sh [-f] [-l] <dir-or-iso>
#   -f   regenerate lists that already exist
#   -l   add the layers (in build order) above the packages
#
# Needs: xorriso, unsquashfs (squashfs-tools)
#
# Per ISO: extract the squashfs from the ISO, extract only
# usr/share/mocaccino/packagelists from it, then merge the layer lists:
# union of all *.pkglist files. With -l the layers are listed above the atoms.

set -uo pipefail
shopt -s nullglob
export LC_ALL=C

LISTS_PATH="usr/share/mocaccino/packagelists"
force=0
layers=0

while getopts "fl" opt; do
    case $opt in
        f) force=1 ;;
        l) layers=1 ;;
        *) echo "Usage: $0 [-f] [-l] <dir-or-iso>" >&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

target=${1:-}
if [ -z "$target" ] || [ ! -e "$target" ]; then
    echo "Usage: $0 [-f] [-l] <dir-or-iso>" >&2
    exit 1
fi

for tool in xorriso unsquashfs; do
    command -v "$tool" >/dev/null 2>&1 || { echo "$0: $tool not found" >&2; exit 1; }
done

merge_lists() {  # <packagelists-dir> <output-file>
    local dir=$1 out=$2
    local lists=("$dir"/*.pkglist)
    [ ${#lists[@]} -gt 0 ] || return 1
    cat "${lists[@]}" | grep -v '^[[:space:]]*$' | sort -u > "$out"
}

# Layers are ordered by the timestamp of their .pkglist file (build time, so
# parents come before the layers built on top). Optional override: a layer order
# file with one layer name per line (no category), parents first. Layers listed
# there come first, the rest follow by timestamp.
ORDER_FILE=${ORDER_FILE:-$(dirname "$(readlink -f "$0")")/layer-order.txt}

layers_list() {  # <packagelists-dir> <output-file>
    local dir=$1 out=$2 f base cat name ver r g m i=0 l
    local -A rank=()
    if [ -f "$ORDER_FILE" ]; then
        while IFS= read -r l; do
            l=${l%%#*}; l=${l//[[:space:]]/}
            [ -n "$l" ] && rank[$l]=$((i++))
        done < "$ORDER_FILE"
    fi
    local lists=("$dir"/*.pkglist)
    [ ${#lists[@]} -gt 0 ] || return 1
    for f in "${lists[@]}"; do
        base=$(basename "$f" .pkglist)
        # <category>-<name>-<version>: the version is the last "-<digit>..." part,
        # optionally followed by a Gentoo revision (-r1), e.g. 3.4.2-r1+1
        if [[ $base =~ ^([^-]+)-(.+)-([0-9][^-]*(-r[0-9]+[^-]*)?)$ ]]; then
            cat=${BASH_REMATCH[1]} name=${BASH_REMATCH[2]} ver=${BASH_REMATCH[3]}
        else
            cat=unknown name=$base ver=-
        fi
        # firmware parts are cut out of linux-firmware: list only linux-firmware itself
        if [ "$cat" = firmware ] && [ "$name" != linux-firmware ]; then continue; fi
        r=${rank[$name]:-9999}
        m=$(stat -c %Y "$f")               # build time of the layer
        g=1; [ "$cat" = layers ] && g=0   # same time: layers before apps
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$r" "$m" "$g" "$name" "$cat" "$ver"
    done > "$out.tmp"
    if [ "$(cut -f2 "$out.tmp" | sort -u | wc -l)" -le 1 ] && [ ${#lists[@]} -gt 1 ]; then
        echo "WARN   all .pkglist files have the same timestamp, layers sorted by name" >&2
    fi
    sort -t $'\t' -k1,1n -k2,2n -k3,3n -k4,4 "$out.tmp" | awk -F '\t' '{ printf "%s/%s %s\n", $5, $4, $6 }' > "$out"
    rm -f "$out.tmp"
}

build_list() {  # <packagelists-dir> <output-file>
    local dir=$1 out=$2 t
    if [ "$layers" -eq 0 ]; then
        merge_lists "$dir" "$out"
        return
    fi
    t=$(mktemp -d) || return 1
    if merge_lists "$dir" "$t/pkgs" && layers_list "$dir" "$t/layers"; then
        {
            echo "# Layers (stacking order)"
            cat "$t/layers"
            echo
            echo "# Packages"
            cat "$t/pkgs"
        } > "$out"
        rm -rf "$t"
    else
        rm -rf "$t"; return 1
    fi
}

process_iso() {  # <iso>
    local iso=$1 out="${1%.iso}.pkglist" tmp sq
    if [ -e "$out" ] && [ "$force" -eq 0 ]; then
        echo "skip   $iso (list exists, use -f)"
        return 0
    fi

    tmp=$(mktemp -d) || return 1

    # Locate the squashfs inside the ISO (xorriso prints the path in single quotes)
    sq=$(xorriso -indev "$iso" -find / -type f -name '*.squashfs' 2>/dev/null \
         | sed "s/^'//;s/'\$//" | head -n 1)
    if [ -z "$sq" ]; then
        echo "FAIL   $iso (no *.squashfs found in the ISO)" >&2
        rm -rf "$tmp"; return 1
    fi

    if ! xorriso -osirrox on -indev "$iso" -extract "$sq" "$tmp/root.squashfs" >/dev/null 2>&1; then
        echo "FAIL   $iso (could not extract $sq)" >&2
        rm -rf "$tmp"; return 1
    fi

    if ! unsquashfs -n -f -d "$tmp/root" "$tmp/root.squashfs" "$LISTS_PATH" >/dev/null 2>&1 \
       || [ ! -d "$tmp/root/$LISTS_PATH" ]; then
        echo "WARN   $iso (no package lists inside, built before they existed?)" >&2
        rm -rf "$tmp"; return 0
    fi

    if build_list "$tmp/root/$LISTS_PATH" "$out"; then
        echo "ok     $out ($(grep -vc '^#\|^$' "$out") lines)"
    else
        echo "FAIL   $iso (no .pkglist files in the lists directory)" >&2
        rm -f "$out"; rm -rf "$tmp"; return 1
    fi
    rm -rf "$tmp"
}

status=0
if [ -f "$target" ]; then
    process_iso "$target" || status=1
else
    found=0
    while IFS= read -r -d '' iso; do
        found=1
        process_iso "$iso" || status=1
    done < <(find "$target" -type f -name '*.iso' -print0 | sort -z)
    [ "$found" -eq 1 ] || { echo "$0: no .iso files below $target" >&2; status=1; }
fi
exit $status
