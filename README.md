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

## Experiencing it
You can experience the Protocol Workbench here: https://workbench.ondc.tech/home

We’d love to hear your feedback, suggestions, questions, or thoughts — feel free to reach out with anything at PW-support@ondc.org
