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
apt-get install -y build-essential nodejs mongodb-org unzip git

# Install Meteor
curl https://install.meteor.com/ | sh

# PRODUCTION
if [ "$OLINCHAT_ENV" == "PRODUCTION" ]
then
    # VPN
    if [[ $OVPN_FILE ]]
    then
        apt-get install openvpn
        openvpn --config "$OVPN_FILE"
    fi

    # pm2 allows auto starting server
    npm install pm2 -g
    pm2 startup

    mkdir -p /var/log/rocket.chat
    chmod 755 /var/log/rocket.chat

    # Deploy
    MONGO_URL=mongodb://localhost:27017/rocketchat
    MONGO_OPLOG_URL=mongodb://localhost:27017/local?replicaSet=001-rs
    ROOT_URL=http://localhost:3000
    PORT=3000

    # Download source
    mkdir /opt/rocketchat
    chown $(whoami) /opt/rocketchat
    git clone -b=olin-master --depth=1 -- https://github.com/Bogidon/Rocket.Chat /opt/rocketchat

    # Build
    cd /opt/rocketchat
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

    pm2 start pm2-rocket-chat.json
    pm2 save
fi


# cd /opt/rocketchat
# meteor build --server "$HOST" --directory .

cd /vagrant/bundle/programs/server
npm install

