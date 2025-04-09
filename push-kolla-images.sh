#!/bin/bash

TAG=19.4.0
LOCAL_REGISTRY=10.2.0.119:4000
Set=2024.2
# Get all Kolla images with the specified tag
images=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep "kolla" | grep "$TAG")

for image in $images; do
    # Extract image name
    name=$(echo $image | cut -d '/' -f2 | cut -d ':' -f1)

    # Tag it for the local registry
    docker tag "$image" "$LOCAL_REGISTRY/mahesh.kolla/$name:$Set"
    
    echo "Pushing $LOCAL_REGISTRY/mahesh.kolla/$name:$Set"
    docker push "$LOCAL_REGISTRY/mahesh.kolla/$name:$Set"
done
