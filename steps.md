
  First time / switching domains:

  # 1. Start core stack (db-service needs to be up before push-to-db runs)
  docker compose up -d

  # 2. Build the domain api service
  #    (push-to-db step needs db-service running — that's why step 1 is first)
  ./scripts/build-api-service.sh draft-FIS12-2.3.0

  # 3. Fill in secrets
  #    docker-env/api-service-common.env — replace *_change_me values

  # 4. Start the api service alongside the running stack
  docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build

  After editing api-service/build-output/ (code change, no spec change):
  docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build

  After editing api-service/config/ (spec change):
  ./scripts/build-api-service.sh draft-FIS12-2.3.0   # regenerates build-output
  docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build

  Switching to a different domain:
  docker compose -f docker-compose.yml -f docker-compose.api.yml down  # stops api 
  service
  ./scripts/build-api-service.sh draft-RET10-1.2.5
  docker compose -f docker-compose.yml -f docker-compose.api.yml up -d --build
  
  The core docker compose up -d (without -f docker-compose.api.yml) always works as the
  base — api service is completely optional and additive on top.
