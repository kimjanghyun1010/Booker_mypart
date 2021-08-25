#!/usr/bin/env groovy

def call(deploy) {

    util.log("RELEASE", "Started Release Stage")

    withCredentials([usernamePassword(credentialsId: gitCredential, usernameVariable: 'username', passwordVariable: 'password')]){
        execute("git config --global http.sslVerify false")

        util.sh("git tag ${params.IMAGE_TAG}")
        util.sh("git push ${env.SCHEME}://${username}:${password}@${env.REMOTE} ${params.IMAGE_TAG}")
    }
    
}
