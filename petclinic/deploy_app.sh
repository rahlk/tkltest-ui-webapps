#!/usr/bin/env bash

WORK_DIR=$PWD
# CALL_TRACING_AGENT_PATH=/path/to/agent.jar
CALL_TRACING_AGENT_PATH=/home/rkrsn/workspace/tackle/tackle-axe/call-tracing-agent/build/libs/ctaagent-1.0-SNAPSHOT.jar
DOCKER_IMAGE_NAME_REST="springcommunity/spring-petclinic-rest"
DOCKER_IMAGE_NAME_ANGULAR="spring-petclinic-angular:latest"
DOCKER_CONTAINER_NAME_REST="petclinic-rest"
DOCKER_CONTAINER_NAME_ANGULAR="petclinic-angular"

usage() {
    echo
    echo "Usage: $0 [command]"
    echo "  build                 build app image"
    echo "  start [-b/--build]    start app container, optionally building the image"
    echo "  stop                  stop app container"
    echo
}

stop() {
    echo "=> Stopping and removing existing $DOCKER_CONTAINER_NAME_ANGULAR container"
    docker rm -f $DOCKER_CONTAINER_NAME_ANGULAR
    echo "=> Stopping and $DOCKER_CONTAINER_NAME_REST"
    kill -9 $(jps | grep "spring-petclinic-rest" | cut -d " " -f 1)

    # echo "=> Stopping and removing existing $DOCKER_CONTAINER_NAME_REST container"
    # docker rm -f $DOCKER_CONTAINER_NAME_REST
    # sleep 1
}

build() {
    echo "=> Building $DOCKER_IMAGE_NAME_ANGULAR"
    cd ./spring-petclinic-angular
    docker build -t spring-petclinic-angular:latest .
    echo "=> Building $DOCKER_CONTAINER_NAME_REST locally"
    cd ./spring-petclinic-rest
    ./mvnw clean package
    cd $WORK_DIR
}

start() {
    "Local deployment for testing"
    stop
    if [[ $# -eq 1 ]]; then
        echo "=> Building $DOCKER_IMAGE_NAME_ANGULAR"
        cd ./spring-petclinic-angular
        docker build -t spring-petclinic-angular:latest .
    fi
    echo "=> Running $DOCKER_CONTAINER_NAME_ANGULAR container"
    docker run -d -p 8080:8080 --name $DOCKER_CONTAINER_NAME_ANGULAR $DOCKER_IMAGE_NAME_ANGULAR
    cd $WORK_DIR
    echo "=> Building $DOCKER_CONTAINER_NAME_REST locally"
    java -javaagent:$CALL_TRACING_AGENT_PATH -cp $CALL_TRACING_AGENT_PATH:$CLASSPATH -jar spring-petclinic-rest/target/spring-petclinic-rest-2.4.2.jar

    sleep 1
}

if [[ $# -eq 0 || $# > 2 ]]; then
    usage
    exit 1
fi

if [[ $1 == "stop" ]]; then
    stop
elif [[ $1 == "build" ]]; then
    build
elif [[ $1 == "start" ]]; then
    if [[ $# -eq 2 ]]; then
        if [[ $2 != "-b" && $2 != "--build" ]]; then
            echo "Unknown start option: $2"
            usage
            exit 1
        fi
        start $2
    else
        start
    fi
else
    echo "Unknown command: $1"
    usage
fi
