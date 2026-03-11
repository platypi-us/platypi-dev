#!/usr/bin/env bash

multipass start cp01;
multipass start worker01;
multipass start worker02;
multipass start worker03;
echo 'Run: export KUBECONFIG="$(pwd)/local.kubeconfig"';