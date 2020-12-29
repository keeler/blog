---
title: "Concatenating MP3 Files"
date: 2020-12-29T02:12:02Z
tags:
  - Linux
  - MP3
  - ffmpeg
  - Bash
---

Smoosh a bunch of MP3 files into one for easier copying around.

<!--more-->

## Background

I [previously wrote about]({{<relref "Linux-to-Apple-File-Transfer.md">}}) how I get audiobook MP3 files from my Linux machine onto my iPhone without iTunes.
However, using that workaround is **extremely tedious** when there are dozens of MP3 files to copy manually.
So, with the help of [this AskUbuntu thread](https://askubuntu.com/questions/20507/concatenating-several-mp3-files-into-one-mp3) I put together a Bash script to concatenate a directory full of MP3 files into a single MP3 file for the sake of minimizing the number of files I need to download through Safari.

As you may have guessed, it's not as simple as doing `cat *.mp3 > output.mp3` because:
1. MP3 files have metadata at the beginning and end of the file which shouldn't be in the middle of a well-formatted output MP3. Naively concatenating them together will result in garbage data in the middle of the concatenated file.
2. Using a glob this way is naive about the order in which the mp3 files should get concatenated together. Since in my case these are the parts of a book, sequence matters a lot.


## How to Use the Script

I named this bash script `cat_mp3s.sh` and put it in my `$PATH` for convenience.

Here's an example of how I use it.
The `-i` option points to the directory of MP3s, and the `-o` option determines what the output filename will be.
Before actually concatenating the files it shows what order they'll be concatenated in and let's you confirm that's the order you want.
If not, you'll need to rename the files so they sort appropriately.

```
$ cat_mp3s.sh -i "~/audiobooks/Neuromancer -o Neuromancer.mp3
Found 12 MP3 files in '/home/keeler/audiobooks/Neuromancer'
They will be concatenated in this order:
########################################
1-12 Neuromancer - William Gibson.mp3
2-12 Neuromancer - William Gibson.mp3
3-12 Neuromancer - William Gibson.mp3
4-12 Neuromancer - William Gibson.mp3
5-12 Neuromancer - William Gibson.mp3
6-12 Neuromancer - William Gibson.mp3
7-12 Neuromancer - William Gibson.mp3
8-12 Neuromancer - William Gibson.mp3
9-12 Neuromancer - William Gibson.mp3
10-12 Neuromancer - William Gibson.mp3
11-12 Neuromancer - William Gibson.mp3
12-12 Neuromancer - William Gibson.mp3
Is this order OK? (y/n) y
...........................
...lots of ffmpeg output...
...........................
Wrote 'Neuromancer.mp3' in '/home/krussell/audiobooks/Neuromancer'
```

### The Script

Here's the script in its entirety. Most of it is helper stuff like options, checks, a confirm prompt, etc.

The main pieces of the script are the following (which are highlighted in the script below):

1. A `find` + `sort` used to discover and correctly order the mp3 files.
2. An invocation of `ffmpeg` used to concatenate the mp3s.


{{<highlight bash "linenos=table,hl_lines=49-53 67">}}
#!/usr/bin/env bash
# Concatenate mp3 files in a directory into a single mp3.

# Default options
DIR=$(pwd)
OUT_FILE="output.mp3"

help () {
  self=$(basename $0)
  echo "Concatenate mp3 files in a directory into a single mp3."
  echo "Usage: $self -i /path/to/mp3s -o output_name.mp3"
  echo "  -i, --input-dir    Path to directory with mp3s in it."
  echo "                     Defaults to current directory."
  echo "  -o, --output-file  Name of concatenated mp3 file."
  echo "                     Must have .mp3 extension."
  echo "                     Defaults to 'output.mp3'."
}

# Parse command line options.
while [[ $# -gt 0 ]]  # While there are more than 0 arguments to parse
do
  OPTION="$1"
  VALUE="$2"

  case $OPTION in
    -h|--help)
      help; exit 1
    ;;
    -i|--input-dir)
      DIR=$VALUE; shift; shift
    ;;
    -o|--output-file)
      OUT_FILE=$VALUE; shift; shift
    ;;
    *)
      echo "Unrecognized option '$OPTION'"; help; exit 1
    ;;
  esac
done

# Check output file has proper extension.
if [[ "${OUT_FILE: -4}" != ".mp3" ]]
then
  echo "Output filename '$OUT_FILE' must have extension '.mp3'"
  exit 2
fi

# Find and sort mp3 files.
FILES=$(find "$DIR" -maxdepth 1 -iname '*.mp3' \
  | sort -V \
  | tr '\n' '|' \
  | sed -E 's/\|$//'
)
NUM_FILES=$(echo $FILES | tr '|' '\n' | wc -l)

echo "Found $NUM_FILES MP3 files in '$DIR'"
echo "They will be concatenated in this order:"
echo "########################################"
echo $FILES | tr '|' '\n' | xargs -I% basename %

# Confirm before concatenating.
read -p "Is this order OK? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo "Concatenating files..."
  ( cd "$DIR" && ffmpeg -i "concat:$FILES" -acodec copy "$OUT_FILE" )
  echo "Wrote '$OUT_FILE' in '$DIR'"
fi
{{</highlight>}}

