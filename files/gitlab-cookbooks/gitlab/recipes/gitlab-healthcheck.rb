#
# Copyright:: Copyright (c) 2016 GitLab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

workhorse_helper = GitlabWorkhorseHelper.new(node)
flags = []

# If nginx is disabled we will use workhorse for the healthcheck
if node['gitlab']['nginx']['enable']
  listen_https = node['gitlab']['nginx']['listen_https']
  # Fallback to the setting derived from external_url
  listen_https = node['gitlab']['gitlab-rails']['gitlab_https'] if listen_https.nil?
  schema = listen_https ? 'https' : 'http'
  # Check first allowed_host, fallback to checking localhost
  allowed_hosts = node['gitlab']['gitlab-rails']['allowed_hosts']
  flags << "--header \"Host: #{allowed_hosts[0]}\"" unless allowed_hosts.empty?
  flags << '--insecure'
  host = "localhost:#{node['gitlab']['nginx']['listen_port']}"
else
  # Always use http for workhorse
  schema = 'http'
  use_socket = workhorse_helper.unix_socket?
  socket_path = use_socket ? node['gitlab']['gitlab-workhorse']['listen_addr'] : ''
  if use_socket
    flags << '--unix-socket'
    flags << socket_path
  else
    flags << '--insecure'
  end
  host = use_socket ? 'localhost' : node['gitlab']['gitlab-workhorse']['listen_addr']
end

template "/opt/gitlab/etc/gitlab-healthcheck-rc" do
  owner 'root'
  group 'root'
  variables(
    {
      url: "#{schema}://#{host}#{Gitlab['gitlab_rails']['gitlab_relative_url']}/help",
      flags: flags.join(' ')
    }
  )
end
