[![Build Status](https://travis-ci.com/nikolaev-rd/pinba-engine.svg?branch=master)](https://travis-ci.com/nikolaev-rd/pinba-engine)
# [Pinba Engine](http://pinba.org) Docker Image
From Pinba site:
> Pinba is a MySQL storage engine that acts as a realtime monitoring/statistics server for PHP using MySQL as a read-only interface.

## Description

- Based on the [alpine image](https://hub.docker.com/_/alpine/) v.3.7
- [aports v.3.7.1](https://github.com/alpinelinux/aports/releases/tag/v3.7.1)
- [MariaDB v.10.1.32](https://downloads.mariadb.org/mariadb/10.1.32/)
- [Pinba Engine v.1.1.0](https://github.com/tony2001/pinba_engine/releases/tag/RELEASE_1_1_0) (latest [release v.1.2.0](https://github.com/tony2001/pinba_engine/releases/tag/RELEASE_1_1_0) doesn't work with MariaDB on Alpine - need to be compiled with same flags, that can't be done with aports).
- [Judy v.1.0.5](http://downloads.sourceforge.net/project/judy/judy/Judy-${JUDY_VERSION}/Judy-1.0.5.tar.gz)

First "dry run" of MariaDB need to create DBs, setup environment and install `libpinba_engine.so` plugin.

## [Official Docker Image](https://github.com/tony2001/pinba_engine/wiki/Docker)
Pull image from Docker Hub:
```
docker pull tony2001/pinba
```
Run:
```
docker run -d --net=host --name=pinba tony2001/pinba
```
