# Running the Project Locally

This guide provides instructions to set up and run the project locally.

## Prerequisites

1. **Docker**: Ensure Docker is installed on your machine. [Install Docker](https://docs.docker.com/get-docker/) for running services inside a container.

2. **Node.js**: Ensure Node.js is installed on your machine. [Install Node.js](https://nodejs.org/) for running services directly.

## Steps to Run the Project

### 1. Clone the Repository

```bash
git clone https://github.com/your-repo/automation-framework.git
cd automation-framework
```

### 2. Initialize Submodules

```bash
git submodule update --init --recursive
```

### 3. Set Up Environment Variables

- For running services directly - Create a `.env` file in the root directory and add the necessary environment variables. Refer to the `.env.example` file for the required variables.
- For running with docker - env has been already setup to communicate internally between containers at docker-env folder

### 4. Build and Start Services

Use Docker Compose to build and start the services.

```bash
docker-compose up --build
```

For running services directly use 
```bash
 npm run dev
 ```
 

### 5. Access the Services

- **Backoffice URL**: [http://localhost:5100/backoffice-frontend](http://localhost:5100/backoffice-frontend)
- **Automation UI**: [http://localhost:3035](http://localhost:3035)

### Additional Information

- For detailed logs and metrics integration, refer to the [automation-monitoring README](./automation-monitoring/README.md).
- For specific service configurations, refer to the respective service directories readme.md.

