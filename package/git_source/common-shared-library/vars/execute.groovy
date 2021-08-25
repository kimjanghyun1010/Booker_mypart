#!/usr/bin/env groovy

def call(String command){
    return sh(returnStdout:true, script : '#!/bin/sh -ex \n' + command).trim()
}

def call(String shell, String command){
    return sh(returnStdout:true, script : "#!/bin/${shell} -ex \n" + command).trim()
}