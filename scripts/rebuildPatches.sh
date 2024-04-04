#!/usr/bin/env bash

(
PS1="$"
basedir="$(cd "$1" && pwd -P)"
echo "Rebuilding patch files from current fork state..."
git config core.safecrlf false

function cleanupPatches {
    # Cd to the patches directory
    cd "$1"

    # Cleanup patches
    for patch in *.patch; do
        echo "$patch"
        gitver=$(tail -n 2 "$patch" | grep -ve "^$" | tail -n 1)
        diffs=$(git diff --staged "$patch" | grep -E "^(\+|\-)" | grep -Ev "(From [a-z0-9]{32,}|\-\-\- a|\+\+\+ b|.index)")

        testver=$(echo "$diffs" | tail -n 2 | grep -ve "^$" | tail -n 1 | grep "$gitver")
        if [ "x$testver" != "x" ]; then
            diffs=$(echo "$diffs" | sed 'N;$!P;$!D;$d')
        fi

        if [ "x$diffs" == "x" ] ; then
            git reset HEAD "$patch" >/dev/null
            git checkout -- "$patch" >/dev/null
        fi
    done
}

function savePatches {
    # BungeeCord data
    waterfall=$1
    waterfall_name=$(basename "$waterfall")
    echo "Formatting patches for $waterfall_name..."

    # Cd to the patches directory
    cd "$basedir/$waterfall_name-Patches/"
    target=$2

    # Handle rebases in a smarter way
    if [ -d "$basedir/$target-Proxy/.git/rebase-apply" ]; then
        echo "REBASE DETECTED - PARTIAL SAVE"

        last=$(cat "$basedir/$target-Proxy/.git/rebase-apply/last")
        next=$(cat "$basedir/$target-Proxy/.git/rebase-apply/next")

        # Remove patches that have not been processed yet
        for i in $(seq -f "%04g" 1 1 $last)
        do
            if [ $i -lt $next ]; then
                rm ${i}-*.patch
            fi
        done
    else
        # Remove patches
        rm -rf *.patch
    fi

    # Cd to the patched fork directory
    cd "$basedir/$target-Proxy"

    # Format patches
    git format-patch --no-stat -N -o "$basedir/$waterfall_name-Patches/" upstream/upstream >/dev/null

    # Cd to the base directory
    cd "$basedir"

    # Add all patches to git
    git add -A "$basedir/$waterfall_name-Patches"

    # Cleanup the patches
    cleanupPatches "$basedir/$waterfall_name-Patches"
    echo "  Patches saved for $waterfall to $waterfall_name-Patches/"
}

savePatches "Waterfall" "Waterfall-Continued"
)
