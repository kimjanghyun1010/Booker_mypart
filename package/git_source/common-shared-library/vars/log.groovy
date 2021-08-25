#!/usr/bin/env groovy


def info(step, msg) {
    echo ">>> [INFO][${step}] : ${msg}"
}

def error(step, msg) {
    echo ">>> [ERROR][${step}] : ${msg}"
}

def warning(step, msg){
    echo ">>> [WARNING][${step}] : ${msg}"
}

def success(msg){
    echo ">>> [SUCCESS]: ${msg}"
}

def fail(msg){
    echo ">>> [FAILED]: ${msg}"
}
