#!/usr/bin/env bash
set -e
set -o pipefail

chown -R deploy:deploy /home/deploy/bops/releases/<%= release %>

reapply-sysadmins

su - deploy <<'EOF'
ln -nfs /home/deploy/bops/shared/tmp /home/deploy/bops/releases/<%= release %>/tmp
ln -nfs /home/deploy/bops/shared/log /home/deploy/bops/releases/<%= release %>/log
ln -nfs /home/deploy/bops/shared/bundle /home/deploy/bops/releases/<%= release %>/vendor/bundle
ln -nfs /home/deploy/bops/shared/packs /home/deploy/bops/releases/<%= release %>/public/packs
ln -s /home/deploy/bops/releases/<%= release %> /home/deploy/bops/current_<%= release %>
mv -Tf /home/deploy/bops/current_<%= release %> /home/deploy/bops/current
cd /home/deploy/bops/current && bundle install --without development test --deployment --quiet
cd /home/deploy/bops/current && bundle exec rake db:migrate
cd /home/deploy/bops/current && yarn install
cd /home/deploy/bops/current && bundle exec rake assets:precompile
cd /home/deploy/bops/current && rm -rf node_modules
if [ ${SERVER_TYPE} = "worker" ] ; then cd /home/deploy/bops/current && bundle exec whenever -w ; else echo not running whenever ; fi
EOF

# Enable services if they have not been previously enabled
systemctl is-active --quiet bops.service || systemctl enable bops.service
