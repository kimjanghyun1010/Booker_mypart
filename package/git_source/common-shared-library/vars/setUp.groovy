#!/usr/bin/env groovy


def setEnv(){
    log.info("SETUP", "Set up the environment.")
    log.info("SETUP", "USE_SR : ${params.USE_SR}")

    env.COMMIT_NAME = ""
    env.BRANCH_NAME = "${env.GIT_BRANCH}".split("/")[1]
    env.REMOTE      = execute("git remote -v | head -1 | awk '{print \$2}' | sed -e 's/http:\\/\\///g'")
    
    if(params.USE_SR) {
       env.COMMIT_NAME  = execute("git log --pretty=format:'%H' --grep '${params.SR_ID}' --reverse")
    }

    execute("git config --global http.sslVerify false")

    log.info("SETUP", "sr_id : ${params.SR_ID}")
}

def fileList(sha1){
    def parent = execute("git log --pretty=%P -n 1 '" + sha1 + "'")
    return execute("git diff --name-only " + sha1 + " " + parent)
}

def loopReturn(sha1s){

    String[] sha1 = sha1s.split('\n')

    def result = [:]
    for(int i=0; i<sha1.size(); i++){
        if( "${sha1[i]}" != "" ){
           result.put("${sha1[i]}", fileList("${sha1[i]}").toString())
        }
    }
    return result
}

def call() {

    if(params.USE_SR && "${params.SR_ID}" == '') {
        error "SR_ID가 존재하지 않습니다."
    }

    setEnv()

    if("${env.BRANCH_NAME}" == 'master' && params.USE_SR){
        withCredentials([usernamePassword(credentialsId: gitCredential, usernameVariable: 'username', passwordVariable: 'password')]){
            
            if(env.COMMIT_NAME == ""){
                log.error("SETUP", "${params.SR_ID} Commit된 파일이 존재하지 않습니다. ")
                error "Commit된 파일이 존재하지 않습니다. "
            }

   
            dir("../${env.JOB_NAME}_develop-${params.SR_ID}"){
                log.info("SETUP", "git clone 수행")
                execute("git clone -b dev --single-branch ${env.SCHEME}://${username}:${password}@${env.REMOTE} .")
            }
        
            log.info("SETUP", "commit_name : ${env.COMMIT_NAME}")
        
            loopReturn("${env.COMMIT_NAME}").each{ 
                execute("git checkout $it.key")
                String[] files = "$it.value".split('\n')
                
                for(int i=0; i<files.size(); i++){
                    if( "${files[i]}".trim() != "" ){
                        execute("cp -r ${files[i]} ../${env.JOB_NAME}_develop-${params.SR_ID}/${files[i]}")
                    }
                }
            }
            
        }
    } else{
        execute("ls -al")
        // execute("git branch -a")
        // if("${env.BRANCH_NAME}" == 'master'){
        //     execute("git checkout -b dev")
        //     execute("ls -al")
        // }else if("${env.BRANCH_NAME}" == 'dev'){
        //     execute("git checkout -b stg")
        // }else if("${env.BRANCH_NAME}" == 'stg'){
        //     execute("git checkout -b prd")
        // }else{
            log.info("SETUP", "Skipped.")
        // }
        
    }
}

