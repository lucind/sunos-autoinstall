#!/bin/bash

installadm create-manifest -n default-sparc -f manifest/frith.xml -c mac=0:14:4f:ae:1b:7c
installadm create-manifest -n default-sparc -f manifest/inle.xml -c mac=0:14:4f:e5:cd:9c
installadm create-profile -n default-sparc -f sc_profiles/frith.xml -c mac=0:14:4f:ae:1b:7c
installadm create-profile -n default-sparc -f sc_profiles/inle.xml -c mac=0:14:4f:e5:cd:9c
installadm list -cmp
