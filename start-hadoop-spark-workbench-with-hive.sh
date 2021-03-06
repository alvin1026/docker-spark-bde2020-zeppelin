#!/bin/bash

echo "Usage: $(basename $0) <docker_file> <base_dir_for_data>"

FORCE_RECREATE=1
BUILD=0

#### ---- Start docker service ----
sudo service docker start

#### ---- Dockerfile to use ----
DOCKER_FILE=${1:-docker-compose-hive.yml}

#### ---- Local host persistent directories to use ----
BASE_DATA_DIR=${2:-${HOME}/data-docker/docker-spark-bde2020-zeppelin}
DATA_DIR=${BASE_DATA_DIR}/data
NOTEBOOK_DIR=${BASE_DATA_DIR}/notebook
mkdir -p ${DATA_DIR}/namenode
mkdir -p ${DATA_DIR}/datanode
mkdir -p ${NOTEBOOK_DIR}
sudo chown -R $USER:$USER ${BASE_DATA_DIR}
echo "DATA_DIR=${DATA_DIR}"
echo "NOTEBOOK_DIR=${NOTEBOOK_DIR}"

#### ---- Create docker network ----
DOCKER_NETWORK=spark-net
docker network create -d bridge ${DOCKER_NETWORK}

#### ---- some issue with restarting spark-notebook
#### ---- workaround: remove old instance first
docker rm -f spark-notebook

#### ---- Starting all services ----
DOCKER_CMD="docker-compose -f ${DOCKER_FILE} up -d --remove-orphans"
#if [ $FORCE_RECREATE -eq 0 ]; then
#    DOCKER_CMD="${DOCKER_COMD} --no-recreate"
#else
#    DOCKER_CMD="${DOCKER_COMD} --force-recreate"
#fi
#if [ $BUILD -eq 0 ]; then
#    DOCKER_CMD="${DOCKER_COMD} --no-build"
#else
#    DOCKER_CMD="${DOCKER_COMD} --build"
#fi
CONTAINER_LIST="\
    namenode datanode \
    hive-metastore-postgresql hive-metastore hive-server hive-server \
    spark-master \
    spark-worker \
    wait/10 \
    spark-notebook \
    hue \
    zeppelin"
for c in $CONTAINER_LIST; do
    if [[ "$c" =~ wait ]]; then
        wait_sec=$(basename $c)
        echo "... waiting for ${wait_sec} seconds ..."
        sleep ${wait_sec}
    else
        ${DOCKER_CMD} $c
    fi
done

#### ---- Print Services ports -----
my_ip=`ip route get 1|awk '{print $NF;exit}'`
echo "Namenode: http://${my_ip}:50070"
echo "Datanode: http://${my_ip}:50075"
echo "Spark-master: http://${my_ip}:8080"
echo "Spark-notebook: http://${my_ip}:9001"
echo "Hue (HDFS Filebrowser): http://${my_ip}:8088/home"
echo "Zeppelin: http://${my_ip}:19090"
