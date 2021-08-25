#!/usr/bin/env groovy

def call() {
    util.log("SOURCE PUSH", "Started Source Push Stage")
    withCredentials([usernamePassword(credentialsId: gitCredential, usernameVariable: 'username', passwordVariable: 'password')]){
        util.sh("git config --global user.email '${username}@crossent.com' && git config --global user.name '${username}' ")
        execute("git config --global http.sslVerify false")

        if(params.USE_SR.toLowerCase() == 'all'){
            util.sh("git pull ${env.SCHEME}://${username}:${password}@${env.REMOTE} -s ours ${env.PROFILE}")
            util.sh("git push ${env.SCHEME}://${username}:${password}@${env.REMOTE} ${env.PROFILE}")
            
        } else if(params.USE_SR.toLowerCase() != 'all'){
            def target_dir=util.getWorkspace()
            dir("${target_dir}"){

                util.log("GIT MERGE", util.sh("git status"))
                def status = util.sh("git status --short | wc -l") as Integer
                if( status > 0){
                    util.sh("git add . && git commit -m '${params.SR_ID} # ${env.COMMIT_NAME}'")
                    util.sh("git push ${env.SCHEME}://${username}:${password}@${env.REMOTE} ${env.PROFILE}")
                }
            }
        }
    }
}