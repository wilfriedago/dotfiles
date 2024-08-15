# /bin/sh

mkdir -p ~/.docker/cli-plugins
ln -sfn /opt/homebrew/opt/docker-compose/bin/docker-compose ~/.docker/cli-plugins/docker-compose

colima start --cpu 1 --memory 2 --disk 10 --vm-type=vz --vz-rosetta

brew services start colima
