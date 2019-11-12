require 'fastlane/action'
require_relative '../helper/xcresult_to_junit_helper'
require 'json'
require 'fileutils'

module Fastlane
  module Actions
    class XcresultToJunitAction < Action
      def self.run(params)
        UI.message("The xcresult_to_junit plugin has started!")
        all_results = Helper::XcresultToJunitHelper.load_results(params)['actions']['_values']
        
        ## READ XCRESULT START
        all_results.each do |test_run|
          if test_run['actionResult']['testsRef'] # Skip if section has no testRef data as this means its not a test run
            test_run_id = test_run['actionResult']['testsRef']['id']['_value']
            device_destination = test_run['runDestination']
            device_udid = device_destination['targetDeviceRecord']['identifier']['_value']
            device_details = {
              'udid' => device_udid,
              'name' => device_destination['targetDeviceRecord']['modelName']['_value'],
              'os' => device_destination['targetDeviceRecord']['operatingSystemVersion']['_value']
            }.to_json

            all_tests = Helper::XcresultToJunitHelper.load_object(params, test_run_id)['summaries']['_values'][0]['testableSummaries']['_values']
            test_suites = []
            
            all_tests.each do |target|
              target_name = target['targetName']['_value']
              # if the test target failed to launch at all, get first failure message
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
                      failure = Helper::XcresultToJunitHelper.load_object(params, test['summaryRef']['id']['_value'])['failureSummaries']['_values'][0]
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
            ## READ XCRESULT END

            ## OUTPUT JUNIT START
            junit_folder = "#{params[:output_path]}/ios-#{device_udid}.junit"
            FileUtils.rm_rf junit_folder
            FileUtils.mkdir junit_folder
            File.open("#{junit_folder}/device.json", 'w') do |f|
              f << device_details
            end
            
            old_stdout = $stdout
            File.open("#{junit_folder}/results.xml", 'w') do |fo|
              $stdout = fo
              puts '<?xml version="1.0" encoding="UTF-8"?>'
              puts '<testsuites>'
              test_suites.each do |suite|
                if suite[:error]
                  puts "<testsuite name=#{suite[:name].encode xml: :attr} errors='1'>"
                  puts "<error>#{suite[:error].encode xml: :text}</error>"
                else
                  puts "<testsuite name=#{suite[:name].encode xml: :attr} tests='#{suite[:count]}' failures='#{suite[:failures]}' errors='#{suite[:errors]}'>"
                  suite[:cases].each do |testcase|
                    print "<testcase classname=#{suite[:name].encode xml: :attr} name=#{testcase[:name].encode xml: :attr} time='#{testcase[:time]}'"
                    if testcase[:failure]
                      puts '>'
                      puts "<failure message=#{testcase[:failure].encode xml: :attr}>#{testcase[:failure_location].encode xml: :text}</failure>"
                      puts '</testcase>'
                    elsif testcase[:error]
                      puts '>'
                      puts "<error>#{testcase[:error].encode xml: :text}</error>"
                      puts '</testcase>'
                    else
                      puts '/>'
                    end
                  end
                end
                puts '</testsuite>'
              end
              puts '</testsuites>'
            end
            $stdout = old_stdout
          end
        end
        ## OUTPUT JUNIT END
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
    