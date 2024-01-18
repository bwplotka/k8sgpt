#!/usr/bin/env bash

# Cleaning up cluster.

../bin/k8sgpt auth remove --backends google
kubectl delete namespace demo
kubectl create namespace demo
