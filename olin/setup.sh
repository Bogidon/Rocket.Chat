# Installs Rocket.Chat and configures VPN
## Inspired by
## - https://rocket.chat/docs/installation/automation-tools/vagrant/
## - https://github.com/Bogidon/Rocket.Chat/blob/develop/.sandstorm/setup.sh

# Make script safer (https://coderwall.com/p/fkfaqq/safer-bash-scripts-with-set-euxo-pipefail)
set -x
set -euvo pipefail

# Install Node 8.x LTS, and other dependencies
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
apt-get install -y build-essential nodejs mongodb unzip

ln -f -s /usr/bin/nodejs /usr/bin/node
ln -f -s /usr/bin/nodejs /usr/sbin/node

# Install Meteor
curl https://install.meteor.com/ | sh

# PRODUCTION
if [ "$OLINCHAT_ENV" == "PRODUCTION" ]
then
	
	# pm2 allows auto starting server
	npm install pm2 -g
	pm2 startup

	mkdir -p /var/log/rocket.chat
fi



# DEPLOY
# HOST=http://your_hostname.com
# MONGO_URL=mongodb://localhost:27017/rocketchat
# MONGO_OPLOG_URL=mongodb://localhost:27017/local
# ROOT_URL=http://localhost:3000
# PORT=3000

# cd /vagrant
# meteor build --server "$HOST" --directory .

# cd /vagrant/bundle/programs/server
# npm install

# cd /vagrant/bundle
# rm -f pm2-rocket-chat.json
# echo '{'                                                     > pm2-rocket-chat.json
# echo '  "apps": [{'                                         >> pm2-rocket-chat.json
# echo '    "name": "rocket.chat",'                           >> pm2-rocket-chat.json
# echo '    "script": "/vagrant/bundle/main.js",' 			>> pm2-rocket-chat.json
# echo '    "out_file": "/var/log/rocket.chat/app.log",'      >> pm2-rocket-chat.json
# echo '    "error_file": "/var/log/rocket.chat/err.log",'    >> pm2-rocket-chat.json
# echo "    \\"port\\": \\"$PORT\\","                         >> pm2-rocket-chat.json
# echo '    "env": {'                                         >> pm2-rocket-chat.json
# echo "      \\"MONGO_URL\\": \\"$MONGO_URL\\","             >> pm2-rocket-chat.json
# echo "      \\"MONGO_OPLOG_URL\\": \\"$MONGO_OPLOG_URL\\"," >> pm2-rocket-chat.json
# echo "      \\"ROOT_URL\\": \\"$ROOT_URL\\","               >> pm2-rocket-chat.json
# echo "      \\"PORT\\": \\"$PORT\\""                        >> pm2-rocket-chat.json
# echo '    }'                                                >> pm2-rocket-chat.json
# echo '  }]'                                                 >> pm2-rocket-chat.json
# echo '}'                                                    >> pm2-rocket-chat.json

# pm2 start pm2-rocket-chat.json
# pm2 save