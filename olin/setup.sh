# Installs Rocket.Chat and configures VPN
## Inspired by
## - https://rocket.chat/docs/installation/automation-tools/vagrant/
## - https://github.com/Bogidon/Rocket.Chat/blob/develop/.sandstorm/setup.sh

# Make script safer (https://coderwall.com/p/fkfaqq/safer-bash-scripts-with-set-euxo-pipefail)
set -x
set -euvo pipefail

# Install Node 8.x LTS, and other dependencies
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
sudo apt-get update
sudo apt-get install -y build-essential nodejs mongodb-org unzip git

# Configure mongo
sudo chown $(whoami) /etc/mongod.conf
sudo cat > /etc/mongod.conf <<EOL
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 127.0.0.1

replication:
      replSetName:  "001-rs"
EOL
sudo systemctl enable mongod
sudo systemctl restart mongod
mongo --eval "rs.initiate()" || true

# Install Meteor
curl https://install.meteor.com/ | sh

# PRODUCTION
if [ "$OLINCHAT_ENV" == "PRODUCTION" ]
then
    # pm2 allows auto starting server
    sudo npm install pm2 -g
    sudo pm2 startup

    sudo mkdir -p /var/log/rocket.chat
    sudo chmod 755 /var/log/rocket.chat

    # Deploy
    MONGO_URL=mongodb://localhost:27017/rocketchat
    MONGO_OPLOG_URL=mongodb://localhost:27017/local?replicaSet=001-rs
    ROOT_URL=http://localhost:3000
    PORT=3000

    # Download source
    sudo rm -rf /opt/rocketchat
    sudo mkdir /opt/rocketchat
    sudo chown $(whoami) /opt/rocketchat
    git clone -b olin-master --depth 1 -- https://github.com/Bogidon/Rocket.Chat /opt/rocketchat

    # Build
    cd /opt/rocketchat
    export TOOL_NODE_FLAGS="--max-old-space-size=6000" # need more RAM for building
    meteor npm install --production
    meteor build --server-only --server "$HOST" --directory .

    # Install some more deps
    cd /opt/rocketchat/bundle/programs/server
    npm install --production

    # Load pm2
    cd /opt/rocketchat/bundle
    rm -f pm2-rocket-chat.json
    cat > pm2-rocket-chat.json <<EOL
{
    "apps": [{
        "name": "rocket.chat",
        "script": "/opt/rocketchat/bundle/main.js",
        "out_file": "/var/log/rocket.chat/app.log",
        "error_file": "/var/log/rocket.chat/err.log",
        "port": "$PORT",
        "env": {
            "NODE_ENV": "production",
            "MONGO_URL": "$MONGO_URL",
            "MONGO_OPLOG_URL": "$MONGO_OPLOG_URL",
            "ROOT_URL": "$ROOT_URL",
            "PORT": "$PORT"
        }
    }]
}
EOL

    sudo pm2 start pm2-rocket-chat.json
    sudo pm2 save

    # VPN -- last because causes disconnect (for now)
    if [[ $OVPN_FILE ]]
    then
        sudo apt-get install -y openvpn
        sudo openvpn --config "/home/vagrant/$OVPN_FILE"
    fi
fi
