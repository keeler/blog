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

These days disks on personal computers are so large that I usually just don't notice how full mine is or not because it typically doesn't impact my everyday work. That being said, I do try to keep tabs on what processes are running, including how much data they download or write to disk. In this situation, though, I had literally no idea what was consuming all that space, so I took a look at all of root.

{{< highlight bash >}}
sudo du -h / | sort --human-numeric-sort --reverse | head
{{</highlight>}}

Fortunately for me, the search was a short one. The `du` command immediately fingered the culprit: docker volumes. In my case it was me not cleaning up after myself when using docker day-in-and-day out.

{{< highlight bash >}}
205G  /
195G  /var
157G  /var/lib
153G  /var/lib/docker
100G  /var/lib/docker/volumes
53G   /var/lib/docker/overlay2
...
{{</highlight>}}

Docker volumes are marvelously handy but over time consume a lot of disk and don't necessarily get cleaned up when you remove images or containers. With a little [peek at the docs](https://docs.docker.com/engine/reference/commandline/system_prune/) I found I could run this command to clear out all that docker volume cruft.

{{< highlight bash >}}
docker system prune -af --volumes
{{</highlight>}}

Note that this command will also delete images, too! In my case I have a decently-fast internet connection and regularly pull new images anyway, so that didn't bother me so much.

However, that command only does the cleanup once, merely extending the clock on what is still a ticking time-bomb of disk-devouring. So, my simple fix was to add a cronjob to run this cleanup command once a week. In other words, I ran `crontab -e` and add the following lines (with the correct shell and email, of course).

{{< highlight bash >}}
SHELL=/bin/bash
MAILTO=myname@email.com

# Prune unused docker cruft once a week.
0 2 * * 1 docker system prune -af --volumes
{{</highlight>}}

So, cron does the cleanup and sends me an email at around [2AM every Monday](https://crontab.guru/#0_2_*_*_1) detailing what it cleaned up. It has been a few months and this solution has worked brilliantly.
