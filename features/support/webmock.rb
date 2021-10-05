require "webmock/cucumber"

allowed_hosts = ["chromedriver.storage.googleapis.com"]
WebMock.disable_net_connect! allow_localhost: true, allow: allowed_hosts
