#!/usr/bin/env bash

multipass stop cp01;
multipass stop worker01;
multipass stop worker02;
echo 'Run: unset KUBECONFIG';