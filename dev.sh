#!/bin/bash

# clean up orphaned images and containers
docker image prune -f
docker container prune -f
docker network prune -f
docker volume prune -f

# current images and containers
docker container ls
docker image ls
docker volume ls

docker compose  up --build -d

echo "

    ###########################################################################

    SMPPEX Development Environment Loaded

    ###########################################################################

    mix deps.get  

    # console mode

    iex -S mix

    OR

    MIX_ENV=test mix test
    MIX_ENV=test mix test --color --trace

    # retest all test that failed previously
    MIX_ENV=test mix test --color --trace --failed

    # stop at first failure
    MIX_ENV=test mix test --color --trace --max-failures 1

    MIX_ENV=test mix test test/esme_test.exs
    MIX_ENV=test mix test test/esme_test.exs:40


    ###########################################################################
    # to safely shut down containers
    docker compose down

"
docker compose exec smppex bash