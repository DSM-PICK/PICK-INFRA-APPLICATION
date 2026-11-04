# PICK-INFRA-APPLICATION

ArgoCD ApplicationSet + 공통 Helm Chart 기반 GitOps 저장소입니다.

`apps/<app>/values.yaml` 파일을 자동으로 감지해 애플리케이션별 ArgoCD Application을 생성하고,
`charts/app` 공통 차트로 Deployment, Service, IngressRoute, Addon 리소스를 배포합니다.

## 구조

```text
.
├── apps/                      # 앱별 values.yaml (ApplicationSet이 자동 감지)
│   └── <app>/values.yaml
├── argocd/
│   └── applicationset.yaml    # ApplicationSet
└── charts/app/                # 공통 Helm Chart
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── _helpers.tpl
        ├── networkpolicy.yaml
        ├── deployments/
        │   ├── deployment.yaml
        │   ├── service.yaml
        │   └── ingress.yaml
        └── addons/
            ├── mysql.yaml
            ├── redis.yaml
            ├── kafka.yaml
            └── debezium.yaml
```

## 동작 방식

1. `argocd/applicationset.yaml`의 Git generator가 `apps/*/values.yaml`을 찾습니다.
2. 디렉터리 이름(`path.basename`)이 ArgoCD Application 이름이 됩니다.
3. `values.yaml`의 `namespace` 값이 배포 대상 namespace가 됩니다.
4. 공통 차트(`charts/app`)와 앱별 values를 합쳐 리소스를 렌더링합니다.

### Namespace

```yaml
namespace: my-namespace
```

- `namespace`가 비어 있으면 ArgoCD destination namespace(`.Release.Namespace`)를 사용합니다.
- ApplicationSet은 `CreateNamespace=true`로 namespace를 자동 생성합니다.

## 새 앱 추가

`apps/<app>/values.yaml` 파일을 추가하고 Git에 push하면 됩니다.

```yaml
namespace: my-app

deployments:
  - name: api
    replicas: 2

    image:
      repository: ghcr.io/example/api
      tag: v1.0.0
      pullPolicy: IfNotPresent

    service:
      type: ClusterIP
      port: 8080
      targetPort: 8080

    ingress:
      entryPoints:
        - web
      hosts:
        - api.example.com

    secret:
      name: api-secret

addons:
  - type: redis
    name: redis
    storage: 5Gi
```

## Deployment 설정

`deployments`는 리스트이므로 한 앱에서 여러 Deployment를 정의할 수 있습니다.

```yaml
deployments:
  - name: admin
    # ...
  - name: user
    # ...
```

| 필드 | 설명 | 기본값 |
| --- | --- | --- |
| `name` | Deployment/Service/IngressRoute 이름 | Release 이름 |
| `replicas` | replica 수 | `1` |
| `image.repository` | 이미지 저장소 | `nginx` |
| `image.tag` | 이미지 태그 | `latest` |
| `image.pullPolicy` | 이미지 pull 정책 | `IfNotPresent` |
| `service.type` | Service 타입 | `ClusterIP` |
| `service.port` | Service 포트 | `80` |
| `service.targetPort` | 컨테이너 포트 | `service.port` |
| `secret.name` | 주입할 Secret 이름 | 없음 (주입 안 함) |
| `ingress.entryPoints` | Traefik entryPoint 목록 | `["web"]` |
| `ingress.hosts` | IngressRoute 호스트 목록 | 없음 (생성 안 함) |
| `ingress.host` | 단일 호스트 (선택) | 없음 |

### Ingress

`ingress.hosts`에 값이 있을 때만 Traefik `IngressRoute`가 생성됩니다.

```yaml
ingress:
  entryPoints:
    - web
  hosts:
    - admin.example.com
    - admin-api.example.com
```

`host` 하나만 쓸 수도 있습니다.

```yaml
ingress:
  host: admin.example.com
```

### Secret

`secret.name`이 비어 있으면 `envFrom.secretRef`를 주입하지 않습니다.

```yaml
secret:
  name: api-secret
```

## Addon 설정

`addons`는 리스트이며 `type`으로 종류를 구분합니다.

지원 타입: `mysql`, `redis`, `kafka`, `debezium`

```yaml
addons:
  - type: mysql
    name: mysql
    # ...
  - type: redis
    name: redis
    # ...
```

### Storage

`storage`는 문자열 또는 객체로 지정할 수 있습니다.

```yaml
# 문자열
storage: 10Gi
```

```yaml
# 객체
storage:
  size: 10Gi
  storageClassName: my-storage-class
```

- `storageClassName`을 생략하면 PVC에 해당 필드를 넣지 않아 클러스터 기본 StorageClass를 사용합니다.
- 크기를 생략하면 문자열 형식일 때 `10Gi`가 기본입니다.

### MySQL

```yaml
- type: mysql
  name: mysql
  database: app
  username: app
  secretName: mysql-secret
  image:
    repository: mysql
    tag: "8.4"
    pullPolicy: IfNotPresent
  storage:
    size: 10Gi
```

- `secretName`을 생략하면 `<name>-secret`을 사용합니다.
- Secret에는 `mysql-password`, `mysql-root-password` 키가 필요합니다.
- Secret 리소스는 차트에서 생성하지 않습니다.

### Redis

```yaml
- type: redis
  name: redis
  image:
    repository: redis
    tag: "7-alpine"
    pullPolicy: IfNotPresent
  storage: 5Gi
```

### Kafka

```yaml
- type: kafka
  name: kafka
  image:
    repository: confluentinc/cp-kafka
    tag: "7.4.0"
  zookeeper:
    image:
      repository: confluentinc/cp-zookeeper
      tag: "7.4.0"
  storage: 10Gi
```

- Kafka와 Zookeeper를 함께 배포합니다.
- `serviceName`을 지정하면 Service 이름을 별도로 설정할 수 있습니다.

### Debezium

```yaml
- type: debezium
  name: debezium
  bootstrap: kafka.my-namespace.svc.cluster.local:9092
  image:
    repository: quay.io/debezium/connect
    tag: "3.3"
  storage: 5Gi
```

- `bootstrap`은 Debezium이 접속할 Kafka 브로커 주소입니다.
- 같은 namespace의 Kafka를 사용하는 경우 `kafka:9092` 형태로 지정할 수 있습니다.
- `serviceName`을 지정하면 Service 이름을 별도로 설정할 수 있습니다.

## NetworkPolicy

차트는 `<app>-allow-same-namespace` NetworkPolicy를 생성합니다.

- 같은 namespace의 Pod 간 통신 허용
- `kube-system` namespace 통신 허용

## 요구 사항

- ArgoCD
- Traefik CRD (`traefik.io/v1alpha1` IngressRoute)
- 기본 StorageClass (별도 지정하지 않는 경우)
- MySQL 사용 시 password Secret 사전 생성

## 로컬 확인

```bash
helm lint charts/app
helm template test charts/app -f apps/<app>/values.yaml
```
