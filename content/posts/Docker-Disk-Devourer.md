---
title: "Docker: Disk Devourer"
date: 2020-11-29T17:53:33Z
draft: false
tags:
  - docker
  - cronjob
---
My laptop's disk was mysteriously filling up: turns out it was docker.

<!--more-->

## What Happened?

When your disk fills up, things get weird and your computer starts to whine.
I was getting alerts saying my disk was nearly full, and ignored them until I literally could not work anymore: Git started to break down with the error `fatal: Unable to write new index file`.
Thus blocked, and having no idea what could be consuming my laptop's disk space, I ran this command to find out:

{{< highlight bash >}}
sudo du -h / | sort --human-numeric-sort --reverse | head
{{</highlight>}}

After a short while the results came back and fortunately the culprit was obvious: docker volumes.
I hadn't been cleaning up after myself when using docker all day every day.

{{< highlight bash >}}
205G  /
195G  /var
157G  /var/lib
153G  /var/lib/docker
100G  /var/lib/docker/volumes
53G   /var/lib/docker/overlay2
...
{{</highlight>}}

## How I Solved It

Docker volumes will over time consume a lot of disk and don't necessarily get cleaned up when you remove images or containers.
With a little [peek at the docs](https://docs.docker.com/engine/reference/commandline/system_prune/) I found I could run this command to clear out all that docker volume cruft:

{{< highlight bash >}}
docker system prune -f --volumes
{{</highlight>}}

However, that command only does the cleanup once, merely extending the clock on a ticking time-bomb of disk-devouring.
So, my simple fix was to add a cronjob to run this cleanup command once a week.
In other words, I ran `crontab -e` and add the following lines (with the correct email, of course).

{{< highlight bash >}}
SHELL=/bin/bash
MAILTO=myname@email.com

# Prune unused docker cruft once a week.
0 2 * * 1 docker system prune -af --volumes
{{</highlight>}}

So, cron does the cleanup and sends me an email at around [2AM every Monday](https://crontab.guru/#0_2_*_*_1) detailing what it cleaned up.
Note that I added the `-a` option which also deletes images not tied to at least one container.
In my case I have a decently-fast internet connection and regularly pull new images anyway, so I actually prefer this to keep the cruft to the absolute minimum.
It has been a few months and this solution has worked brilliantly.
