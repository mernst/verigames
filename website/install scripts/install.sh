#!/bin/sh

#install ant - might use it?
yum install ant

#install php
yum install php

#install dot
cp graphviz-rhel.repo /etc/yum.repos.d/graphviz-rhel.repo
yum install 'graphviz*'

#build java parts

#copy stuff to website location

