require 'fastlane/action'
require_relative '../helper/redmine_upload_helper'

module Fastlane
  module Actions
    module SharedValues
      REDMINE_UPLOAD_FILE_TOKEN = :REDMINE_UPLOAD_FILE_TOKEN
      REDMINE_UPLOAD_FILE_NAME = :REDMINE_UPLOAD_FILE_NAME
    end
    class RedmineUploadAction < Action
      def self.run(params)
        require 'net/http'
        require 'net/http/uploadprogress'
        require 'uri'
        require 'json'

        # getting parameters
        file_path = params[:file_path]
        file_name = File.basename(file_path) unless file_path == nil
        
        Actions.lane_context[SharedValues::REDMINE_UPLOAD_FILE_NAME] = file_name

        redmine_url = params[:redmine_host]
        api_key = params[:redmine_api_key]
        username = params[:redmine_username]
        password = params[:redmine_password]

        upload_content_uri = URI.parse(redmine_url+'/uploads.json')
        UI.message("Start file upload \"#{file_name}\" to Redmine API #{upload_content_uri}")
  
        token = nil
        response_upload_content = nil
        File.open(file_path, 'rb') do |io|
          # Create the HTTP objects
          http_upload_content = Net::HTTP.new(upload_content_uri.host, upload_content_uri.port)
          request_upload_content = Net::HTTP::Post.new(upload_content_uri.request_uri)

          request_upload_content["Content-Type"] = "application/octet-stream"
          unless api_key == nil 
            request_upload_content["X-Redmine-API-Key"] = "#{api_key}"
          end
          unless username == nil || password == nil
            request_upload_content.basic_auth username, password
          end

          request_upload_content.content_length = io.size
          request_upload_content.body_stream = io
          # print upload progress
          Net::HTTP::UploadProgress.new(request_upload_content) do |progress|
            printf("\rUploading \"#{file_name}\"...  #{ 100 * progress.upload_size / io.size }%")
          end
          # Send the request
          response_upload_content = http_upload_content.request(request_upload_content)
          printf("\n")
        end
        case response_upload_content
          when Net::HTTPSuccess
            # get token from upload content response
            token=JSON.parse(response_upload_content.body)['upload']['token']
            UI.success("Content uploaded! File token released: #{token}")
            Actions.lane_context[SharedValues::REDMINE_UPLOAD_FILE_TOKEN] = token
          else
            UI.error(response_upload_content.value)
          end
      end

      def self.description
        "A fastlane plugin to upload file contents to Redmine"
      end

      def self.authors
        ["Mattia Salvetti"]
      end

      def self.output
        [
          ['REDMINE_UPLOAD_FILE_TOKEN', 'Token release as response of redmine POST /uploads.json'],
          ['REDMINE_UPLOAD_FILE_NAME', 'Uploading file name']
        ]
      end

      def self.return_value
        "Returns a token released from redmine http POST to /uploads.json."
      end

      def self.details
        # Optional:
        "This plugin uses Redmine REST API to attach a generic file and release a token to use for attachment binding to any Redmine entity. It makes a http request to a redmine host POST /uploads.json
        See APIs documentations at http://www.redmine.org/projects/redmine/wiki/Rest_api"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :redmine_host,
                                  env_name: "REDMINE_HOST",
                               description: "Redmine host where upload file. e.g. ",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :redmine_username,
                                  env_name: "REDMINE_USERNAME",
                               description: "Redmine username (optional). An API key can be provided instead",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :redmine_password,
                                  env_name: "REDMINE_PASSWORD",
                               description: "Redmine password (optional). An API key can be provided instead",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :redmine_api_key,
                                  env_name: "REDMINE_API_KEY",
                               description: "Redmine API key (optional). username and password can be provided instead",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :file_path,
                                  env_name: "FILE_PATH",
                               description: "Local path of file to upload to redmine",
                                  optional: false,
                                      type: String)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
