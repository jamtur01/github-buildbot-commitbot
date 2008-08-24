# Github-Builbot CommitBot 
# v0.1 - 22/08/2008:  Initial release
# - heavily draws on Adam Jacob's Github Commit Email Bot

# License:: GNU General Public License version 2 or later
#
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software
# Foundation; either version 2 of the License, or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

require 'rubygems'
require 'json'
require 'open-uri'
require 'socket'

Merb::Config.use { |c|
  c[:project]             = "Puppet",
  c[:buildhost]           = "BuildBot",
  c[:git_dir]             = "/sources/puppet/.git",
  c[:git_buildbot]        = "/buildbot/git_buildbot.py",
  c[:tmp_commit_file]     = "/tmp/commit",
  c[:framework]           = {},
  c[:session_store]       = 'none',
  c[:exception_details]   = true
}

Merb::Router.prepare do |r|
  r.resources :commit
  r.match('/').to(:controller => 'commit', :action =>'index')
end

class Commit < Merb::Controller

  def index
    results =  "I accept github post-commits for #{Merb::Config[:project]}"
    results << " and send them to #{Merb::Config[:buildhost]}.  POST to /commit."
    results
  end

  def create
    # parse and assign variables
    ch = JSON.parse(params[:payload])
    before = ch['before']
    after = ch['after']
    ref = ch['ref']

    # Set Git directory
    ENV['GIT_DIR'] = Merb::Config[:git_dir]

    # Fetch commits
    %x{git fetch origin}

    # create commit
    c = "#{before} " + "#{after} " + "#{ref}"

    # Write temporary commit to file
    f = File.open(Merb::Config[:tmp_commit_file], 'w')
    f.write(c)
    f.close

    # Process change
    %x{#{Merb::Config[:git_buildbot]} < #{Merb::Config[:tmp_commit_file]}}

  end
end

