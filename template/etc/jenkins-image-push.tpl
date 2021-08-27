#!/bin/sh

source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env

path='images'
docker_images=()

## 변수
count=`ls images | grep tar | wc -l`
image_list=`ls images | grep tar | awk '{print $1}'`

## 함수
function docker_load(){
        docker load -i $path/$1 -q | awk '{ split($0, arr, " "); print arr[3]}'
}

function docker_push(){
        docker tag $1 ${HARBOR_URL}/library/$1
        docker push ${HARBOR_URL}/library/$1
}

## Main

for i in ${image_list[@]}
do
        docker_images+=(`docker_load $i`)
done
for i in ${docker_images[@]}
do
        docker_push $i
        echo ""$i" push complete!!"
done
echo "############ "$PWD" -> docker images "$count" upload complete ############"