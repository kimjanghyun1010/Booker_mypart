## PaasXpert Install

### 1. Gucci Install
- version: v1.4.0

```
$ wget -q https://github.com/noqcks/gucci/releases/download/1.4.0/gucci-v1.4.0-linux-amd64
$ chmod +x gucci-v1.4.0-darwin-amd64
$ mv gucci-v1.4.0-darwin-amd64 /usr/local/bin/gucci
$ ln -s /usr/local/bin/gucci /usr/bin/gucci
```

### 2. Helm deploy

- Ceck list
- Rancher Version
- 

#### 2.1. Kubectl Command Install
- version: v1.18.16 (Rancher Support Matrix)
> https://rancher.com/support-maintenance-terms/all-supported-versions/rancher-v2.4.11/
```
$ curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.16/bin/linux/amd64/kubectl
$ cp kubectl /usr/local/bin/kubectl
$ ln -s /usr/local/bin/kubectl /usr/bin/kubectl
$ vi ~/.kube/config
$ kubectl version
```


#### 2.2. Helm Command Install
- version: v3.2.4
> https://github.com/helm/helm/releases
```
$ wget https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz
$ tar zxvf helm-v3.2.4-linux-amd64.tar.gz
$ cd linux-amd64/
$ cp helm /usr/local/bin/helm
$ ln -s /usr/local/bin/helm /usr/bin/helm
$ helm version
```

#### 2.3. Helm Deploy script create
> https://github.com/CrossentCloud/hkmc.clap-helm-catalog.git
```
$ git clone https://github.com/CrossentCloud/hkmc.clap-helm-catalog.git origin epis
$ cd hkmc.clap-helm-catalog/install_template/bin
$ vi site.yaml
$ gucci -o missingkey=zero -f site.yaml ../template/create.tpl > ./create.sh
$ bash hkmc.clap-helm-catalog/install_template/bin/create.sh
```

#### 2.4. Secret Setting
> 
1. openssl 사설인증서 발급
2. 생성된 인증서로 secret 생성
3. secret 생성목록
	1. `platform` tls secret
	2. `gitea-cert` generic secret
	3. `regcred` docker registry secret
```
## 생성 방법

```
