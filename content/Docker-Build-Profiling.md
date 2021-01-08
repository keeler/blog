---
title: "Docker Build Profiling"
date: 2021-01-06T07:32:21Z
tags:
  - docker
  - jaeger
  - buildkit
  - opentracing
---

Figure out why your docker build is slow.

<!--more-->

# Background

I ran into a case where building a docker image was taking too long for my liking.
However, vanilla docker doesn't give you any good way to profile the build process to figure out exactly what is so slow.

Buildkit to the rescue!
[This buildkit PR](https://github.com/moby/buildkit/pull/255) added a way to hook up Jaeger to buildkit.
In other words, with a little bit of setup, you can build a docker image with buildkit and get a nice breakdown (i.e. profile) of the build time.

![Jaeger running locally](/images/posts/docker-build-profiling/jaeger.jpg)

# General Idea

Most of the complicated bits are built into the [keelerrussell/docker-build-profiler](https://hub.docker.com/r/keelerrussell/docker-build-profiler) docker image.
It's just a [docker-in-docker](https://hub.docker.com/_/docker) image with buildkit and Jaeger built into it for you.
Starting the image starts the docker daemon, Jaeger, and the buildkit daemon automatically in a container.

With this image running as a container, you can repeat these steps iteratively:
1. Copy files into the container (e.g. Dockerfile + build assets like source files).
1. Build them with buildkit in the container.
1. View profiling information in your web browser, or make REST request to get it programmatically.

# Demo

**Step 1: Start The Container**

Start the image as a container:

```bash
docker run -it -d --privileged \
  --name build-profiler \
  -p16686:16686 \
  keelerrussell/docker-build-profiler
```

Note that it is named `build-profiler` and that port 16686 is opened.
The name is arbitrary and just for convenience, but that port is not arbitrary.
It's the port allowing access to Jaeger outside the container so you can get that sweet, sweet profiling information. :open_mouth:

*At this point, you can leave the container running and repeat the following steps as needed while you're experimenting with tweaks to your Dockerfile.*

**Step 2: Copy Your Files Into the Container**

For the sake of a concrete example, you can run the the lines in this footnote[^1] in a terminal to download [this Flask app](https://github.com/docker/labs/tree/9fd92affd4f02d31fa0dc674d61e9ab18b61ec4f/beginner/flask-app) from the canonical Docker examples.
Otherwise, just use your own project.

Make a directory in the running `build-profiler` container and copy your Dockerfile and other associated sources, assets, etc. into the container.

```bash
cd ~/flask_app
docker exec -it build-profiler mkdir demo
docker cp . build-profiler:/workspace/demo
```

Note that this creates the `demo` folder in the container at `/workspace/demo`; this is because the image has WORKDIR set to `/workspace`.

**Step 3: Build Using `buildkit`**

Next, build your docker image inside the `build-profiler` container using buildkit.

```bash
docker exec -it build-profiler buildctl build \
  --frontend=dockerfile.v0 \
  --local context=demo \
  --local dockerfile=demo
```

**Step 4: Get Traces From Jaeger**

You can use either the web UI for a visual representation, or a REST request for programmatic access.

1. For the web UI, go to [http://localhost:16686](http://localhost:16686) in your browser. Choose "buildctl" in the `Service` dropdown, click the `Find Traces` button, and choose the most recent one.
1. You can also use the [REST API](https://www.jaegertracing.io/docs/1.21/apis/#http-json-internal). It works but is undocumented as of Jan 2021 and subject to change.
    ```bash
    curl -s http://localhost:16686/api/traces\?service\=buildctl | jq '.'
    ```

# How it Works

Be forwarned, this is docker-ception; docker-in-docker with extra docker images hacked in.
Seeing the source code may help you follow along: https://github.com/keeler/docker-build-profiler

**Why is this a docker image at all?**

I could just install the buildkit daemon locally, right?
Well, no, not really; I didn't like running it as root and the "rootless" setup didn't work for me.
Furthermore, `buildkitd` is only available on Linux (as of Jan 2021) and I felt a more cross-platform solution would be more appropriate.
So instead I built this docker-based solution so I can run it without root privileges.
Though I haven't tried it, it probably also doesn't require Linux, either.

**OK, so how does the image work?**

As mentioned above, this is a docker image which adds buildkit and Jaeger into a pre-existing docker-in-docker image from dockerhub.

When you run the `docker-build-profiler` image, it first calls the entrypoint of its parent docker-in-docker image to start the docker daemon *inside the container*.
After the docker daemon is running, it runs `docker load` to load a `jaeger-all-in-one` image built into the container
(this is kind of weird but bear with me, I'll elaborate momentarily)
then runs that image with this command yanked more-or-less directly from the [buildkit PR](https://github.com/moby/buildkit/pull/255) mentioned earlier:

```bash
docker run -d -p6831:6831/udp -p16686:16686 $JAEGER_IMAGE
```

Finally, it runs the buildkit daemon and is ready for you to use.

**Now, what is that weird `docker load` bit about?**

You may have percieved that I could just do a `docker pull` to get the `jaeger-all-in-one` image at runtime instead.
However, I didn't like that approach because I occasionally work while commuting on a train (not during Covid-19 but past me did and future me will).
Since the train can have spotty internet service, such an approach is a non-starter for me.
As a matter of personal preference, I prefer solutions which minimize internet bandwidth requirements as much as possible.

So instead, my solution is a little more complicated but doesn't require internet access (after you've pulled the `docker-build-profiler` image locally, that is).
Before ever running `docker build`, I first run `docker save` to turn the `jaeger-all-in-one` image into a .tar file then *immediately unpack that tar file* into a plain ol' folder called `jaeger/`.
That `jaeger/` folder gets added to `docker-build-profiler` image and gets gzipped up at build-time; this circumvents "magic number" errors from the `tar` command caused by differences between the tar version running on the machine which ran `docker save` and the tar version built into `alpine` which docker-in-docker is based on.

Of course, because this is weird and error-prone to do manually, I automated it with a Makefile so all you need to do is run `make` or `make docker` in the repo.

[^1]: Commands you can use to download the demo files locally:
{{<highlight bash "linenos=table">}}
cd ~
mkdir flask_app
cd flask_app

GITHUB=https://raw.githubusercontent.com/
COMMIT=9fd92affd4f02d31fa0dc674d61e9ab18b61ec4f
BASE_URL=$GITHUB/docker/labs/$COMMIT/beginner/flask-app

curl -L $BASE_URL/requirements.txt --output requirements.txt
curl -L $BASE_URL/app.py --output app.py
curl -L $BASE_URL/Dockerfile --output Dockerfile
mkdir -p templates
curl -L $BASE_URL/index.html --output templates/index.html
{{</highlight>}}


