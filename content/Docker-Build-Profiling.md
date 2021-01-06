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

# How To Do It

First of all,  to do any of this requires `buildkitd` which is only available on Linux (as of Jan 2021).
However, I didn't like the fact that I need to run it as root and besides even if I was OK with that I couldn't get it to work, anyway (neither was the rootless mode).
So instead, I built a custom image based on [docker-in-docker](https://hub.docker.com/_/docker) into which I install buildkit.
As such it may work outside Linux but I haven't tried this so no guarantees.

### General Idea

The basic idea is to build a custom docker-in-docker image with buildkit installed.
With that custom image running, then start Jaeger and the buildkit daemon inside that container.
Then you can repeat these steps iteratively:
1. Copy files into the container (Dockerfile + build context)
1. Build them with buildkit in the container.
1. Outside the container view/extract the profiling information.

### Set Up

Here's the Dockerfile for the custom docker-in-docker image:
{{<highlight Dockerfile "linenos=table">}}
FROM docker:dind

WORKDIR /workspace

ENV BUILDKIT_VERSION=0.8.0
ENV BUILDKIT_ARCHIVE=buildkit-v$BUILDKIT_VERSION.linux-amd64.tar.gz

# Download and install buildkit
RUN wget https://github.com/moby/buildkit/releases/download/v$BUILDKIT_VERSION/$BUILDKIT_ARCHIVE
RUN tar xvzf $BUILDKIT_ARCHIVE \
 && mkdir /bin/buildkit \
 && mv ./bin/* /bin/buildkit \
 && rm -rf ./bin $BUILDKIT_ARCHIVE

# Set up Jaeger and buildkit daemon to run.
# See https://github.com/moby/buildkit/pull/255
ENV JAEGER_IMAGE=jaegertracing/all-in-one:latest
ENV JAEGER_TRACE=0.0.0.0:6831

RUN printf '#!/bin/sh\n\
docker run -d -p6831:6831/udp -p16686:16686 $JAEGER_IMAGE\n\
/bin/buildkit/buildkitd &'\
>> init.sh
RUN chmod +x init.sh
{{</highlight>}}

Save that Dockerfile as `Dockerfile-profiler`. Now to build it:

```bash
docker build -t docker-build-profiler -f Dockerfile-profiler .
```

Once the build is complete, start a container with the image:

```bash
docker run --name build-profiler -it -d --privileged -p16686:16686 docker-build-profiler
```

The flags are basically the same as are recommended in the docker-in-docker docs, except the opening of port 16686.
This allows connecting to Jaeger outside of docker to get that sweet, sweet profiling information. :open_mouth:

Now, we need to start Jaeger and the buildkit daemon.
I built a helper script into the image to do this:

```bash
docker exec -it build-profiler ./init.sh
```

Alternatively you could run:
```bash
docker exec -it build-profiler docker run -d -p6831:6831/udp -p16686:16686 $JAEGER_IMAGE
docker exec -it build-profiler /bin/buildkit/buildkitd &
```

### Getting Profiling Information

With the setup complete, you can leave the container running and repeat the following steps as much as you want.
Basically, you'll copy your Docker build context into the container, build your image, and then extract or view auto-generated profiling stats.
I've been making a folder in the container per project I'm working on.

1. Make a folder in the container's `/workspace` path to build your image in.
    ```bash
    docker exec -it build-profiler mkdir demo
    ```
1. Copy in your Dockerfile and build context.
    ```bash
    docker cp Dockerfile build-profiler:/workspace/demo
    docker cp <other files> build-profiler:/workspace/demo
    ```
1. Build the files with buildkit.
    ```bash
    docker exec -it build-profiler /bin/buildkit/buildctl build \
        --frontend=dockerfile.v0 \
        --local context=demo \
        --local dockerfile=demo
    ```
1. Get the traces from Jaeger. Use the web UI for a visual representation, or use `curl` for CLI access.
    1. For the web UI, go to `http://localhost:16686` in your browser. Choose "buildctl" in the `Service` dropdown, click the `Find Traces` button, and choose the most recent one.
    1. For curl, you can use the [REST API](https://www.jaegertracing.io/docs/1.21/apis/#http-json-internal). It works but is undocumented as of Jan 2021 and subject to change.
        ```bash
        curl -s http://localhost:16686/api/traces\?service\=buildctl | jq '.'
        ```

