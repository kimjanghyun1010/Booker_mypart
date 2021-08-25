#!/usr/bin/env groovy

def getWorkspace(){
    def target_dir = "${WORKSPACE}"
    if(params.USE_SR.toLowerCase() == 'sr-id' && "${env.BRANCH_NAME}" == 'master'){
        target_dir = "${WORKSPACE}-${params.SR_ID}"  
    }
    return target_dir
}

def getProfile(){
    String branchList= sh("git branch -a | grep remotes | awk '{print \$1}'")
    log("BRANCH LIST", branchList)
        
    if("${env.BRANCH_NAME}" == 'master'){
        return branchList.contains('dev') ? "dev" : "stg"
    }else if("${env.BRANCH_NAME}" == 'dev'){
        return branchList.contains('stg') ? "stg" : "prd"
    }else if("${env.BRANCH_NAME}" == 'stg'){
        return "prd"
    }else{
        error "유효하지 않는 브랜치명입니다."
    }    
}

def checkDirectory(String name){
    def result = ""
    if(name != "" && name.indexOf("/") > -1){
        result = name.substring(0, name.lastIndexOf("/"))
    }
    return result
}

def setGitConfig(){
    withCredentials([usernamePassword(credentialsId: gitCredential, usernameVariable: 'username', passwordVariable: 'password')]){
        sh("git config --global user.email '${username}@crossent.com' && git config --global user.name '${username}' && git config --global http.sslVerify false ")
    }
}

def log(String step, msg) {
    echo ">>> [INFO][${step}] : ${msg}"
}

def sh(String command){
    return sh(returnStdout:true, script : '#!/bin/sh -e \n' + command).trim()
}

def scheme() {
    return "https"
}
