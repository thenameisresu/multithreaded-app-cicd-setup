#!/bin/bash

echo "=== Namespace ==="
kubectl get ns | grep multithread-app

echo -e "\n=== Pods ==="
kubectl get pods -n multithread-app -o wide

echo -e "\n=== Services ==="
kubectl get svc -n multithread-app

echo -e "\n=== Deployments ==="
kubectl get deployments -n multithread-app

echo -e "\n=== Pod Logs ==="
kubectl logs -n multithread-app -l app=multithread-app --tail=20

echo -e "\n=== Recent Events ==="
kubectl get events -n multithread-app --sort-by='.lastTimestamp' | tail -10

echo -e "\n=== Minikube IP ==="
minikube ip

echo -e "\n=== Service URL ==="
minikube service multithread-app-service -n multithread-app --url