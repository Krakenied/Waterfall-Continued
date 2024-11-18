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

function updateWaterfallPatch {
    # Waterfall data
    waterfall=$2
    waterfall_name=$(basename "$waterfall")

    # Branch to use
    branch=$3

    # Ensure that the branch is still valid
    cd "$basedir/$waterfall"
    git fetch
    git branch -f upstream "$branch" >/dev/null

    # Remove patches we don't want to maintain
    #rm "BungeeCord-Patches/0046-OSX-native-zlib-and-crypto.patch"

    # Apply Waterfall patches
    echo "Applying $waterfall_name patches..."
    ./waterfall p >/dev/null 2>&1

    # Get the patches count
    patches=$(find . -name "*.patch" -type f | wc -l)
    echo "Squashing $patches commits..."

    # Squash all the patches commits into a single Waterfall changes commit
    cd "$basedir/$waterfall/$waterfall_name-Proxy"
    git reset --soft HEAD~$patches
    git commit -m "Waterfall changes

MIT License

Copyright (c) 2015-2016 Waterfall Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE." >/dev/null 2>&1

    # Rebuild patches to get the squashed Waterfall changes patch
    echo "Constructing $waterfall_name squashed patch..."
    cd "$basedir/$waterfall"
    ./waterfall rb >/dev/null 2>&1

    # BungeeCord data
    bungee=$1
    bungee_name=$(basename "$bungee")

    # Create patches directory if does not exist
    if [ ! -d "$basedir/$waterfall_name-Patches" ]; then
        mkdir -p "$basedir/$waterfall_name-Patches"
    fi

    # Move squashed patch to the new fork directory
    cp -f "$basedir/$waterfall/$bungee_name-Patches/0001-Waterfall-changes.patch" "$basedir/$waterfall_name-Patches/0001-Waterfall-changes.patch"

    # Reset Waterfall branch
    echo "Done! Resetting $waterfall_name upstream..."
    cd "$basedir/$waterfall"
    git reset --hard >/dev/null 2>&1
}

# Disable GPG signing before AM, slows things down and doesn't play nicely.
# There is also zero rational or logical reason to do so for these sub-repo AMs.
# Calm down kids, it's re-enabled (if needed) immediately after, pass or fail.
if [[ "$gpgsign" == "true" ]]; then
    echo "Temporarily disabling GPG signing"
    git config --global commit.gpgsign false
fi

updateWaterfallPatch upstreams/BungeeCord upstreams/Waterfall HEAD

enableCommitSigningIfNeeded
