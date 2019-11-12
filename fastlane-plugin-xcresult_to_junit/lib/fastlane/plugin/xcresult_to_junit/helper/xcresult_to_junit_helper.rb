require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class XcresultToJunitHelper
      # class methods that you define here become available in your action
      # as `Helper::XcresultToJunitHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the xcresult_to_junit plugin helper!")
      end
    end
  end
end
