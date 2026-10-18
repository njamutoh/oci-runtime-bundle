#!/usr/bin/env bash

mkdir -p bundle/rootfs
sudo chown root:root bundle/rootfs

sudo pacstrap -c bundle/rootfs base python

sudo mkdir -p bundle/rootfs/app
sudo cp app.py bundle/rootfs/app/
