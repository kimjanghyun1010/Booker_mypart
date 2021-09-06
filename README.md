

## PaasXpert Install





**[온라인 설치]**

### 0. 참고 사항
- CI/CD까지 테스트 하고자 할 경우에는 CI/CD 이미지 패키지가 있어야 하고 Jenkins 연동은 따로 진행하셔야 합니다.
- 패키지는 용량이 커서 올려 놓지 못했습니다. 요청 하시면 드리겠습니다.

### 1. 사전 준비

- ssh key copy가 설정되어 있어야 합니다
- jenkins와 portal 이미지는 새로 생성한 유저의 images 디렉토리 안에 있어야 합니다. ( /home/paasadm/images )
- longhorn을 다른 볼륨으로 사용할 경우  마운트는 따로 해야 합니다.
  

### 2. 설치 방법

- inception이 없을 경우 haproxy에서 모든 설치를 진행합니다.
- inception이 있을 경우 inception에서 모든 설치를 진행합니다.
- 해당 README에서 새로 생성할 유저는 paasadm으로 가정합니다.



#### 2.1 유저 생성 및 배포 환경 설정

##### 2.1.1 유저 생성 shell

아래 shell을 전체 복사 해서 그대로 커맨드에 넣고 입력하면 됩니다.

    # shell 생성
    cat > ./user-add.sh << 'EOF'
    #!/bin/sh
    DEFAULT_USER=centos
    USERNAME=paasadm
    PASSWORD=crossent1234!
    
    #/
    # USERNAME 생성하는 shell
    #
    # @authors 크로센트
    #/
    
    CHECK_USER=$(sudo cat  /etc/passwd | grep ${USERNAME})
    
    if [ -z "$CHECK_USER" ]
    then
        sudo useradd ${USERNAME}
        echo "${PASSWORD}" | sudo passwd --stdin ${USERNAME}
        sudo sed -i -r -e  "/NOPASSWD/a\\${USERNAME} ALL\=\(ALL\)       NOPASSWD:\ALL" /etc/sudoers
        sudo sed -i -r -e  '/NOPASSWD/a\centos ALL\=\(ALL\)       NOPASSWD:\ALL' /etc/sudoers
        sudo echo PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/${USERNAME}/.local/bin:/home/${USERNAME}/bin | sudo tee -a /home/${USERNAME}/.bashrc
    
        sudo cp -r /home/${DEFAULT_USER}/.ssh /home/${USERNAME}/
        sudo chown -R ${USERNAME}. /home/${USERNAME}/.ssh
    fi
    EOF
    
    # shell 실행
    bash user-add.sh



##### 2.1.2 새로 생성한 유저에 접속합니다.

    sudo su paasadm



##### 2.1.3  설치에 필요한 기본 패키지를 설치합니다.

    sudo yum install -y tree wget git net-tools
    
    wget -q https://github.com/noqcks/gucci/releases/download/1.4.0/gucci-v1.4.0-linux-amd64
    chmod +x gucci-v1.4.0-linux-amd64
    sudo mv gucci-v1.4.0-linux-amd64 /usr/local/bin/gucci
    sudo ln -s /usr/local/bin/gucci /usr/bin/gucci
    
    cd ~
    git clone https://github.com/CrossentCloud/paasxpert-deployment-tool



##### 2.1.4 배포 환경 설정 (site.yaml)

    common:
    ## online, offline
      env: online
      directory:
    ## app에서 설정한 디렉토리에 설치 shell이 생성됩니다.
        app: /home/paasadm/paasxpert-deployment-tool/app
        data: /home/paasadm/paasxpert-deployment-tool/data
        log: /home/paasadm/paasxpert-deployment-tool/applog
        ## gitea-push, harbor-login에서 사용
    ## 자동화 템플릿을 git clone 받은 경로
        workdir: /home/paasadm/paasxpert-deployment-tool
      default_username: centos
      username: paasadm
      password: crossent1234!
      IP:
        haproxy:
          haproxy1: 192.168.153.1
        inception:
          inception1: 192.168.153.2
        master:
          master1: 192.168.153.4
        worker:
          worker1: 192.168.153.7
      docker:
        version: 1.19.3
        curl: 20.10.3
      rke:
        version: 1.2.8
      kubectl:
        version: 1.20.6
      rancher:
        version: 2.5.8
    # mount한 볼륨으로 longhorn을 구성할지에 대한 설정 false는 default 볼륨을 사용함(/var/lib/longhorn)
    longhorn:
      version: 1.1.0
      enable: false
      name:
        disk-1: /data/longhorn1
        disk-2: /data/longhorn2
    global:
      namespace: platform
      domain: prd.msxpert.co.kr
      ## private registry 설정할 경우 setting, harbor_secret 과 다른이름으로 생성
      ## public일 경우 imagePullSecrets 비워둠
      imagePullSecrets:
      harborimagePullSecrets: regcred
      storageClass: longhorn
    
      tls:
        secret: platform
      ## public 환경이 아닐 경우 private registry 주소를 적어준다.
      image:
        repository: docker.io
    
      port:
      ## nginx-http: 80 / nginx-https: 443
      ## 기본 port가 변경되면 적는다.
        nginx_http:
        nginx_https:
        rancher_https: 
        registry: 5000
        
    #-----
    # 아래 부분은 따로 설정하지 않고, 그대로 사용 합니다.
    
    



