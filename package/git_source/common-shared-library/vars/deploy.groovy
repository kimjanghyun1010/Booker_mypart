#!/usr/bin/env groovy

def call(deploy) {

    util.log("DEPLOY", "Started Deploy Stage")
    if(deploy == "k8s") {

        util.log("DEPLOY", "${params.CLUSTER_CREDENTIAL}  : ${params.CLUSTER_URL} : ${params.CLUSTER_NAME} : ${params.NAMESPACE}")
        withKubeConfig([credentialsId: "${params.CLUSTER_CREDENTIAL}",
                        serverUrl    : "${params.CLUSTER_URL}",
                        clusterName  : "${params.CLUSTER_NAME}",
                        namespace    : "${params.NAMESPACE}"
                    ]) {

            util.sh("kubectl apply -v=8 -f deploy/${env.PROFILE}/deployment.yml")
            //util.sh("kubectl patch deployment ${application} -p '{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"build_id\":\"${env.BUILD_ID}\"}}}}}'")
            util.sh("kubectl patch deployment ${application} -p '{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"build_id\":\"${env.BUILD_ID}\"}},\"spec\":{\"containers\":[{\"name\":\"${application}\",\"image\":\"${registry}${application}:${params.IMAGE_TAG}\"}]}}}}'")
            // util.sh("kubectl patch  -v=8 -f deploy/${env.PROFILE}/deployment.yml -p '{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"build_id\":\"${env.BUILD_ID}\"}},\"spec\":{\"containers\":[{\"name\":\"${application}\",\"image\":\"${registry}${application}:${params.IMAGE_TAG}\"}]}}}}'")

            // util.sh("kubectl rollout status deployment ${application} --namespace ${params.NAMESPACE}")
        }
    }
}