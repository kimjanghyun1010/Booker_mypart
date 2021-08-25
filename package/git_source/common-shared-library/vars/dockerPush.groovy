#!/usr/bin/env groovy

def call() {
    util.log("DOCKER PUSH", "Started Docker Push Stage")

    def target_dir = util.getWorkspace()
    dir("${target_dir}"){
        //def profile = util.getCloneBranch()
        sh "cp deploy/${env.PROFILE}/Dockerfile ./"
        docker.withRegistry(registryUrl, registryCredential) {
            util.log("IMAGE BUILD AND PUSH", "docker Build ${registry}${application}:${params.IMAGE_TAG}")
            dockerImage = docker.build("${registry}${application}:${params.IMAGE_TAG}", "--no-cache .")
            //dockerImage = docker.build "${registry}${application}:${params.IMAGE_TAG}"
            dockerImage.push(params.IMAGE_TAG)
            sh "rm ./Dockerfile"
        }
    }
}