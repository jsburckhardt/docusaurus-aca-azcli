#!/bin/bash

nextReleaseVersion="$1"

RELEASE=${nextReleaseVersion} make ci-package deploy
