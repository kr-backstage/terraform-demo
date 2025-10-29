terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "test"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "instance_type" {
  description = "EC2 instance type for the demo web server"
  type        = string
  default     = "t3.micro"
}

variable "allow_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance"
  type        = string
  default     = "0.0.0.0/0"
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/25"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-public-subnet"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name_prefix = "${local.name_prefix}-web-"
  description = "Security group for demo web server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Optional SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allow_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-web-sg"
  })
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true

  user_data = <<-EOF
              #!/bin/bash
              set -eux
              dnf update -y
              dnf install -y nginx
              systemctl enable nginx
              cat <<'HTML' >/usr/share/nginx/html/index.html
              <!doctype html>
              <html lang="ko">
                <head>
                  <meta charset="utf-8">
                  <title>${var.project_name} :: Backstage Terraform Demo</title>
                  <meta name="viewport" content="width=device-width, initial-scale=1">
                  <style>
                    :root {
                      --bg-gradient: linear-gradient(135deg, #0f172a 0%, #1e3a8a 50%, #2563eb 100%);
                      --card-shadow: 0 20px 60px rgba(15, 23, 42, 0.35);
                    }
                    * { box-sizing: border-box; }
                    body {
                      margin: 0;
                      min-height: 100vh;
                      font-family: 'Pretendard', 'Noto Sans KR', system-ui, sans-serif;
                      background: #0b1220;
                      color: #f8fafc;
                      display: flex;
                      align-items: center;
                      justify-content: center;
                      padding: 3rem 1.5rem;
                    }
                    .page {
                      width: 100%;
                      max-width: 1040px;
                      background: rgba(15, 23, 42, 0.82);
                      border-radius: 32px;
                      box-shadow: var(--card-shadow);
                      overflow: hidden;
                    }
                    .hero {
                      position: relative;
                      padding: 3.5rem;
                      background: var(--bg-gradient);
                    }
                    .hero::after {
                      content: '';
                      position: absolute;
                      inset: 0;
                      background: radial-gradient(circle at top right, rgba(59, 130, 246, 0.45), transparent 55%);
                      pointer-events: none;
                    }
                    .hero-inner {
                      position: relative;
                      z-index: 1;
                      display: grid;
                      gap: 2rem;
                    }
                    .event-badge {
                      display: inline-flex;
                      align-items: center;
                      gap: 0.5rem;
                      padding: 0.45rem 1.1rem;
                      border-radius: 999px;
                      background: rgba(15, 23, 42, 0.35);
                      border: 1px solid rgba(255, 255, 255, 0.25);
                      font-size: 0.95rem;
                      font-weight: 600;
                      letter-spacing: 0.04em;
                    }
                    .event-title {
                      font-size: clamp(2.1rem, 4vw, 2.9rem);
                      font-weight: 700;
                      line-height: 1.25;
                      margin: 1.5rem 0 0.75rem;
                    }
                    .event-meta {
                      display: grid;
                      gap: 0.35rem;
                      font-size: 1rem;
                      color: rgba(241, 245, 249, 0.85);
                    }
                    .hero-banner {
                      margin-top: 1.5rem;
                      border-radius: 24px;
                      width: 100%;
                      max-height: 260px;
                      object-fit: cover;
                      border: 1px solid rgba(255, 255, 255, 0.15);
                      box-shadow: 0 16px 45px rgba(14, 23, 42, 0.45);
                    }
                    .content {
                      display: grid;
                      gap: 2.5rem;
                      padding: 3.5rem;
                      background: rgba(15, 23, 42, 0.85);
                    }
                    .section {
                      background: rgba(15, 23, 42, 0.65);
                      border-radius: 28px;
                      padding: 2.5rem;
                      border: 1px solid rgba(59, 130, 246, 0.18);
                      box-shadow: inset 0 0 0 1px rgba(30, 64, 175, 0.18);
                    }
                    .section h2 {
                      margin: 0 0 1.25rem;
                      font-size: 1.45rem;
                      font-weight: 700;
                      letter-spacing: -0.01em;
                    }
                    .agenda {
                      border-radius: 20px;
                      overflow: hidden;
                      border: 1px solid rgba(94, 234, 212, 0.25);
                      box-shadow: 0 14px 40px rgba(15, 118, 110, 0.25);
                      background: rgba(15, 118, 110, 0.12);
                    }
                    .details-list {
                      display: grid;
                      gap: 0.75rem;
                      margin: 1.5rem 0;
                    }
                    .details-list li {
                      list-style: none;
                      padding-left: 1.2rem;
                      position: relative;
                      color: rgba(226, 232, 240, 0.9);
                    }
                    .details-list li::before {
                      content: '•';
                      position: absolute;
                      left: 0;
                      color: #60a5fa;
                    }
                    .two-up {
                      display: grid;
                      gap: 1.5rem;
                      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
                    }
                    .stat {
                      padding: 1.25rem 1.5rem;
                      border-radius: 18px;
                      background: rgba(15, 23, 42, 0.6);
                      border: 1px solid rgba(148, 163, 184, 0.24);
                    }
                    .stat span {
                      display: block;
                    }
                    .label {
                      font-size: 0.85rem;
                      text-transform: uppercase;
                      letter-spacing: 0.18em;
                      color: rgba(148, 163, 184, 0.8);
                      margin-bottom: 0.35rem;
                    }
                    .value {
                      font-size: 1.2rem;
                      font-weight: 600;
                      color: #e2e8f0;
                    }
                    .cta-box {
                      margin-top: 2rem;
                      padding: 1.6rem;
                      border-radius: 20px;
                      background: rgba(37, 99, 235, 0.18);
                      border: 1px solid rgba(147, 197, 253, 0.4);
                    }
                    .cta-box strong {
                      display: block;
                      margin-bottom: 0.5rem;
                      font-size: 1.05rem;
                    }
                    footer {
                      text-align: center;
                      font-size: 0.9rem;
                      color: rgba(148, 163, 184, 0.6);
                      padding: 1.5rem 3.5rem 3rem;
                    }
                    @media (max-width: 768px) {
                      .hero, .content { padding: 2.2rem; }
                      .section { padding: 1.8rem; }
                      .hero-banner { max-height: 200px; }
                    }
                  </style>
                </head>
                <body>
                  <div class="page">
                    <section class="hero">
                      <div class="hero-inner">
                        <span class="event-badge">Backstage × Terraform Demo</span>
                        <h1 class="event-title">제 39회 IT 인프라 &amp; 네트워크 전문가 따라잡기 'N.EX.T' 정기 기술 세미나</h1>
                        <div class="event-meta">
                          <span>프로젝트: ${var.project_name}</span>
                          <span>Environment: ${var.environment} / Region: ${var.aws_region}</span>
                          <span>Provisioned via Backstage Software Template &amp; GitHub Actions</span>
                        </div>
                        <img class="hero-banner" src="https://static.onoffmix.com/afv2/thumbnail/2025/10/21/v35c32fa6abcf2af85fb9e18940044a8bc.png" alt="N.EX.T 세미나 배너">
                      </div>
                    </section>

                    <section class="content">
                      <article class="section">
                        <h2>행사 정보</h2>
                        <ul class="details-list">
                          <li>행사명: 제 39회 네트워크 전문가 따라잡기 N.EX.T</li>
                          <li>일시: 2025년 11월 15일(토) 10:00 ~ 16:00</li>
                          <li>장소: 코엑스 남컨퍼런스룸 402호</li>
                        </ul>
                        <div class="two-up">
                          <div class="stat">
                            <span class="label">EC2 INSTANCE</span>
                            <span class="value">${var.instance_type}</span>
                          </div>
                          <div class="stat">
                            <span class="label">GITHUB WORKFLOW</span>
                            <span class="value">terraform.yml</span>
                          </div>
                        </div>
                        <div class="cta-box">
                          <strong>Backstage에서 생성된 Terraform 파이프라인으로 자동 배포 완료!</strong>
                          <span>GitHub Actions에서 플랜/적용/삭제 내역을 확인하고, 데모를 반복 실행해 볼 수 있습니다.</span>
                        </div>
                      </article>

                      <article class="section">
                        <h2>Agenda Preview</h2>
                        <img class="agenda" src="https://static.onoffmix.com/afv2/attach/2025/10/27/v31b86f03334e7cd432b7bf4d994987681.jpg" alt="세미나 아젠다">
                      </article>
                    </section>

                    <footer>
                      이 페이지는 Backstage 소프트웨어 템플릿 &amp; Terraform CI/CD 파이프라인으로 자동 생성되었습니다.
                    </footer>
                  </div>
                </body>
              </html>
              HTML
              systemctl restart nginx
              EOF

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-web"
  })
}

resource "aws_eip" "web" {
  instance = aws_instance.web.id
  vpc      = true

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-eip"
  })
}
