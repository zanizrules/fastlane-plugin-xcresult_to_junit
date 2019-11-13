describe Fastlane::Actions::XcresultToJunitAction do
  describe '#run' do
    it 'prints all messages' do
      expect(Fastlane::UI).to receive(:message).with("The xcresult_to_junit plugin has started!")
      expect(Fastlane::UI).to receive(:message).with("The xcresult_to_junit plugin has finished!")

      Fastlane::Actions::XcresultToJunitAction.run(xcresult_path: './fastlane/sample.xcresult', output_path: './fastlane/test_output/')
    end
  end
end
