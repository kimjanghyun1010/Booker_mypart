#!/bin/sh
source {{ .common.directory.app }}/function.env
source {{ .common.directory.app }}/properties.env


Protocol="https"
Jenkins_CNAME="{{ .jenkins.ingress.cname }}"
Keycloak_CNAME="{{ .keycloak.ingress.cname }}"
DOMAIN="{{ .global.domain }}"
JENKINS_PATH="${JSON_PATH}/jenkins"


#/
# <pre>
# Jenkins sso 연동을 위한 api
# cookie, crumb, api-token을 발급 받고 jenkins.yaml 파일에 기록
# Jenkins CI/CD를 위한 Credential 등록 api
# </pre>
#
# @authors 크로센트
# @see
#/

echo_api_blue "== Cookie Create =="
curl -s ${Protocol}://${Jenkins_CNAME}.${DOMAIN}/j_security_check \
  -d 'j_username=admin&j_password=crossent1234%21&from=&Submit=%EB%A1%9C%EA%B7%B8%EC%9D%B8' \
  --compressed \
  --insecure -c ${JENKINS_PATH}/${Jenkins_CNAME}.cookie

export Jenkins_Cookie=`cat ${JENKINS_PATH}/${Jenkins_CNAME}.cookie | grep HttpOnly | awk '{print $6"="$7}'`
echo ${Jenkins_Cookie}

echo_api_blue "== Crumb Create =="
curl -s ${Protocol}://${Jenkins_CNAME}.${DOMAIN}/crumbIssuer/api/xml?tree=crumb \
-b @${JENKINS_PATH}/${Jenkins_CNAME}.cookie \
  --compressed \
  --insecure > ${JENKINS_PATH}/${Jenkins_CNAME}.crumb

export Jenkins_Crumb=`cat ${JENKINS_PATH}/${Jenkins_CNAME}.crumb | grep "<crumb>" | cut -d '>' -f3 | rev | cut -c 8-| rev`
echo ${Jenkins_Crumb}

echo_api_blue "== Token Create =="
curl -ks ${Protocol}://${Jenkins_CNAME}.${DOMAIN}/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken \
-b @${JENKINS_PATH}/${Jenkins_CNAME}.cookie --data 'newTokenName=my-first-sso-token' --user 'admin:{{ .jenkins.adminPassword }}' \
-H "Jenkins-Crumb:${Jenkins_Crumb}" > ${JENKINS_PATH}/${Jenkins_CNAME}.token

export Jenkins_Token=`cat ${JENKINS_PATH}/${Jenkins_CNAME}.token | grep tokenValue | cut -d ":" -f5 | rev | cut -c 14- | rev | sed 's/"//g'`
echo ${Jenkins_Token}

echo_api_blue "== Keycloak Client Secret Jenkins_Script Conversion =="
curl -ks -b @${JENKINS_PATH}/${Jenkins_CNAME}.cookie -X POST ${Protocol}://${Jenkins_CNAME}.${DOMAIN}/scriptText -d "script=println(hudson.util.Secret.fromString('JENKINS_CLIENT_SECRET').getEncryptedValue())" -H "Jenkins-Crumb:${Jenkins_Crumb}"  -u admin:${Jenkins_Token} | sed 's/{//gi' | sed 's/}//gi' > ${JENKINS_PATH}/${Jenkins_CNAME}.secret

export Jenkins_Client_Secret=`cat ${JENKINS_PATH}/${Jenkins_CNAME}.secret`
echo ${Jenkins_Client_Secret}

echo_api_blue "== Password Credential harbor =="
curl -ksX POST ${Protocol}://${Jenkins_CNAME}.${DOMAIN}/credentials/store/system/domain/_/createCredentials \
-H "Jenkins-Crumb:${Jenkins_Crumb}" --user admin:${Jenkins_Token} \
-b @${JENKINS_PATH}/${Jenkins_CNAME}.cookie \
--data-urlencode 'json={
  "": "0",
  "credentials": {
    "scope": "GLOBAL",
    "id": "registry-credential",
    "username": "admin",
    "password": "{{ .harbor.adminPassword }}",
    "description": "registry-credential",
    "stapler-class": "com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl"
  }
}'

echo_api_blue "== Password Credential gitea =="
curl -ksX POST ${Protocol}://${Jenkins_CNAME}.${DOMAIN}/credentials/store/system/domain/_/createCredentials \
-H "Jenkins-Crumb:${Jenkins_Crumb}" --user admin:${Jenkins_Token} \
-b @${JENKINS_PATH}/${Jenkins_CNAME}.cookie \
--data-urlencode 'json={
  "": "0",
  "credentials": {
    "scope": "GLOBAL",
    "id": "git-credential",
    "username": "{{ .gitea.adminUsername }}",
    "password": "{{ .gitea.adminPassword }}",
    "description": "git-credential",
    "stapler-class": "com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl"
  }
}'


echo_api_blue "== Secret Credential kubernetes =="
curl -ksX POST ${Protocol}://${Jenkins_CNAME}.${DOMAIN}/credentials/store/system/domain/_/createCredentials \
-H "Jenkins-Crumb:${Jenkins_Crumb}" --user admin:${Jenkins_Token} \
-b @${JENKINS_PATH}/${Jenkins_CNAME}.cookie \
--data-urlencode 'json={
  "": "0",
   "credentials": {
   "scope": "GLOBAL",
   "id": "kubernetes-credential",
   "secret": "K8S_TOKEN",
   "description": "kubernetes-credential",
   "$class": "org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl"
  }
}'

echo_api_blue "== Create jenkins.yaml =="
cat > ${JENKINS_PATH}/../jenkins.yaml << EOF
configure:
  Jenkins_URL: ${Jenkins_CNAME}.${DOMAIN}
  Keycloak_URL: ${Keycloak_CNAME}.${DOMAIN}
  Jenkins_Client_Secret: ${Jenkins_Client_Secret}
  Jenkins_Crumb: ${Jenkins_Crumb}
  Jenkins_Cookie: ${Jenkins_Cookie}
EOF
