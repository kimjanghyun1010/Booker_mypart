#!/usr/bin/env groovy

def call() {

    util.log("READY", "Started Ready Stage")
    
    env.COMMIT_NAME = ""
    env.BRANCH_NAME = "${env.GIT_BRANCH}".split("/")[1]
    env.REMOTE      = util.sh("git remote -v | head -1 | awk '{print \$2}' | sed -e 's/http:\\/\\///g' | sed -e 's/https:\\/\\///g'")
    env.PROFILE     = util.getProfile()
    env.SCHEME      = util.scheme()
    
    withCredentials([usernamePassword(credentialsId: gitCredential, usernameVariable: 'username', passwordVariable: 'password')]){
        util.setGitConfig()

        if( params.USE_SR.toLowerCase() != "all" && "${params.SR_ID}" == '') {
            error "SR_ID가 존재하지 않습니다."
        }

        if("${env.BRANCH_NAME}" == 'master' && params.USE_SR.toLowerCase() == "sr-id"){
            env.COMMIT_NAME  = util.sh("git log --pretty=format:'%H' --grep '^${params.SR_ID}\\s' --reverse")
            if(env.COMMIT_NAME == ""){
                error "${params.SR_ID} Commit 정보가 존재하지 않습니다. "
            }

            def target_dir = util.getWorkspace()
            dir("${target_dir}"){
                util.sh("git clone -b ${env.PROFILE} --single-branch  ${env.SCHEME}://${username}:${password}@${env.REMOTE} .")
            }
        
            String[] sha1 = "${env.COMMIT_NAME}".split('\n')
            for(item in sha1){
                if( item != "" ){
                    def rev_type = util.sh("git cat-file -t '" + item + "'")
                    if (rev_type == 'commit') {
                        util.sh("git checkout ${item}")
                        
                        String[] commit_files  = util.sh("git show --pretty='' --name-status '${item}'").split('\n')
                        util.log("files", item + " : " + commit_files)
                        
                        for(file_status in commit_files){ 
                            String status       = util.sh("echo '${file_status}' | awk '{print \$1}'")
                            String file_name    = util.sh("echo '${file_status}' | awk '{print \$2}'")
                            String updated_file = util.sh("echo '${file_status}' | awk '{print \$3}'")
                            String file_dir     = util.checkDirectory(file_name)
                            String updated_dir  = util.checkDirectory(updated_file)

                            if(status == "A" || status == "M"){
                                if(file_name.indexOf("/") > -1){
                                    util.sh("mkdir -p ${target_dir}/${file_dir}")
                                }
                                util.sh("cp -rf ${file_name} ${target_dir}/${file_name}")

                            }else if(status == "D"){
                                util.sh("rm -f ${target_dir}/${file_name}")
                            }else if(status.indexOf("R") > -1){
                                if(updated_file.indexOf("/") > -1){
                                    util.sh("mkdir -p ${target_dir}/${updated_dir}")
                                }
                                util.sh("cp -rf ${updated_file} ${target_dir}/${updated_file}")
                                util.sh("rm -f ${target_dir}/${file_name}")
                            }
                            //delete directory
                            if(file_name.indexOf("/") > -1){
                                def count = util.sh("ls -1A ${target_dir}/${file_dir} | wc -l")
                                if(count == 0){
                                    util.sh("rm -r ${target_dir}/${file_dir}")
                                }
                            }
                        }
                    }
                }
            }

        }else{
            if( "${env.BRANCH_NAME}" != 'master' && params.USE_SR.toLowerCase() == 'sr-id'){
                //dev, stg && SR_ID
                env.COMMIT_NAME  = util.sh("git log --pretty=format:'%H' --grep '^${params.SR_ID}\\s' | head -1")
            } 
            if(params.USE_SR.toLowerCase() != 'sr-id'){
                //master && 전체 또는 전체+SR_ID
                env.COMMIT_NAME  = util.sh("git log --pretty=format:'%H' | head -1")
            }
            if(params.USE_SR.toLowerCase() == 'all' ){
                util.sh("git checkout -b ${env.PROFILE} ")
            }else{
                util.sh("git checkout ${env.PROFILE} ")
                util.sh("git pull ${env.SCHEME}://${username}:${password}@${env.REMOTE} ${env.PROFILE}")
            }

            if(env.COMMIT_NAME == ""){
                error "[${params.SR_ID}] Commit 정보가 존재하지 않습니다. "
            }

            util.sh("git merge --no-commit -Xtheirs ${env.COMMIT_NAME} --squash")

            util.log("READY", "USE_SR : ${params.USE_SR}")
           
            if( "${env.BRANCH_NAME}" != 'master' && params.USE_SR.toLowerCase() == 'sr-id'){
                //dev, stg && SR_ID
                String[] commit_files  = util.sh("git diff --diff-filter=R --name-status '" + env.COMMIT_NAME + "'").split('\n')
                util.log("files", commit_files)
                for(file_status in commit_files){ 
                    String updated_file = util.sh("echo '${file_status}' | awk '{print \$2}'")
                    String old_file     = util.sh("echo '${file_status}' | awk '{print \$3}'")
                    String file_dir     = util.checkDirectory(old_file)

                    util.sh("rm -f ${updated_file}")

                    //delete directory
                    if(old_file.indexOf("/") > -1){
                        util.log("READY", file_dir)
                        def count = util.sh("ls -1A ${file_dir} | wc -l")
                        if(count == 0){
                            util.sh("rm -r ${file_dir}")
                        }
                    }
                }
            } 
        }
        gitPush()
    }
}