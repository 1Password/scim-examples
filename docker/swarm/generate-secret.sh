#!/bin/bash

# this script creates a Docker Swarm secret using the scimsession file in the PWD

cat ./scimsession | docker secret create scimsession -