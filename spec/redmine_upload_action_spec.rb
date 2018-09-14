describe Fastlane::Actions::RedmineUploadAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The redmine_upload plugin is working!")

      Fastlane::Actions::RedmineUploadAction.run(nil)
    end
  end
end
