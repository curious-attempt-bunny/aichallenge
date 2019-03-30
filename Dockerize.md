# Setup steps

    git submodule init
    git submodule update
    docker build -t ants-manager .
    docker run -it ants-manager /bin/bash
