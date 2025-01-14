#
# Copyright:: Copyright (c) 2017 GitLab Inc.
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

# Configure Prometheus Services
Prometheus.services.each do |service|
  cookbook_name = SettingsDSL::Utils.hyphenated_form(service)
  if node['monitoring'][service]['enable']
    include_recipe "monitoring::#{cookbook_name}"
  else
    include_recipe "monitoring::#{cookbook_name}_disable"
  end
end
