module Fastlane
  module Actions
    class RedmineFilePostAction < Action
      def self.run(params)
        require 'net/http'
        require 'uri'
        require 'json'

        redmine_url = params[:redmine_host]
        api_key = params[:redmine_api_key]
        username = params[:redmine_username]
        password = params[:redmine_password]
        project = params[:redmine_project]
        token = params[:file_token]
        file_name = params[:file_name]
        file_version = params[:file_version]
        file_description = params[:file_description]

        upload_file_uri = URI.parse(redmine_url + "/projects/#{project}/files.json")
        # prepare request with token previously got from upload
        json_content = {
          "file" = {
            "token" => token
          }
        }

        json_content["file"]["filename"] = file_name unless file_name = nil
        json_content["file"]["version_id"] = file_version unless file_version = nil
        json_content["file"]["description"] = file_description unless file_description = nil
            
        file_body = JSON.pretty_generate(json_content)
        UI.message("File post with content #{file_body}")

        # Create the HTTP objects
        http_file_post = Net::HTTP.new(upload_file_uri.host, upload_file_uri.port)
        request_file = Net::HTTP::Post.new(upload_file_uri.request_uri)

        request_file["Content-Type"] = "application/json"
        unless api_key.nil?
          request_file["X-Redmine-API-Key"] = api_key.to_s
        end
        unless username.nil? || password.nil?
          request_file.basic_auth(username, password)
        end

        request_file.body = file_body
          # Send the request
        request_file = http_file_post.request(request_file)

        case request_file
        when Net::HTTPSuccess
          UI.success("File uploaded successfully")
        else
          UI.error(request_file.value)
        end
      end

      def self.description
        "Uploads a file in a Redmine Files section of a given Redmine project"
      end

      def self.authors
        ["Mattia Salvetti"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Uploads a file in a Redmine host under files section of specified Redmine project."
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
          FastlaneCore::ConfigItem.new(key: :redmine_project,
                                  env_name: "REDMINE_PROJECT",
                               description: "Project of redmine",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :file_token,
                                  env_name: "FILE_TOKEN",
                               description: "Token of file previously released",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :file_name,
                                  env_name: "FILE_NAME",
                               description: "FIle name",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :file_version,
                                  env_name: "FILE_VERSION",
                               description: "Version of file",
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :file_description,
                                  env_name: "FILE_DESCRIPTION",
                               description: "Description of file to upload",
                                  optional: true,
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
