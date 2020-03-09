#!/bin/sh
git branch devel
git checkout devel
git add .
git commit -m "establishing devel branch"
git checkout master
git push origin devel
