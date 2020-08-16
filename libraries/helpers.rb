#
# Cookbook:: aptly
# Library:: helpers
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

module Aptly
  module Helpers
    def aptly_env
      { 'HOME' => node['aptly']['rootDir'], 'USER' => node['aptly']['user'] }
    end

    def gpg_command
      case node['platform']
      when 'debian'
        node['platform_version'].to_i < 9 ? 'gpg' : 'gpg1'
      when 'ubuntu'
        node['platform_version'].to_f < 18.04 ? 'gpg' : 'gpg1'
      end
    end

    def filter(f)
      f.empty? ? '' : " -filter '#{f}'"
    end

    def filter_with_deps(f)
      f == true ? ' -filter-with-deps' : ''
    end

    def with_installer(i)
      i == true ? ' -with-installer' : ''
    end

    def with_udebs(u)
      u == true ? ' -with-udebs' : ''
    end

    def architectures(arr)
      arr.empty? ? '' : " -architectures #{arr.join(',')}"
    end

    def mirror_info(m)
      return unless shell_out("aptly mirror -raw list | grep ^#{m}$",
        user: node['aptly']['user'], environment: aptly_env).exitstatus == 0
      cmd = shell_out("aptly mirror show #{m}", user: node['aptly']['user'], environment: aptly_env)
      # the output of aptly mirror show is broken into sections delimited
      # by a blank line. We're only interested in the first section
      output = cmd.stdout.split(/\n\n/).first
      # convert the output of the aptly mirror show command into a hash
      info = output.split(/\n/).map do |x|
        # the hash keys have spaces and hyphens replaced with underscore,
        # and periods are removed.
        k, v = x.split(/:\s*/, 2)
        [k.downcase().gsub('.', '').gsub(/(\s+|-)/, '_'), v]
      end.compact.to_h
      # convert the architectures to an array
      if info.key?('architectures')
        info['architectures'] = info['architectures'].split(/,\s*/)
      end
      # convert boolean values
      %w(download_sources download_udebs filter_with_deps).each do |k|
        if info.key?(k)
          info[k] = info[k] == 'yes'
        end
      end
      info
    end
  end
end

Chef::Recipe.include ::Aptly::Helpers
Chef::Resource.include ::Aptly::Helpers
