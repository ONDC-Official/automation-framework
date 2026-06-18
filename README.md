# Protocol Workbench
A universal, intelligent framework designed to enable and facilitate the implementation of open network protocols of ONDC. It provides for seamless API validation, experiencing real-world use cases and scenarios, and robust interoperability. Built for adaptability, it serves as a foundation for scalable, ONDC’s open-network implementations across diverse domains.

## Objectives
- Act as a universal protocol experience and enablement framework
- API processing & real-world scenario simulation including ONDC protocol checks
- Go-to source for development & validation
- Automation-driven testing for faster adoption
- Standardized api-level validation & compliance
- Enhanced debugging & error resolution
- Address development journey hindrances ONDC NPs face

## Capabilities
Protocol Workbench offers guided assistance for experiencing open API based transactions being executed in an open network, as it simulates real NP-to-NP interactions – for example, a buyer app developer can illustrate flows against a simulated seller app in the sandbox – making end-to-end integration development feasible. It enforces protocol consistency with validations based on the flows defined, helping reduce divergent interpretations.

## Core Tools
- Schema Validation Tool – Validates API payloads against ONDC specifications, highlighting inconsistencies / missing fields. NPs can simply Paste/ Upload their API json payloads. Based on the payload pasted, the tool takes the domain and the version for testing compliance and checks for errors in API schema, data types, required fields, enums and conditions as applicable by the model implementation. NPs can review errors on missing or incorrect fields and fix issues and re-test as required 
- Flow Testing Suite – Simulates end-to-end transactions to verify adherence to protocol flows and expected behavior. It enables testing of complete ONDC workflows across buyer and seller interactions in the respective domain. Enter your details to get started with the testing. Once entered, based on the use case selected, flows specific to the domain/ use case will be available to initiate the flow testing process. Process & send payloads as per the flow and issues, if any, are highlighted as you proceed step by step.

## Local Development Setup

### Prerequisites
- Docker & Docker Compose
- Git

### First-time setup

Clone and initialise submodules (pinned to the tested commit):
```bash
git clone <this-repo>
cd automation-framework
git submodule update --init
```

Build and start all services:
```bash
docker compose build ui-frontend backoffice-frontend
docker compose up -d
```

### Pulling latest frontend code

The frontend submodules (`automation-frontend`, `automation-backoffice`) track the `main` branch of their upstream repos. To update them to the latest code before rebuilding:
```bash
git submodule update --remote --merge
docker compose build ui-frontend backoffice-frontend
docker compose up -d ui-frontend backoffice-frontend
```

### Running a domain API service

Each ONDC domain/version (FIS12, RET10, TRV11, etc.) is a separate API service generated from a spec branch. The script clones the spec locally so you can edit both the spec config and the generated code before building.

**1. List available spec branches:**
```bash
./scripts/build-api-service.sh
```

**2. Run the script for the branch you want:**
```bash
./scripts/build-api-service.sh draft-FIS12-2.3.0
# or a release branch:
./scripts/build-api-service.sh release-eks-RET10-1.2.5
```

The script:
- Clones `automation-specifications` into `api-service/` (first run) or fetches the new branch (subsequent runs)
- Parses `api-service/config/` → `build.yaml` and validates it
- Runs `@ondc/api-service-generator` to produce `api-service/build-output/`
- Pushes spec data to the local `db-service` (if running)
- Writes `docker-compose.api.yml` pointing to `api-service/build-output/` as the Docker build context

**3. Fill in secrets:**
```
docker-env/api-service-common.env  ← replace *_change_me values
```

**4. Build the Docker image and start:**
```bash
docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build
```

The service is reachable at **http://localhost:3032** and at `http://api-service:7039` from other containers on the network.

---

**Editing generated code** (no spec change needed):
```bash
# Edit api-service/build-output/ directly, then rebuild:
docker compose -f docker-compose.yml -f docker-compose.api.yml build
docker compose -f docker-compose.yml -f docker-compose.api.yml up -d
```

**Editing the spec config** (regenerates code from scratch):
```bash
# Edit api-service/config/, then re-run the script:
./scripts/build-api-service.sh draft-FIS12-2.3.0
docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build
```

> `api-service/` and `docker-compose.api.yml` are git-ignored. Only one domain service can run on port 3032 at a time.

---

### Port reference

| Service | URL |
|---------|-----|
| UI Frontend | http://localhost:3035 |
| UI Backend | http://localhost:3034 |
| Backoffice Frontend | http://localhost:5100 |
| Backoffice Backend | http://localhost:5200 |
| Mock Service | http://localhost:3031 |
| Report Service | http://localhost:3000 |
| Form Service | http://localhost:3300 |
| DB Service | http://localhost:5001 |
| Config Service | http://localhost:5556 |
| User Management | http://localhost:8082 |
| Registry Service | http://localhost:8080 |
| Jaeger UI | http://localhost:16686 |
| Domain API Service | http://localhost:3032 |

## Experiencing it
You can experience the Protocol Workbench here: https://workbench.ondc.tech/home

We’d love to hear your feedback, suggestions, questions, or thoughts — feel free to reach out with anything at PW-support@ondc.org



# automation framework
Signing_private_key: ATL8IjR0EazALCFrA4PTTaTI4Xzx+dBN9xvwUSfCikCKdrsK5g5HymMvzDKzc/kQYmmQTaQhTZS1n0DfPWC+cw==
Signing_public_key:  ina7CuYOR8pjL8wys3P5EGJpkE2kIU2UtZ9A3z1gvnM=
Crypto_Privatekey:   MC4CAQAwBQYDK2VuBCIEIAgGK8YFrauA87XhrePFGGIiPLVmA3M0M8VAiAK+mshX
Crypto_Publickey:    MCowBQYDK2VuAyEAzfkKWnGhpm3HjxIqcbMEXt8m2EiIX+7a8WAhlX3wMCY=
