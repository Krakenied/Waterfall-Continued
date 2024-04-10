#!/usr/bin/env bash

PS1="$"
basedir="$(cd "$1" && pwd -P)"
gpgsign="$(git config commit.gpgsign || echo "false")"

function enableCommitSigningIfNeeded {
    if [[ "$gpgsign" == "true" ]]; then
        echo "Re-enabling GPG signing"
        # Yes, this has to be global
        git config --global commit.gpgsign true
    fi
}

function applyPatches {
    # BungeeCord data
    bungee=$1
    bungee_name=$(basename "$bungee")

    # Branch to use
    branch=$4

    # Ensure that the branch is still valid
    cd "$basedir/$bungee"
    git fetch
    git branch -f upstream "$branch" >/dev/null

    # Cd to the base directory
    cd "$basedir"
    target=$3

    # Create patched fork directory if does not exist
    if [ ! -d "$basedir/$target-Proxy" ]; then
        git clone "$bungee" "$target-Proxy"
    fi

    # Cd to the patched fork directory
    cd "$basedir/$target-Proxy"

    # Reset fork to the upstream branch
    echo "Resetting $target-Proxy to $bungee_name..."
    git remote rm upstream >/dev/null 2>&1
    git remote add upstream "$basedir/$bungee" >/dev/null 2>&1
    git checkout master 2>/dev/null || git checkout -b master
    git fetch upstream >/dev/null 2>&1
    git reset --hard upstream/upstream

    # Waterfall data
    waterfall=$2
    waterfall_name=$(basename "$waterfall")

    # Apply patches
    echo "  Applying patches to $target-Proxy..."

    git am --abort >/dev/null 2>&1
    git am --3way --ignore-whitespace "$basedir/$waterfall_name-Patches/"*.patch

    if [ "$?" != "0" ]; then
        echo "  Something did not apply cleanly to $target-Proxy."
        echo "  Please review above details and finish the apply then"
        echo "  save the changes with rebuildPatches.sh."
        enableCommitSigningIfNeeded
        exit 1
    else
        echo "  Patches applied cleanly to $target-Proxy."
    fi
}

# Disable GPG signing before AM, slows things down and doesn't play nicely.
# There is also zero rational or logical reason to do so for these sub-repo AMs.
# Calm down kids, it's re-enabled (if needed) immediately after, pass or fail.
if [[ "$gpgsign" == "true" ]]; then
    echo "Temporarily disabling GPG signing"
    git config --global commit.gpgsign false
fi

applyPatches upstreams/BungeeCord upstreams/Waterfall Waterfall-Continued HEAD

enableCommitSigningIfNeeded
