#!/usr/bin/env groovy

def call(String status){

    if( status == "cleanDir" ){
        dir("${WORKSPACE}@tmp") {
            deleteDir()
        }
        if(params.USE_SR){
            def target_dir=util.getWorkspace()
            dir("${target_dir}"){
                deleteDir()
            }
            dir("${target_dir}@tmp"){
                deleteDir()
            }
        }
    }
    
    if( status == "success" ){
        util.log("SUCCESS","파이프라인 성공")
    }
    
    if( status == "failure" ) {
        util.log("FAIL","파이프라인 실패 (${env.BUILD_URL})")
    }

}