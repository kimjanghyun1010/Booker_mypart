## Jenkins Shared Library 설정

### 사전준비

#### 환경설정

Jenkins 관리 > 환경설정 > Global Pipeline Libraries 구성에 [추가] 버튼을 클릭하여 아래 내용과 같이 입력 후 저장한다.
<img src="http://101.55.126.222:3000/common/common-shared-libraries/src/branch/master/img/global-pipeline-libraries.png" width="700" alt="global-pipeline-libraries" >

#### Paremter

| Name               | Defaul Value        | 설명            |
| ------------------ | ------------------- | -------------- |
| SR_ID              |       -             | SR_ID          |
| CLUSTER_URL        |       -             | 클러스터 주소     |
| CLUSTER_NAME       |       -             | 클러스터 명       |
| CLUSTER_CREDENTIAL |       -             | k8s credential |
| NAMESPACE          |       -             | 네임스페이스      |
| SOURCE_MERGE       | ALL/ALL-SR-ID/SR_ID | 소스병합 방법 선택  |


#### common-shared-libraries Branch 별 CI/CD 전략


| 브랜치        | 설명                       |
| ------------| ------------------------- |
| master      | 개발                       |
| step3       | master, dev, prd 전략            |
| step4       | master, dev, stg, prd 전략   |



#### Jenkinsfile

파이프라인 생성시 해당 소스 저장소에 deploy 디렉토리가 생성되며, master를 제외한 브랜치 별 Jenkinsfile, Dockerfile 등의 파일이 존재

- dev, stg에 해당하는 Jenkinsfile

```
#!groovy
@Library('common-shared-libraries@master') _

pipeline{

    environment {
        registryUrl = "https://harbor.doxpert.co.kr"
        registry = "harbor.doxpert.co.kr/library/"
        application = "spring-demo"
        tag = "latest"
        gitCredential = "sudouser2"
        registryCredential = "harbor-registry-credential"
    }

    agent {
      kubernetes {
        defaultContainer 'jnlp'
        yamlFile 'deploy/dev/JenkinsPod.yml'
      }
    }

    options {
        timeout(time: 20, unit: 'MINUTES')
    }

    stages{
        stage("READY"){
            steps{
                container('jnlp') {
                    ready()
                }
            }
        }
        stage('SPRING BUILD') {
            steps{
                container('maven') {
                    sourceBuild("springboot-maven-jar")
                }
            }
        }
        stage("SOURCE TEST"){
            steps{
                container('maven') {
                    sourceTest('')
                }
            }
        }
        stage("IMAGE BUILD AND PUSH"){
            steps{
                container('docker') {
                    dockerPush()
                }
            }
        }
        stage("DEPLOY"){
            steps{
                container('kubectl') {
                    deploy('k8s')
                }
            }
        }

    }
    post{
        success { postEvent('success')}
        failure { postEvent('failure')}
    }
}
```

- prd에 해당하는 Jenkinsfile

```
#!groovy
@Library('common-shared-libraries@master') _

pipeline{

    environment {
        registryUrl = "https://harbor.doxpert.co.kr"
        registry = "harbor.doxpert.co.kr/library/"
        application = "spring-demo"
        tag = "latest"
        gitCredential = "sudouser2"
        registryCredential = "harbor-registry-credential"
    }

    agent {
      kubernetes {
        defaultContainer 'jnlp'
        yamlFile 'deploy/prd/JenkinsPod.yml'
      }
    }

    options {
        timeout(time: 20, unit: 'MINUTES')
    }

    stages{
        stage("READY"){
            steps{
                container('jnlp') {
                    ready()
                }
            }
        }
        stage('MAVEN BUILD') {
            steps{
                container('maven') {
                    sourceBuild("springboot-maven-jar")
                }
            }
        }

        stage("BUILD DOCKER IMAGE"){
            steps{
                container('docker') {
                    dockerPush()
                }
            }
        }
        stage("DEPLOY"){
            steps{
                container('kubectl') {
                    deploy('k8s')
                }
            }
        }
        stage("RELEASE"){
            steps{
                container('jnlp') {
                    release()
                }
            }
        }
    }
    post{
        success { postEvent('success')}
        failure { postEvent('failure')}
    }
}
```