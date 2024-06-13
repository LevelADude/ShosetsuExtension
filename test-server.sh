#!/bin/bash -x

# This file simply runs a basic http server locally.
# Requires python to be installed with the http.server module.
# Defaults to hosting on: http://localhost:8000

python -m http.server
