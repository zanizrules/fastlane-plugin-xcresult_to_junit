require 'fastlane_core/ui/ui'
require 'json'
require 'fileutils'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class XcresultToJunitHelper
      def self.load_object(xcresult_path, id)
        JSON.load FastlaneCore::CommandExecutor.execute(command: "xcrun xcresulttool get --format json --path #{xcresult_path} --id #{id}")
      end

      def self.load_results(xcresult_path)
        JSON.load FastlaneCore::CommandExecutor.execute(command: "xcrun xcresulttool get --format json --path #{xcresult_path}")
      end

      def self.fetch_screenshot(xcresult_path, output_path, file_name, id)
        if !File.directory?(output_path)
          FileUtils.mkdir output_path
        end
        JSON.load FastlaneCore::CommandExecutor.execute(command: "xcrun xcresulttool export --path #{xcresult_path} --output-path \"#{output_path}/#{file_name}\" --id #{id} --type file")
      end

      def self.save_screenshot_mapping(map_hash, output_path)
        File.open("#{output_path}/map.json", 'w') do |f|
          f << map_hash.to_json
        end
      end

      def self.save_device_details_to_file(output_path, device_destination)
        device_udid = device_destination['targetDeviceRecord']['identifier']['_value']
        device_details = {
          'udid' => device_udid,
          'name' => device_destination['targetDeviceRecord']['modelName']['_value'],
          'os' => device_destination['targetDeviceRecord']['operatingSystemVersion']['_value']
        }.to_json

        junit_folder = "#{output_path}/ios-#{device_udid}.junit"
        FileUtils.rm_rf junit_folder
        FileUtils.mkdir junit_folder
        FileUtils.mkdir "#{junit_folder}/attachments"
        File.open("#{junit_folder}/device.json", 'w') do |f|
          f << device_details
        end
        return junit_folder
      end

      def self.junit_file_start
        puts '<?xml version="1.0" encoding="UTF-8"?>'
        puts '<testsuites>'
      end

      def self.junit_file_end
        puts '</testsuites>'
      end

      def self.junit_suite_error(suite)
        puts "<testsuite name=#{suite[:name].encode xml: :attr} errors='1'>"
        puts "<error>#{suite[:error].encode xml: :text}</error>"
      end

      def self.junit_suite_start(suite)
        puts "<testsuite name=#{suite[:name].encode xml: :attr} tests='#{suite[:count]}' failures='#{suite[:failures]}' errors='#{suite[:errors]}'>"
      end

      def self.junit_suite_end
        puts '</testsuite>'
      end

      def self.junit_testcase_start(suite, testcase)
        print "<testcase name=#{testcase[:name].encode xml: :attr} classname=#{suite[:name].encode xml: :attr} time='#{testcase[:time]}'>"
      end

      def self.junit_testcase_end
        puts '</testcase>'
      end

      def self.junit_testcase_failure(testcase)
        puts "<failure message=#{testcase[:failure].encode xml: :attr}>#{testcase[:failure_location].encode xml: :text}</failure>"
      end

      def self.junit_testcase_error(testcase)
        puts "<error>#{testcase[:error].encode xml: :text}</error>"
      end

      def self.junit_testcase_performance(testcase)
        puts "<system-out>#{testcase[:performance]}</system-out>"
      end

      def self.generate_junit(junit_folder, test_suites)
        File.open("#{junit_folder}/results.xml", 'w') do |fo|
          old_stdout = $stdout
          $stdout = fo
          Helper::XcresultToJunitHelper.junit_file_start()
          test_suites.each do |suite|
            if suite[:error]
              Helper::XcresultToJunitHelper.junit_suite_error(suite)
            else
              Helper::XcresultToJunitHelper.junit_suite_start(suite)
              suite[:cases].each do |testcase|
                Helper::XcresultToJunitHelper.junit_testcase_start(suite, testcase)
                if testcase[:failure]
                  Helper::XcresultToJunitHelper.junit_testcase_failure(testcase)
                elsif testcase[:error]
                  Helper::XcresultToJunitHelper.junit_testcase_error(testcase)
                end
                if testcase[:performance]
                  Helper::XcresultToJunitHelper.junit_testcase_performance(testcase)
                end
                Helper::XcresultToJunitHelper.junit_testcase_end
              end
            end
            Helper::XcresultToJunitHelper.junit_suite_end()
          end
          Helper::XcresultToJunitHelper.junit_file_end()
          $stdout = old_stdout
        end
      end
    end
  end
end
