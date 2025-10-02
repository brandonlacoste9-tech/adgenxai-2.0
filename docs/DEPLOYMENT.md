# Deployment Guide

This document describes the deployment workflows available in this repository.

## Available Workflows

### 1. Deploy (`deploy.yml`)
Main deployment workflow with environment selection.

**Triggers:**
- Manual dispatch (with environment selection: production/staging/development)
- Push to `main` branch
- Version tags (v*)

**Features:**
- Environment selection (production, staging, development)
- Pre-deployment checks
- Post-deployment verification
- Deployment status notifications

**Manual Trigger:**
Go to Actions → Deploy → Run workflow → Select environment

### 2. Launch Logkeeper (`launch-logkeeper.yml`)
Launches and monitors the logkeeper service.

**Triggers:**
- Manual dispatch
- Scheduled (every 6 hours)
- Push to `main` branch

**Purpose:**
Maintains logkeeper service for monitoring and log collection.

### 3. Smoke Status Auto (`smoke-status-auto.yml`)
Automated smoke tests for critical paths.

**Triggers:**
- Manual dispatch
- Scheduled (every 30 minutes)
- Push to `main` branch

**Purpose:**
Continuously validates that critical services and paths are operational.

### 4. Docker Multi-Arch (`docker-multiarch.yml`)
Builds multi-architecture Docker images.

**Triggers:**
- Manual dispatch
- Push to `main` branch
- Version tags (v*)
- Pull requests to `main`

**Platforms:**
- linux/amd64
- linux/arm64

**Features:**
- QEMU setup for cross-platform builds
- Docker Buildx for multi-arch support
- Optional Docker Hub push (requires secrets)
- Build caching for faster builds

## Configuration

### Docker Hub Authentication (Optional)
To push images to Docker Hub, configure these secrets:
- `DOCKER_USERNAME`: Your Docker Hub username
- `DOCKER_PASSWORD`: Your Docker Hub password or access token

### Environment Setup
GitHub environments can be configured for the Deploy workflow:
- production
- staging
- development

## Quick Start

1. **Manual Deployment:**
   - Go to Actions tab
   - Select "Deploy" workflow
   - Click "Run workflow"
   - Choose environment
   - Click "Run workflow"

2. **Automatic Deployment:**
   - Push to `main` branch
   - Or create a version tag: `git tag v1.0.0 && git push --tags`

## Monitoring

Check workflow status:
- GitHub Actions tab shows all workflow runs
- README badges show status of key workflows
- Failed workflows send notifications (if configured)

## Troubleshooting

### Workflow fails to start
- Check workflow YAML syntax
- Verify required secrets are configured
- Check branch protection rules

### Docker build fails
- Verify Dockerfile is present and valid
- Check if required secrets are configured
- Review build logs in Actions tab

### Deployment fails
- Check deployment environment configuration
- Verify access permissions
- Review pre-deployment check logs
