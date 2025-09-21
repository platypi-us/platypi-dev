#!/usr/bin/env bash

multipass start cp01;
multipass start worker01;
multipass start worker02;
echo 'Run: export KUBECONFIG="$(pwd)/local.kubeconfig"';