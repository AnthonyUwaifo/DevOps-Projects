#!/bin/bash

#Start upp minikube
minikube start

#Verify minikube is running
minikube status

#Create Kubernetes resources from YAML manifest
kubectl apply -f nginx-manifest.yaml

#Verify resources
kubectl get pods #List pods
kubectl get deployments #List deployments
kubectl get services #List services