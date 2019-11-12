describe Fastlane::Actions::XcresultToJunitAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The xcresult_to_junit plugin is working!")

      Fastlane::Actions::XcresultToJunitAction.run(nil)
    end
  end
end
