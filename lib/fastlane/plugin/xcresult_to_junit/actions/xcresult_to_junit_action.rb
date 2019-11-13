require 'fastlane/action'
require_relative '../helper/xcresult_to_junit_helper'

module Fastlane
  module Actions
    class XcresultToJunitAction < Action
      def self.run(params)
        UI.message("The xcresult_to_junit plugin has started!")
        all_results = Helper::XcresultToJunitHelper.load_results(params[:xcresult_path])['actions']['_values']
        all_results.each do |test_run|
          if test_run['actionResult']['testsRef'] # Skip if section has no testRef data as this means its not a test run
            test_run_id = test_run['actionResult']['testsRef']['id']['_value']
            all_tests = Helper::XcresultToJunitHelper.load_object(params[:xcresult_path], test_run_id)['summaries']['_values'][0]['testableSummaries']['_values']
            test_suites = []
            all_tests.each do |target|
              target_name = target['targetName']['_value']
              unless target['tests']
                failure_summary = target['failureSummaries']['_values'][0]
                test_suites << { name: target_name, error: failure_summary['message']['_value'] }
                next
              end
              test_classes = target['tests']['_values'][0]['subtests']['_values'][0]['subtests']['_values']
              test_classes.each do |test_class|
                suite = { name: "#{target_name}.#{test_class['name']['_value']}", cases: [] }
                if test_class['subtests']
                  test_class['subtests']['_values'].each do |test|
                    duration = 0
                    duration = test['duration']['_value'] if test['duration']
                    testcase = { name: test['name']['_value'], time: duration }
                    if test['testStatus']['_value'] == 'Failure'
                      failure = Helper::XcresultToJunitHelper.load_object(params[:xcresult_path], test['summaryRef']['id']['_value'])['failureSummaries']['_values'][0]
                      filename = failure['fileName']['_value']
                      message = failure['message']['_value']
                      if filename == '<unknown>'
                        testcase[:error] = message
                      else
                        testcase[:failure] = message
                        testcase[:failure_location] = "#{filename}:#{failure['lineNumber']['_value']}"
                      end
                    end
                    suite[:cases] << testcase
                  end
                end
                suite[:count] = suite[:cases].size
                suite[:failures] = suite[:cases].count { |testcase| testcase[:failure] }
                suite[:errors] = suite[:cases].count { |testcase| testcase[:error] }
                test_suites << suite
              end
            end
            junit_folder = Helper::XcresultToJunitHelper.save_device_details_to_file(params[:output_path], test_run['runDestination'])
            Helper::XcresultToJunitHelper.generate_junit(junit_folder, test_suites)
          end
        end
        UI.message("The xcresult_to_junit plugin has finished!")
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
        "By using the xcresulttool this plugin parses xcresult files and generates junit reports to be used with other tools to display iOS test results"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcresult_path,
            env_name: "XCRESULT_TO_JUNIT_XCRESULT_PATH",
            description: "The path to the xcresult file",
            optional: false,
            type: String),
            FastlaneCore::ConfigItem.new(key: :output_path,
              env_name: "XCRESULT_TO_JUNIT_OUTPUT_PATH",
              description: "The path where the output will be placed",
              optional: false,
              type: String)
            ]
          end
          
          def self.is_supported?(platform)
            [:ios, :mac].include?(platform)
          end
        end
      end
    end
