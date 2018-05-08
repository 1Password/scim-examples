#!/bin/bash

# this script generates a file called `scim.env` using the contents of a scimsession file in the PWD.
# This env file is used to populate the scimsession env var in the container to prevent copying the sensitive file into a container layer.

SESSION=$(cat scimsession | base64 | tr -d "\n")

echo "OPSCIM_SESSION=$SESSION" > scim.env