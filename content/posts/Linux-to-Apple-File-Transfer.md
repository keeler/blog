---
title: "Linux to Apple File Transfer"
date: 2020-12-28T02:12:02Z
tags:
  - Linux
  - iPhone
  - Apple
  - Hack
  - Workaround
  - Bash
---

A workaround to transfer files from Linux devices to Apple devices.
<!--more-->

## Background

I wanted to transfer some audiobook mp3s from my laptop to my iPhone.
Unfortunately for me, simply plugging in the iPhone via USB isn't really an option: this requires iTunes, but my laptop runs Linux and there's no iTunes client for Linux.
While `wine` is an option I didn't want to go that route because it has been difficult and finnicky for me in my previous experience with it.
(Maybe it's gotten better since then, but ¯\\_(ツ)\_/¯)

## The Workaround

The workaround is relatively simple:
1. Put the laptop and iPhone on the same WiFi network.
1. Run a web server on the laptop.
1. Navigate to the web server in Safari on the iPhone to download the mp3s.

Caveat: this is an insecure, quick & dirty solution.
My WiFi has a decent WPA2 key and I kill the server immediately after I'm done transferring files so I'm not too worried.

### Details

1. Put your computer and iPhone to the same network. For example, connect both to the same WiFi network.
1. Start an HTTP server in the directory you want to share.
    ```
    $ cd ~/audiobooks
    $ python3 -m http.server 54321
    Serving HTTP on 0.0.0.0 port 54321 (http://0.0.0.0:54321/) ...
    ```
1. Figure out your computer's IP.
    ```
    $ hostname -I | awk '{print $1}'
    10.0.0.129
    ```
1. Open `http://10.0.0.129:54321` in Safari on your Apple device (replace IP address as apporpriate). You'll see a listing of files in the directory you started the HTTP server in.
1. Download all the files you want. You can play them from "Downloads" on the iPhone.

**See also:** [Concatenating MP3 Files]({{<relref "Concatenating-MP3-Files.md">}}).
Audiobooks often get split into many smaller MP3s; copying each of these manually through a browser is tedious!
That post shows a way to merge MP3 files together so you only need to download a single MP3 instead.

### Automating It

I made a small bash script for this which I added to my $PATH for convenience.

{{<highlight bash "linenos=table">}}
#!/usr/bin/env bash
# Open an HTTP server from the given directory.

DIR=${1:-$(pwd)}
PORT=${2:-54321}

IP=$(hostname -I | awk '{print $1}')
HOST="http://$IP:$PORT"

MSG="Serving '$DIR' at $HOST..."
LEN=$(echo $MSG | wc -m)
SEP=$(printf %${LEN}s | tr ' ' '#')
echo $SEP
echo $MSG
echo $SEP

( cd "$DIR" && python3 -m http.server $PORT )
{{</highlight>}}

Here it is in action. Omitting the directory serves whatever the current directory is.
```
$ serve.sh ~/audiobooks
################################################################
Serving '/home/keeler/audiobooks' at http://10.0.0.129:54321...
################################################################
Serving HTTP on 0.0.0.0 port 54321 (http://0.0.0.0:54321/) ...
```
