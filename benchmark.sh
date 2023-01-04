#!/bin/bash

DEEP="deep-image-96-angular"
GIST="gist-960-euclidean"
GLOVE="glove-100-angular"
PREPARE="--prepare"
DATASET="gist-960-euclidean"
CONCURRENCY=1
ALL_CONCURRENCY=false
SCRIPTS_DIR=$(dirname "$0")
HOST=""

while getopts "d:c:s:aih" arg; do
    case $arg in
        d)
            DATASET=$OPTARG
            CORRECT_DATASET=false
            for dataset in $DEEP $GIST $GLOVE; do
                if [ $dataset = $DATASET ]; then
                    CORRECT_DATASET=true
                    break
                fi
            done
            if [ $CORRECT_DATASET = false ]; then
                echo "ERROR! Dataset ${DATASET} is not supported."
            fi ;;
        c)
            CONCURRENCY=$OPTARG ;;
        s)
            HOST=$OPTARG ;;
        a)
            ALL_CONCURRENCY=true ;;
        i)
            PREPARE="--no-prepare" ;;
        h) # help
            echo "

parameter:
-d: dataset, only deep-image-96-angular, gist-960-euclidean and glove-100-angular are supported now(default: deep-image-96-angular)
-c: concurrency to benchmark, only 1, 2, 4, 8, 100 are supported now(default: 1)
-s: server host
-a: run all concurrencies(default: false)
-i: ignore data preparation(default: false)
-h: help

usage:
./benchmark.sh -d \${DATA_SET} -c \${CONCURRENCY} -s \${HOST} [-a] [-i]
            "
            exit 0 ;;
        ?)
            echo "ERROR! unknown argument"
            exit 1
            ;;
    esac
done

MAIN_PATH=$SCRIPTS_DIR/main.py
DATASET_NAME=""

case $DATASET in
    $DEEP)
        DATASET_NAME="deep_image_96" ;;
    $GIST)
        DATASET_NAME="gist_960" ;;
    $GLOVE)
        DATASET_NAME="glove_100" ;;
esac
python3 $MAIN_PATH recall --host $HOST --engine milvus --dataset-name $DATASET --config-name milvus_${DATASET_NAME}_recall_95_recall $PREPARE 
CONCURRENCY_CONFIG_PREFIX=milvus_${DATASET_NAME}_recall_95_concurrency

if [ $ALL_CONCURRENCY = true ]; then
    # for concurrency in 1 2 4 8 100; do
    python3 $MAIN_PATH concurrency --host $HOST --engine milvus --config-name ${CONCURRENCY_CONFIG_PREFIX}_*
    # done
else
    python3 $MAIN_PATH concurrency --host $HOST --engine milvus --config-name ${CONCURRENCY_CONFIG_PREFIX}_${CONCURRENCY}
fi
