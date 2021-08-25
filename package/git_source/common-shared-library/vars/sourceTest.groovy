#!/usr/bin/env groovy

def call(packageType) {
    util.log("SOURCE TEST", "Started Source Test Stage")
    def target_dir = util.getWorkspace()
    dir("${target_dir}"){
        if(packageType.indexOf("maven-jar") > -1 ) {
            util.log("SOURCE TEST", "maven Junit 테스트")
            util.sh("mvn test") 
        }else {
            util.log("SOURCE TEST", "Test Skipped.")
        }
    }
}