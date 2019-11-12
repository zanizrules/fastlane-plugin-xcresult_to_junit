require 'fastlane/action'
require_relative '../helper/xcresult_to_junit_helper'

module Fastlane
  module Actions
    class XcresultToJunitAction < Action
      def self.run(params)
        UI.message("The xcresult_to_junit plugin is working!")
      end

      def self.description
        "Produces junit xml files from Xcode 11+ xcresult files"
      end

      def self.authors
        ["Shane Birdsall"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "By using the xcresulttool this plugin parses xcresult files and generates junit reports to be used with other tools to display iOS test results"
      end

      def self.available_options
        [
          # FastlaneCore::ConfigItem.new(key: :your_option,
          #                         env_name: "XCRESULT_TO_JUNIT_YOUR_OPTION",
          #                      description: "A description of your option",
          #                         optional: false,
          #                             type: String)
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
