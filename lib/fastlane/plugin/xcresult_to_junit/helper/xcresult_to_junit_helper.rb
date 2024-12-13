# frozen_string_literal: true

require 'fastlane_core/ui/ui'
require 'json'
require 'fileutils'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?('UI')

  module Helper
    class XcresultToJunitHelper
      def self.fetch_tests(xcresult_path)
        JSON.parse(FastlaneCore::CommandExecutor.execute(command: "xcrun xcresulttool get test-results tests --path #{xcresult_path}"))
      end

      def self.save_attachments(xcresult_path, output_path)
        FileUtils.mkdir(output_path) unless File.directory?(output_path)
        FastlaneCore::CommandExecutor.execute(command: "xcrun xcresulttool export attachments --path #{xcresult_path} --output-path #{output_path}")
      end

      def self.fetch_attachment_manifest(attachments_folder)
        JSON.parse(FastlaneCore::CommandExecutor.execute(command: "cat #{attachments_folder}/manifest.json"))
      end

      def self.save_screenshot_mapping(map_hash, output_path)
        File.open("#{output_path}/map.json", 'w') do |f|
          f << map_hash.to_json
        end
      end

      def self.save_device_details_to_file(output_path, devices)
        device = devices[0]
        device_details = {
          'architecture' => device['architecture'],
          'udid' => device['deviceId'],
          'name' => device['deviceName'],
          'model' => device['modelName'],
          'os' => device['osVersion'],
          'platform' => device['platform']
        }.to_json

        junit_folder = "#{output_path}/ios-#{device['deviceId']}.junit"
        FileUtils.rm_rf(junit_folder)
        FileUtils.mkdir_p("#{junit_folder}/attachments")
        File.open("#{junit_folder}/device.json", 'w') do |f|
          f << device_details
        end
        junit_folder
      end

      def self.junit_file_start
        puts('<?xml version="1.0" encoding="UTF-8"?>')
        puts('<testsuites>')
      end

      def self.junit_file_end
        puts('</testsuites>')
      end

      def self.junit_suite_error(suite)
        puts("<testsuite name=#{suite[:name].encode(xml: :attr)} errors='1'>")
        puts("<error>#{suite[:error].encode(xml: :text)}</error>")
      end

      def self.junit_suite_start(suite)
        puts("<testsuite name=#{suite[:name].encode(xml: :attr)} tests='#{suite[:count]}' failures='#{suite[:failures]}' errors='#{suite[:errors]}'>")
      end

      def self.junit_suite_end
        puts('</testsuite>')
      end

      def self.junit_testcase_start(suite, testcase)
        print("<testcase name=#{testcase[:name].encode(xml: :attr)} classname=#{suite[:name].encode(xml: :attr)} time='#{testcase[:time]}'>")
      end

      def self.junit_testcase_end
        puts('</testcase>')
      end

      def self.junit_testcase_failure(testcase)
        if testcase[:failure].length != testcase[:failure_location].length
          raise "Mismatch in lengths: testcase[:failure] and testcase[:failure_location] must have the same length."
        end
        for index in 0...testcase[:failure].length
          failure = testcase[:failure][index]
          failure_location = testcase[:failure_location][index]
          puts("<failure message=#{failure.encode(xml: :attr)}>#{failure_location.encode(xml: :text)}</failure>")
        end
      end

      def self.junit_testcase_error(testcase)
        puts("<error>#{testcase[:error].encode(xml: :text)}</error>")
      end

      def self.junit_testcase_performance(testcase)
        puts("<system-out>#{testcase[:performance]}</system-out>")
      end

      def self.generate_junit(junit_folder, test_suites)
        File.open("#{junit_folder}/results.xml", 'w') do |fo|
          old_stdout = $stdout
          $stdout = fo
          Helper::XcresultToJunitHelper.junit_file_start
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
                Helper::XcresultToJunitHelper.junit_testcase_performance(testcase) if testcase[:performance]
                Helper::XcresultToJunitHelper.junit_testcase_end
              end
            end
            Helper::XcresultToJunitHelper.junit_suite_end
          end
          Helper::XcresultToJunitHelper.junit_file_end
          $stdout = old_stdout
        end
      end
    end
  end
end