##### 2.1.5 배포 스크립트 생성 및 실행 (create.sh)

    cd /home/paasadm/paasxpert-deployment-tool/bin
    gucci -o missingkey=zero -f site.yaml ../template/create.tpl > create.sh
    sudo bash create.sh



##### 2.1.6  Inception 서버 hosts 등록

    sudo bash etc-hosts.sh



##### 2.1.7 배포 대상 서버에 paasadm 유저 생성

    bash run-user-add.sh # 이미 생성 했으면 실행하지 않습니다.



##### 2.1.8 배포 대상 서버 공통 설정

    bash base-common.sh
    sg docker -c "bash"
    sg ${USER} -c "bash"


##### 2.1.9 LB 구성

    bash ../app/deploy/loadbalancer-install.sh   # haproxy 와 named 설치



##### 2.1.10 RKE 설치

    bash ../app/deploy/os/rke/rke.sh
    bash ../app/deploy/os/rke/rke-install.sh



##### 2.1.11 PaaSXpert 서비스 설치

    # (~/paasxpert-deployment-tool/bin 폴더에서 실행)
    bash ../app/deploy/os/rke/px-install.sh



### 3. 연동

- 연동 점검과 설정을 진행하면서 coreDNS의 에러를 자주 볼 수 있는데 서버 상태가 좋지 못한거라 coreDNS와 kube-proxy를 재시작 해주면 간혹 정상으로 돌아옵니다.

#### 3.1 rancher Authentication 설정



##### 3.1.1

- Global 화면에서 Security 탭의 Authentication을 클릭 합니다.

![image-20210905234254653](https://user-images.githubusercontent.com/48508250/132132265-041e1ee7-a896-420e-be37-2747e2e80b36.png)


##### 3.1.2

- SAML - KeyCloak을 누릅니다.

![image-20210905234321154](https://user-images.githubusercontent.com/48508250/132132275-273bf0ca-5706-4727-905b-ce01fcfc94e9.png)





##### 3.1.3

- 필요한 값들은 이미 들어가 있으니 Authenticate with KeyCloak 버튼을 누릅니다.
- 팝업 로그인 창이 뜨면 keycloak에서 만든 paasadm 계정으로 로그인을 합니다. 
- 로그인을 하면 404화면이 뜨는데 rancher를 ha구성하면 생기는 에러라고 하니 팝업창에서 새로고침을 하면 정상작동 되면서 다음 화면으로 넘어갑니다.

    해당 이슈에 대한 내용이 담긴 링크 입니다.
    https://github.com/rancher/rancher/issues/31163

![image-20210905234452223](https://user-images.githubusercontent.com/48508250/132132284-ae5bd948-0ef2-4c66-b5a3-5c8e6e5d91aa.png)






##### 3.1.4

- Site Access 탭에서 중간에 있는 버튼을 선택하고, /paasxpert 그룹을 추가 후 저장 합니다.

![image-20210905234724016](https://user-images.githubusercontent.com/48508250/132132291-e1651277-fadb-4118-a6aa-9b1c2306975b.png)





#### 3.2 Gitea Password update



##### 3.2.1 

- openid 버튼으로 paasadm 계정에 로그인하고, 프로필을 눌러 설정 버튼을 누릅니다.

![image-20210906001230281](https://user-images.githubusercontent.com/48508250/132132295-32a2b353-5384-46d8-9b1d-d4735f18e870.png)


##### 3.2.2

- 기존 paasword와 똑같이 입력후 변경 해줍니다.
- 변경전에는 [현재 비밀번호] 칸이 없으니 새 비밀번호와 다시 입력에 입력후 변경 합니다.

![image-20210906001408609](https://user-images.githubusercontent.com/48508250/132132300-6978e58a-0c30-4b16-b6ca-9f99d8a18ef8.png)





#### 3.3 Portal 설정

- 네트워크 문제로 추정되는 에러가 많이 뜹니다.

##### 3.3.1 

- paasadm 계정으로 로그인을 하고, 환경설정 - 사용자 관리에 접속합니다.

![image-20210906002208263](https://user-images.githubusercontent.com/48508250/132132308-5696ce00-616e-465e-b961-928dd42b52f5.png)



##### 3.3.2

- 클러스터 권한을 ADMIN으로 주고 저장 합니다.

![image-20210906002200822](https://user-images.githubusercontent.com/48508250/132132313-ad3cfe72-38db-4776-b753-abf407b66f3b.png)




##### 3.3.3 

- 노드를 클릭 했을때 아래 자원 사용량이 나오면 됩니다.

![image-20210906002419082](https://user-images.githubusercontent.com/48508250/132132322-16848d11-7149-48ac-bdd1-47a2db8ea175.png)

