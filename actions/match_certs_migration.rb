module Fastlane
  module Actions
    module SharedValues
      MATCH_CERTS_MIGRATION_CUSTOM_VALUE = :MATCH_CERTS_MIGRATION_CUSTOM_VALUE
    end

    class MatchCertsMigrationAction < Action
      attr_accessor :all_certs_dir

      def self.run(params)
        require 'spaceship'
        require 'match'
        require 'fileutils'

        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message "Action: exsiting_certs_migration Params: username => #{params[:username]} app_identifier => #{params[:app_identifier]}  type => #{params[:type]}"

        Spaceship.login(params[:username])
        Spaceship.select_team

        all_certs_dir = Dir.mktmpdir
        current_git_dir = Dir.mktmpdir

        get_all_certs(params[:git_url], all_certs_dir, current_git_dir)

        dest_branch_name = dest_remote_branch_name(params)
        remote_branches = `git branch -a`.split("\n")
        remote_branches.each {|branch| 
          if branch.include?(dest_branch_name)
            UI.success ("👏👏👏 Your certificate are under the gitlab, next it will execute the match...."); return
          end
        }
        
 
        matched_cert_id = remote_matched_cert_id(cert_type(params[:type]))

        Dir.foreach(all_certs_dir) do |file|
          if file !="." and file !=".."
            cert_id = file.split('.')[0]
            if matched_cert_id == cert_id
              UI.success "😁😁😁 The certificate that can be reused is found, cert_id => #{cert_id}"; break;
            end
          end
        end

        UI.success "💔💔💔 The certificate of type: #{params[:type]} can not be found or The certificate is going to expire, the next step: Match will create a new one for you..." && return unless matched_cert_id != nil

        cp_certs(current_git_dir, all_certs_dir, params[:type], dest_branch_name, matched_cert_id)

        git_commit_changes(current_git_dir, params, dest_branch_name)
      end


      # copy certs and p12 which named `matched_id` to `current_git_dir`
      def self.cp_certs(current_git_dir, all_certs_dir, type, dest_branch_name, matched_id)
        # ensure your there are only README.md and match_version.txt
        git_command_executor("git checkout '.'")
        git_command_executor("git checkout 'master' ")
        git_command_executor("git checkout -b #{dest_branch_name}")


        certs_dir = "#{current_git_dir}/certs/#{type}"
        FileUtils.mkdir_p(certs_dir)

        FileUtils.cp_r(Dir.glob("#{all_certs_dir}/#{matched_id}.*"), certs_dir)
      end

 
      # get all the certs exist in your remote git repo then copy them to `all_certs_dir`
      def self.get_all_certs(git_url, all_certs_dir, current_git_dir)
        git_command_executor("git clone '#{git_url}' '#{current_git_dir}'")
        Dir.chdir(current_git_dir)
        
        remote_branches = git_command_executor("git branch -a | grep remotes | grep -v HEAD | grep -v master").split("\n")

        remote_branches.each { |branch|
          git_command_executor("git checkout '.'")
          git_command_executor("git checkout #{branch}")

          Match::Encrypt.new.decrypt_repo(path: current_git_dir, git_url: git_url, manual_password: nil)

          if File.exist?("#{current_git_dir}/certs")
            FileUtils.cp_r(Dir.glob("#{current_git_dir}/certs/**/*.cer"), all_certs_dir)
            FileUtils.cp_r(Dir.glob("#{current_git_dir}/certs/**/*.p12"), all_certs_dir)
          end
        }
      end

      # return cert type with type
      def self.cert_type(type) 
        cert_type = "Development" if type == "development"
        cert_type = "Inhouse"     if type == "enterprise"
        cert_type = "Production"  if ["adhoc", "appstore", "distribution"].include?(type)

        return cert_type
      end


      def self.git_add_config(user_name, user_email, path)
        commands = []
        commands << "git config user.name \"#{user_name}\"" unless user_name.nil?
        commands << "git config user.email \"#{user_email}\"" unless user_email.nil?

        return if commands.empty?

        UI.message "Add git user config to local git repo..."
        Dir.chdir(path) do
          commands.each do |command|
            git_command_executor(command)
          end
        end
      end

      # git command executor 
      def self.git_command_executor(command)
        FastlaneCore::CommandExecutor.execute(command: command,
                                            print_all: FastlaneCore::Globals.verbose?,
                                        print_command: FastlaneCore::Globals.verbose?)
      end

      # custom git commit message
      def self.git_commit_changes(current_git_dir, params, dest_branch_name)
        commit_message = ["[Update]", "certs_migration", "#{params[:type]}"].join(" ")
        Match::GitHelper.commit_changes(current_git_dir, commit_message, params[:git_url], dest_branch_name)
      end


      # generate a branch name with app_identifier and cert type
      def self.dest_remote_branch_name(params)
        return ["#{params[:app_identifier]}", "#{params[:type]}"].join(".")
      end


      # get remote cert_id according to apple_id and cert_type, and the cert cannot be expired after a month in additional
      def self.remote_matched_cert_id(type)
        cert_id = nil

        Spaceship.certificate.all.each do |cert|
          cert_type = Spaceship::Portal::Certificate::CERTIFICATE_TYPE_IDS[cert.type_display_id].to_s.split("::")[-1]
          if cert_type == type && cert.expires - Time.now > 3600 * 24 * 30
            cert_id = cert.id; break
          end
          
        end

        return cert_id
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "migration an existing certificate on developer.apple.com to prevent from recreating a new certificate by match"
      end

      def self.details
        # Optional:
        # this is your chance to provide a more detailed description of this action
        "You can use this action to do cool things..."
      end

      def self.available_options
        # Define all options your action supports. 
        
        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :git_url,
                                       env_name: "FL_MATCH_CERTS_MIGRATION_API_TOKEN", # The name of the environment variable
                                       description: "the developer git_url", # a short description of this parameter
                                       is_string: true,
                                       ),
          FastlaneCore::ConfigItem.new(key: :username,
                                       env_name: "FL_MATCH_CERTS_MIGRATION_API_TOKEN", # The name of the environment variable
                                       description: "the developer username", # a short description of this parameter
                                       is_string: true,
                                       verify_block: proc do |value|
                                          UI.user_error!("No API token for MatchCertsMigrationAction given, pass using `api_token: 'token'`") unless (value and not value.empty?)
                                          # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :type,
                                       env_name: "FL_MATCH_CERTS_MIGRATION_DEVELOPMENT",
                                       description: "the certificate type you will verify",
                                       is_string: false, # true: verifies the input is a string, false: every kind of value
                                       verify_block: proc do |value|

                                          UI.user_error!("No API token for MatchCertsMigrationAction given, pass using `type: 'type'`") unless (['development', 'appstore', 'enterprise', 'adhoc', 'distribution'].include?(value))
                                          # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :app_identifier,
                                       env_name: "FL_MATCH_CERTS_MIGRATION_DEVELOPMENT",
                                       description: "the certificate type you will verify",
                                       is_string: false, # true: verifies the input is a string, false: every kind of value
                                       ),
        ]
      end

      def self.output
        # Define the shared values you are going to provide
        # Example
        [
          ['MATCH_CERTS_MIGRATION_CUSTOM_VALUE', 'A description of what this value contains']
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["HiIgor"]
      end

      def self.is_supported?(platform)
        # you can do things like
        # 
        #  true
        # 
        #  platform == :ios
        # 
        #  [:ios, :mac].include?(platform)
        # 

        platform == :ios
      end
    end
  end
end