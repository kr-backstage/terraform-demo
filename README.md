# test - Terraform Demo Infrastructure

test

## Architecture Overview

이 프로젝트는 Backstage 소프트웨어 템플릿을 통해 단일 EC2 웹 애플리케이션을 자동으로 배포합니다.
배포 구성은 다음과 같습니다.

- **VPC & Public Subnet**: 10.0.0.0/24 대역의 전용 VPC와 퍼블릭 서브넷
- **Internet Gateway & Route**: 인터넷 트래픽을 위한 기본 라우팅
- **Security Group**: HTTP(80) 기본 허용, SSH(22)는 변수로 제어
- **EC2 (Amazon Linux 2023)**: Nginx 기반의 데모 웹 페이지 자동 구성
- **Elastic IP**: 고정 퍼블릭 IP 할당으로 URL 안정성 확보

## CI/CD 파이프라인

`.github/workflows/terraform.yml` 워크플로는 다음 단계를 자동 수행합니다.

1. **fmt / validate / plan** – Terraform 기본 검증
2. **PR 코멘트** – Plan 결과를 Pull Request에 자동 코멘트
3. **Apply** – `main` 브랜치 푸시 또는 `workflow_dispatch` 입력값이 `apply`일 때 실행
4. **Destroy** – `workflow_dispatch` 입력값이 `destroy`일 때 인프라 정리

> AWS 자격 증명은 GitHub Organization (또는 Repository) Secrets의 `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`를 사용합니다.
>
> 새로 생성한 저장소는 `Settings → Actions → General → Access to organization secrets` 옵션이 활성화되어야 합니다.

## 주요 변수

| 변수 | 설명 | 기본값 |
| --- | --- | --- |
| `environment` | 배포 환경 이름 | `dev` |
| `project_name` | 프로젝트 식별자 | `test` |
| `aws_region` | 배포 리전 | `ap-northeast-2` |
| `instance_type` | EC2 인스턴스 타입 | `t3.micro` |
| `allow_ssh_cidr` | SSH 허용 CIDR | `0.0.0.0/0` |

필요 시 `terraform.tfvars` 또는 GitHub Actions `workflow_dispatch` 입력을 활용해 값을 재정의하세요.

## GitHub Secrets 체크리스트

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

조직 레벨 시크릿을 사용하는 경우, 새 저장소에서도 상속이 허용되는지 반드시 확인하세요.

## 배포 확인

워크플로가 완료되면 다음 출력값을 확인할 수 있습니다.

```txt
application_url      = http://<Elastic-IP>
instance_public_ip   = <Elastic-IP>
instance_id          = i-xxxxxxxxxxxxxxxxx
security_group_id    = sg-xxxxxxxxxxxxxxxxx
vpc_id               = vpc-xxxxxxxxxxxxxxxxx
```

브라우저에서 `application_url`을 방문하면 Backstage Terraform 데모 페이지가 기본으로 노출됩니다.

## 수동 조작 명령어

```bash
# Plan 만 실행 (필요 시)
terraform plan

# Apply 수동 실행
terraform apply -auto-approve

# 자원 정리 (주의)
terraform destroy -auto-approve
```

## 문제 해결

| 증상 | 원인 | 해결 |
| --- | --- | --- |
| `Credentials could not be loaded` | Secrets 미설정 또는 상속 비활성화 | 저장소 설정에서 Secrets 상속 활성화, 키 이름 확인 |
| EC2 접속 실패 | Security Group 또는 Elastic IP 미할당 | `allow_ssh_cidr` 조정, `application_url` 출력값 확인 |

## 정리

- Backstage 템플릿 실행 시 소스 코드와 GitHub Actions 파이프라인이 자동 배포됩니다.
- EC2 단일 리소스이므로 비용과 배포 시간이 최소화됩니다.
- 필요 시 템플릿을 수정해 Auto Scaling, RDS 등으로 확장할 수 있습니다.

---

즐거운 데모 되세요! 🚀
