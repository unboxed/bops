#!/usr/bin/env bash
set -e
set -o pipefail

chown -R deploy:deploy /home/deploy/bops/releases/<%= release %>

su - deploy <<'EOF'
ln -nfs /home/deploy/bops/shared/tmp /home/deploy/bops/releases/<%= release %>/tmp
ln -nfs /home/deploy/bops/shared/log /home/deploy/bops/releases/<%= release %>/log
ln -nfs /home/deploy/bops/shared/bundle /home/deploy/bops/releases/<%= release %>/vendor/bundle
ln -nfs /home/deploy/bops/shared/packs /home/deploy/bops/releases/<%= release %>/public/packs
ln -s /home/deploy/bops/releases/<%= release %> /home/deploy/bops/current_<%= release %>
mv -Tf /home/deploy/bops/current_<%= release %> /home/deploy/bops/current
cd /home/deploy/bops/current && bundle install --without development test --deployment --quiet
cd /home/deploy/bops/current && bundle exec rake db:migrate
cd /home/deploy/bops/current && bundle exec rake assets:precompile
EOF
