#!/usr/bin/env groovy

def call(packageType) {
    util.log("SOURCE BUILD", "Started Source Build Stage")
    def target_dir = util.getWorkspace()
    dir("${target_dir}"){
        if(packageType.indexOf("maven-jar") > -1 ) {
            util.log("SOURCE BUILD", "mvn clean package")
            util.sh("mvn -s /tmp/settings.xml -DskipTests=true clean package")
        }else if(packageType.indexOf("war") > -1 ) {
            util.log("SOURCE BUILD", "war build")
            util.sh("jar -cvf ROOT.war *")
        }else {
            util.log("SOURCE BUILD", "유효하지 않는 packageType 입니다.")
            error "유효하지 않는 packageType 입니다."
        }
    }
}
