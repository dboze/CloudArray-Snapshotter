#!/usr/bin/env ruby

require 'rubygems'
require 'yaml'
require 'net/http'
require 'cgi'
require 'nokogiri'
require 'logger'

config_file = File.join(File.dirname(__FILE__), "config.yml")
config = YAML.load(File.read(config_file))
username = config['credentials']['username']
password = config['credentials']['password']
log = Logger.new('snapshot.log')

def http_get(domain,path,params)
  return Net::HTTP.get(domain, "#{path}?".concat(params.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&'))) if not params.nil?
  return Net::HTTP.get(domain, path)
  rescue Timeout::Error => e
    return "Volume will snapshot once flush completes."
end

auth_params = {:username => username, :password => password}
volumes = http_get(config['setup']['cloudarray'], "/rest/list_volumes", auth_params)

volumes = Nokogiri::XML(volumes)
volumes.xpath('/result/volumes/volume/name').each do |vol|
  unless config['exclusions'].include? vol.content
    snap_params = {:when => config['setup']['when'], :volume => vol.content, :username => username, :password => password}
    log.debug "Snapshotting " + vol.content + "..."
    log.debug http_get(config['setup']['cloudarray'], "/rest/new_snapshot", snap_params).gsub(/<\/?[^>]*>/, "")
  else
    log.debug "Excluding volume: " + vol.content
  end
end