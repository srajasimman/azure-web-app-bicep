# Azure Two-Tier Web Application Infrastructure

This repository contains Azure ARM templates (Bicep) for deploying a two-tier web application infrastructure in Azure.

## Overview

- **Frontend**: React Static UI hosted in Azure Storage Account and served through Azure Front Door
- **Backend**: .NET API service hosted in Azure App Service with:
  - MySQL Server for data storage
  - Azure Storage Account for object storage
  - Okta authentication integration

## Environments

- **Development**: Lower-tier resources optimized for development and testing
- **Production**: Higher-tier resources with redundancy and security features

## IaC Architecture

```mermaid
flowchart TB
    %% Clients
    User["User"]:::external

    %% Frontend Layer
    subgraph "Frontend Layer"
        direction TB
        FrontDoor["Azure Front Door"]:::network
        StaticStorage["Static Website Storage"]:::data
    end

    %% Backend Layer
    subgraph "Backend Layer"
        direction TB
        subgraph "Azure Network (VNet)"
            direction TB
            VNet["Virtual Network"]:::network
            AppSubnet["App Subnet"]:::network
            AppService["App Service Plan & .NET API"]:::compute
        end
        MySQLDB["Azure Database for MySQL"]:::data
        BlobStorage["Blob/Object Storage"]:::data
    end

    %% Security
    Okta["Okta Authentication (OIDC)"]:::external

    %% Environments
    subgraph "Environments"
        DevOverlay["Dev Environment Overlay"]:::network
        ProdOverlay["Prod Environment Overlay (WAF enabled)"]:::network
    end

    %% Connections
    User -->|"HTTPS"| FrontDoor
    FrontDoor -->|"Serves Static Assets"| StaticStorage
    FrontDoor -->|"Routes API Calls"| AppService
    FrontDoor -->|"Validates Token"| Okta
    AppService -->|"SQL over TLS"| MySQLDB
    AppService -->|"REST API (Blob) over HTTPS"| BlobStorage
    AppService -->|"Validates Token"| Okta
    AppService --- AppSubnet
    AppSubnet --- VNet

    %% Click Events
    click StaticStorage "https://github.com/srajasimman/azure-web-app-bicep/blob/main/modules/frontend/storage-account.bicep"
    click FrontDoor "https://github.com/srajasimman/azure-web-app-bicep/blob/main/modules/frontend/front-door.bicep"
    click AppService "https://github.com/srajasimman/azure-web-app-bicep/blob/main/modules/backend/app-service.bicep"
    click MySQLDB "https://github.com/srajasimman/azure-web-app-bicep/blob/main/modules/backend/mysql.bicep"
    click BlobStorage "https://github.com/srajasimman/azure-web-app-bicep/blob/main/modules/backend/storage.bicep"
    click VNet "https://github.com/srajasimman/azure-web-app-bicep/blob/main/modules/network/vnet.bicep"
    click AppSubnet "https://github.com/srajasimman/azure-web-app-bicep/blob/main/modules/network/app-subnet.bicep"
    click Okta "https://github.com/srajasimman/azure-web-app-bicep/blob/main/modules/security/okta-authentication.bicep"
    click DevOverlay "https://github.com/srajasimman/azure-web-app-bicep/blob/main/environments/dev/main.bicep"
    click ProdOverlay "https://github.com/srajasimman/azure-web-app-bicep/blob/main/environments/prod/main.bicep"

    %% Styles
    classDef compute fill:#D0E8FF,stroke:#333,stroke-width:1px
    classDef data fill:#DFFFD0,stroke:#333,stroke-width:1px
    classDef network fill:#FFE0B2,stroke:#333,stroke-width:1px
    classDef external fill:#E1D5E7,stroke:#333,stroke-width:1px
```

## Application Architecture
![Application Architecture](./app-architecture.svg)

## Deployment

### Prerequisites

- Azure CLI installed
- Azure subscription
- Resource Group created
- GitHub repository with the code

### Deployment Steps

1. Clone this repository
2. Set up the required secrets in GitHub:
   - AZURE_CREDENTIALS
   - AZURE_SUBSCRIPTION
   - AZURE_RG
3. Push to the appropriate branch:
   - `develop` branch for development environment
   - `main` branch for production environment

### Manual Deployment

```bash
# Login to Azure
az login

# Deploy to development
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file ./environments/dev/main.bicep \
  --parameters ./environments/dev/parameters.json

# Deploy to production
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file ./environments/prod/main.bicep \
  --parameters ./environments/prod/parameters.json
```

## Resources Created

- **Frontend**:
  - Storage Account for static website hosting
  - Front Door for global distribution and HTTPS
  
- **Backend**:
  - App Service Plan
  - App Service for .NET API
  - MySQL Server
  - Storage Account for object storage
  
- **Security**:
  - Okta integration for authentication
  - Web Application Firewall (Production only)

## Configuration

Update the parameters files in the `environments/dev` and `environments/prod` directories to customize the deployment for your needs.