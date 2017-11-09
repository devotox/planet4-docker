# Docker builds for Planet4 on Google Container Registry

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/8c54834e6f1a4f3e864b5f8614347c01?branch=master)](https://www.codacy.com/app/Greenpeace/planet4-docker?utm_source=github.com&utm_medium=referral&utm_content=greenpeace/planet4-docker&utm_campaign=badger) [![CircleCI](https://circleci.com/gh/greenpeace/planet4-docker/tree/master.svg?style=shield)](https://circleci.com/gh/greenpeace/planet4-docker/tree/master)

## Description

This is a work in progress at creating a modular, re-usable Docker application architecture for the Greenpeace Planet 4 Wordpress application project.

# Quickstart

```
./build.sh -r
```

This triggers a Google Container Registry (GCR) build using the settings from `config.default`

## Building locally versus remotely
```
# Build the Docker platform suite on your local machine
./build.sh -l

# Build the Docker platform suite on gcr.io
./build.sh -r
```

```
# Perform a remote build, pull new images once complete, and show verbose build output
./build.sh -r -p -v
# or
./build.sh -rpv
```

## Subset builds
Build order can be specified on a per-project basis by the inclusion of a `build_order` file in the root of that project.
This is helpful in determining the correct build order for local or partial builds where projects have dependencies on parent images.
Subset builds can significantly speed up container rebuilds if changes are made late in the dependency list.

There are two different methods of specifying a subset build - providing a list of images to build, or by providing a starting point and appending `+` to the starting image which will build that image and any following it in the build order.

For example, with a given `build_order` file such as:
```
ubuntu
nginx-pagespeed
nginx-php-exim
wordpress
p4-onbuild
```

1. Specifically stating which containers to build:
```
# Perform a remote build of a small subset
./build.sh -r nginx-pagespeed wordpress
```
In this example, only the nginx-pagespeed and wordpress images are built.

2. Building the dependency chain from a given start point:
```
# Performs a remote build of all images in the build_order file, starting at nginx-php-exim:
./build.sh -r nginx-php-exim+
```
In this example, the `nginx-php-exim wordpress p4-onbuild` images are all built due to the trailing `+` on nginx-php-exim


## Updating build configuration variables

Containers can be modified at build time by build arguments `ARG`, or on container start with environment variables `ENV`.

To build containers with custom values, or to specify different default values, you can supply build-time command line arguments (see below) or make edits to a configuration file.

To rewrite platform variables without triggering a build, run `build.sh` without the `-l` or `-r` command line arguments:

```
./build.sh
```

This will update the local Dockerfile ENV variables such as `NGINX_VERSION` or `OPENSSL_VERSION`, but does not send a GCR build request. Since this repository is monitored for commit changes, simply updating these variables and pushing the commit will submit a new build request automagically in the CI pipeline.

## Customising the container build

See `config.default` for optional build configuration parameters. The easiest way to overwrite default parameters is to add new entries to a bash key value file, eg `config.custom`, then re-run the build with command line parameter like so: `./build.sh -c config.custom`

Note: to overwrite the default values, it's recommended to edit the short form of the variable without the leading `DEFAULT_`. For example, to change the application repository branch, use `GIT_REF`, not `DEFAULT_GIT_REF`. This ensures hierarchical resolution of variables from multiple sources, and enables the values to be configured at build and runtime, while falling back to sane default values.

Also note that not all defined variables are configurable on container start, for example changing `NGINX_VERSION` won't have any effect at container start as it's a variable used to install the infrastructure instead of control application behaviour.

### Variable resolution priority
1.  Config file custom values (optional)
2.  Environment variables (optional)
3.  Config file default values

Another valid use-case is to supply custom default values by editing, eg the `DEFAULT_MAX_UPLOAD_SIZE` and still allow runtime configuration by modifying the environment on container start.

### Specify build time parameters from a configuration file:
```
echo "GOOGLE_PROJECT_ID=greenpeace-testing" >> config.custom
./build -c config.custom

```
### Using environment variables
```
# Build the whole docker suite on GCB:
./build.sh -r

# Build only a subset of the project, with a custom source branch,
# starting from wordpress and continuing down the dependency chain
GIT_REF=dev-feature/example ./build.sh -r wordpress+
```
