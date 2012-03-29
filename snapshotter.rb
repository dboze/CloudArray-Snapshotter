#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'httparty'
require 'logger'
require 'crack'

config_file = File.join(File.dirname(__FILE__), "config.yml")
CONFIG = YAML.load(File.read(config_file))
USERNAME = CONFIG['credentials']['username']
PASSWORD = CONFIG['credentials']['password']
log = Logger.new('snapshot.log')

class CloudArray
  include HTTParty
  base_uri CONFIG['setup']['cloudarray']
  format :xml
  
  def self.volumes
    Crack::XML.parse(CloudArray.get("/rest/list_volumes", 
      :query => {:username => USERNAME, :password => PASSWORD}).body)
    rescue Timeout::Error => e
      return "Server timeout."
  end
  
  def self.take_snaps(volume)
    CloudArray.get("/rest/new_snapshot", 
      :query => {:when => CONFIG['setup']['when'], :volume => volume, :username => USERNAME, :password => PASSWORD}).body
    rescue Timeout::Error => e
      return "Volume will snapshot once flush completes."
  end
end

CloudArray.volumes['result']['volumes']['volume'].each do |volume|
  unless CONFIG['exclusions'].include? volume['name']
    log.debug "Snapshotting " + volume['name'] + "..."
    log.debug CloudArray.take_snaps(volume['name']).gsub(/<\/?[^>]*>/, "")
  else
    log.debug "Excluding volume: " + volume['name']
  end
end