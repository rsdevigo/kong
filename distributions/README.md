# Building Kong distributions

Kong can be distributed to different platforms like CentOS, Debian, Ubuntu and OS X. Here you find the scripts that will start the build process and output packages.

# Requirements

The build can only be started from OS X, and requires [Docker](https://www.docker.com/) to be available on the system.

# Build

Run `/bin/bash build-package.sh -h` for help.

To start the build process for every distribution available execute:

```shell
/bin/bash build-package.sh -k KONG_TAG_OR_BRANCH -p PLATFORM
```

or you can selectively build only for specific platforms, like:

```shell
/bin/bash build-package.sh -k KONG_TAG_OR_BRANCH -p osx centos:5 debian:8
```

The output will be stored in `build-output` folder (the folder will be automatically created if not existing).

**Note:** This folder also contains a file called `build-package-script.sh` file. **Don't execute it**, it's used internally by the build.