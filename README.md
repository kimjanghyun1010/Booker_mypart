# Booker (멀티캠퍼스 프로젝트)



#### Booker 란

```
부커(Booker)는 온라인 예약이 가능한 웹 사이트를 사업자가 직접 원하는 형태로 쉽게 만들어 주는 서비스입니다. 

부커 서비스를 통해 소규모 영세 사업자는 웹 사이트를 통한 홍보와 온라인 예약을 통한 매출 증대를,
사용자는 본인이 원하는 서비스를 온라인으로 쉽게 예약하고 
기다림 없이 이용할 수 있는 편리함을 제공하고자 합니다. 
또한 기존처럼 한정된 업종을 지원하는 포탈 예약시스템을 뛰어넘어, 
최대한 다양한 업종에서 활용 가능한 통합된 예약 서비스를 구축하는 것입니다.
```



#### 필요성

```
비대면 온라인 예약에 익숙한 사용자들의 편의를 위해 네이버와 같은 포털 사이트에서
예약 서비스를 제공하고 있으나 예약 가능한 서비스 유형과 기능이 다양하지 못 합니다.

자력으로 온라인 예약 시스템을 구축하기 어려운 소규모 영세 사업자들에게 
맞춤형 예약 시스템을 제공하기 위해 “부커(Booker)”를 기획하게 되었습니다. 
```



#### 목표

```
사업자를 위한 독립된 형태의 예약 홈페이지를 MSA 기반의 서비스로 구축하여
다른 기능이 정지되어도 구축된 홈페이지는 정지하지 않고 작동되게 만드는 것입니다.
```



#### 기존 서비스 분석

```
 네이버 예약

네이버 예약의 장점으로 포털 사이트로서 많은 사용자들이 쉽게 사용할 수 있다는 접근성과 
간편 결제 시스템인 네이버 페이의 편리성을 들 수 있습니다.

네이버 예약의 단점은 업종이 9개로 한정되어 있으며, 예약 정보를 보여주는 화면이 고정되어 있어
업체별 커스터마이징이 불가능하다는 것을 들 수 있습니다. 


 Wix 

홈페이지 제작 서비스 Wix의 장점은 다양한 템플릿을 바탕으로 
본인만의 웹사이트를 손쉽게 만들 수 있다는 것입니다. 
코딩에 대한 지식 없이 마우스 클릭만으로 간편하게 편집할 수 있습니다.

Wix의 단점은 Wix에서 예약 기능을 추가하기 위해서는 유료 서비스를 신청해야 할 뿐 아니라, 
제공되는 템플릿도 한정되어 있습니다. 
```



#### 서비스 동작화면

```
첨부파일의 Booker시연영상을 시청하시거나 아래의 링크로 시청부탁 드리겠습니다.
```

https://www.youtube.com/embed/EBM2ZLhK7lU

#### 서비스 아키텍쳐

```
Booker 서비스는 사업자 전용 페이지와 사용자 전용 페이지, 
그리고 독립된 예약 홈페이지로 구성되며, 각각 8080, 8081, 8082 포트를 통해서 서비스됩니다. 

개별 서비스는 스프링 부트와 스프링 클라우드를 기반으로 구현되었으며, 
소스 코드는 GitHub에 저장되고 Travis CI를 통해 AWS EC2 서버로 자동 배포될 수 있도록 구성했습니다.
```



### 부커 프로젝트에서 담당한 부분

```
사용자 프론트와 사용자 백앤드 8081, 8082를 개발 하였습니다. 

사용자 메인페이지(Booker메인페이지)
  * 검색기능(카카오API 키워드 지도검색)
  * 등록된 모든 업종 및 업체를 확인 할 수 있는 탭
사용자 마이페이지                                      
  * 예약 내역확인
개설한 사업자 업체페이지
  * 위치기능(카카오API 핀)
  * 간단한 업체 설명
예약 페이지
  * 달력(React DatePicker API)
  * 시간(React TimePicker)

사업자 페이지
  * 우편번호 등록(카카오API postcode)
  * Spring Template
 
사용자 백앤드

사용자 페이지에서 백앤드 서버로의 통신은 Promise 기반의 HTTP 클라이언트 모듈인 axios를 사용했으며, 
가장 범용적으로 많이 사용하는 JSON을 데이터 교환 형식으로 사용했으며,
백엔드 서버와 데이터베이스 연동은 Spring Data의 JPA로 처리했습니다.

```



