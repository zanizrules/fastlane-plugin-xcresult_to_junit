require 'date'
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
            map = {}
            junit_folder = Helper::XcresultToJunitHelper.save_device_details_to_file(params[:output_path], test_run['runDestination'])
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
                suite_name = "#{target_name}.#{test_class['name']['_value']}"
                suite = { name: suite_name, cases: [] }
                if test_class['subtests']
                  test_class['subtests']['_values'].each do |test|
                    duration = 0
                    duration = test['duration']['_value'] if test['duration']
                    testcase_name = test['name']['_value'].tr('()', '')
                    tags = testcase_name.split('_')[1..-1]
                    testcase_name = testcase_name.split('_').first
                    testcase = { name: testcase_name, time: duration }
                    map["#{suite_name}.#{testcase_name}"] = {'files' => [], 'tags' => tags}

                    if defined?(test['summaryRef']['id']['_value'])
                      summaryRef = test['summaryRef']['id']['_value']
                      ref = Helper::XcresultToJunitHelper.load_object(params[:xcresult_path], summaryRef)
                      if defined?(ref['activitySummaries']['_values'])
                        ref['activitySummaries']['_values'].each do |summary|
                          if summary['attachments']
                            summary['attachments']['_values'].each do |attachment|
                              timestamp = DateTime.parse(attachment['timestamp']['_value']).to_time.to_i
                              name = attachment['name']['_value']
                              folder_name = "#{suite_name}.#{testcase_name}"
                              id = attachment['payloadRef']['id']['_value']
                              Helper::XcresultToJunitHelper.fetch_screenshot(params[:xcresult_path], "#{junit_folder}/attachments/#{folder_name}", "#{id}.png", id)
                              map[folder_name]['files'].push({'description' => name, 'mime-type' => 'image/png', 'path' => "#{folder_name}/#{id}.png", 'timestamp' => timestamp})
                            end
                          end
                        end
                      end
                    end

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
            Helper::XcresultToJunitHelper.generate_junit(junit_folder, test_suites)
            Helper::XcresultToJunitHelper.save_screenshot_mapping(map, "#{junit_folder}/attachments/")
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
