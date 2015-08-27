#!/usr/bin/env bash

docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$1"
