#!/bin/sh

TIMESTAMP=$(date +%Y-%m-%d_%H:%M:%S)
COMMIT_MSG="Site updated: ${TIMESTAMP}"
jekyll build
cd _site
git add .
git commit -m "${COMMIT_MSG}"
git push origin gh-pages