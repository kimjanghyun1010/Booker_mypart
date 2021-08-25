#!/usr/bin/env groovy

def call() {
    
    withCredentials([usernamePassword(credentialsId: gitCredential, usernameVariable: 'username', passwordVariable: 'password')]){
        log.info("BRANCH MERGE", "${env.BRANCH_NAME} BRANCH MERGE ")

        execute("git config --global http.sslVerify false")
        execute("git config --global user.email '${username}@example.com' && git config --global user.name '${username}' ")
        if("${env.BRANCH_NAME}" == 'master'){
            if(params.USE_SR){
                dir("../${env.JOB_NAME}_develop-${params.SR_ID}"){
                    def status = execute("git status --short | wc -l") as Integer

                    if( status > 0){
                        log.info("BRANCH MERGE", "count : ${status}")
                        execute("git add . && git commit -m '[${params.SR_ID}] 이관(master->dev)'")
                        execute("git push ${env.SCHEME}://${username}:${password}@${env.REMOTE} dev")
                    }
                }
            }else{
                execute("git pull ${env.SCHEME}://${username}:${password}@${env.REMOTE} dev")
                execute("git checkout -b dev")
                execute("git push ${env.SCHEME}://${username}:${password}@${env.REMOTE} dev")
            }
        } else if("${env.BRANCH_NAME}" == 'dev'){ 
                execute("git pull ${env.SCHEME}://${username}:${password}@${env.REMOTE} stg")
                execute("git checkout -b stg")
                execute("git push ${env.SCHEME}://${username}:${password}@${env.REMOTE} stg")
        } else if ("${env.BRANCH_NAME}" == 'stg'){
                execute("git pull ${env.SCHEME}://${username}:${password}@${env.REMOTE} prd")
                execute("git checkout -b prd")
                execute("git push ${env.SCHEME}://${username}:${password}@${env.REMOTE} prd")

                execute("git tag ${params.SR_ID}")
                execute("git push ${env.SCHEME}://${username}:${password}@${env.REMOTE} ${params.SR_ID}")
        } else {
               error "유효하지 않는 브랜치 입니다." 
        } 
    }
}