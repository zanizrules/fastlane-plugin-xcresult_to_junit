require 'fastlane_core/ui/ui'
require 'json'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class XcresultToJunitHelper
      def self.load_object(params, id)
        JSON.load FastlaneCore::CommandExecutor.execute(command: "xcrun xcresulttool get --format json --path #{params[:xcresult_path]} --id #{id}")
      end

      def self.load_results(params)
        JSON.load FastlaneCore::CommandExecutor.execute(command: "xcrun xcresulttool get --format json --path #{params[:xcresult_path]}")
      end
    end
  end
end
