# frozen_string_literal: true

require 'date'
require 'fastlane/action'
require_relative '../helper/xcresult_to_junit_helper'

module Fastlane
  module Actions
    class XcresultToJunitAction < Action
      def self.run(params)
        UI.message('The xcresult_to_junit plugin has started!')
        result = Helper::XcresultToJunitHelper.fetch_tests(params[:xcresult_path])

        devices = result['devices']
        test_plans = result['testNodes']
        map = {}
        junit_folder = Helper::XcresultToJunitHelper.save_device_details_to_file(params[:output_path], devices)
        test_suites = []

        test_plans.each do |test_plan|
          test_plan['children'].each do |test_bundle|
            test_bundle['children'].each do |test_suite|
              suite_name = test_suite['name']
              count = 0
              passed = 0
              failed = 0
              test_cases = []
              test_suite['children'].each do |test_case|
                duration = 0.0
                duration = test_case['duration'].sub('s', '').to_f if test_case['duration']
                full_testcase_name = test_case['name'].sub('()', '')
                tags = full_testcase_name.split('_')[1..]
                testcase = { name: full_testcase_name, time: duration }
                count += 1
                if test_case['result'] == 'Passed'
                  passed += 1
                elsif test_case['result'] == 'Failed'
                  failed += 1
                  testcase[:failure] ||= []
                  testcase[:failure_location] ||= []
                  test_case['children'].each do |failure|
                    if failure['nodeType'] == 'Repetition'
                      failure['children'].each do |retry_failure|
                        testcase[:failure] << retry_failure['name']
                        testcase[:failure_location] << failure['name']
                      end
                    elsif failure['nodeType'] == 'Failure Message'
                      testcase[:failure] << failure['name']
                      testcase[:failure_location] << failure['name'].split(': ')[0]
                    end
                  end
                end
                test_cases << testcase
                map["#{suite_name}.#{full_testcase_name}"] = { 'files' => [], 'tags' => tags }
              end
              suite = { name: suite_name.to_s, count: count, failures: failed, errors: 0, cases: test_cases }
              test_suites << suite
            end
          end
        end

        Helper::XcresultToJunitHelper.generate_junit(junit_folder, test_suites)
        attachments_folder = "#{junit_folder}/attachments"
        Helper::XcresultToJunitHelper.save_attachments(params[:xcresult_path], attachments_folder)

        test_attachments = Helper::XcresultToJunitHelper.fetch_attachment_manifest(attachments_folder)

        test_attachments.each do |test_attachment|
          test_identifier = test_attachment['testIdentifier']
          folder_name = test_identifier.sub('()', '').sub('/', '.')

          test_attachment['attachments'].reverse().each do |attachment|
            name = attachment['suggestedHumanReadableName']
            filename = attachment['exportedFileName']
            mime_type = 'image/png'
            mime_type = 'text/plain' if filename.end_with?('.txt')
            timestamp = attachment['timestamp']
            map[folder_name] ||= { 'files' => [] }
            map[folder_name]['files'].push({ 'description' => name, 'mime-type' => mime_type, 'path' => filename,
                                             'timestamp' => timestamp })
          end
        end

        Helper::XcresultToJunitHelper.save_screenshot_mapping(map, attachments_folder)
        UI.message('The xcresult_to_junit plugin has finished!')
      end

      def self.description
        'Produces junit xml files from Xcode 11+ xcresult files'
      end

      def self.authors
        ['Shane Birdsall']
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        'By using the xcresulttool this plugin parses xcresult files and generates junit reports to be used with other tools to display iOS test results'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcresult_path,
                                       env_name: 'XCRESULT_TO_JUNIT_XCRESULT_PATH',
                                       description: 'The path to the xcresult file',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :output_path,
                                       env_name: 'XCRESULT_TO_JUNIT_OUTPUT_PATH',
                                       description: 'The path where the output will be placed',
                                       optional: false,
                                       type: String)
        ]
      end

      def self.is_supported?(platform)
        %i[ios mac].include?(platform)
      end
    end
  end
end
