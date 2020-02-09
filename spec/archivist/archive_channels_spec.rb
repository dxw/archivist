describe Archivist::ArchiveChannels do
  subject { Archivist::ArchiveChannels }

  let(:slack_client) { double(Slack::Web::Client) }

  before do
    Archivist::Config.configure(slack_token: "testtoken")

    allow(Archivist::Config).to receive(:slack_client) { slack_client }
  end

  describe ".run" do
    before do
      conversation_list_response = Slack::Messages::Message.new(
        channels: [
          Slack::Messages::Message.new(
            id: "test-a-id",
            name: "test-a",
            pending_shared: []
          ),
          Slack::Messages::Message.new(
            id: "test-b-id",
            name: "test-b",
            pending_shared: []
          ),
          Slack::Messages::Message.new(
            id: "member-test-id",
            name: "member-test",
            is_member: true,
            pending_shared: []
          ),
          Slack::Messages::Message.new(
            id: "shared-test-id",
            name: "shared-test",
            is_shared: true,
            pending_shared: []
          ),
          Slack::Messages::Message.new(
            id: "pending-shared-test-id",
            name: "pending-shared-test",
            pending_shared: ["other-team"]
          ),
        ]
      )

      allow(slack_client)
        .to receive(:conversations_list)
        .and_return(conversation_list_response)
    end

    it "joins channels it's not already a member of" do
      expect(slack_client)
        .to receive(:conversations_join)
        .with(channel: "test-a-id")
      expect(slack_client)
        .to receive(:conversations_join)
        .with(channel: "test-b-id")

      subject.run
    end

    it "doesn't join channels it's already a member of" do
      expect(slack_client)
        .not_to receive(:conversations_join)
        .with(channel: "member-test-id")

      subject.run
    end

    it "doesn't join shared or pending shared channels" do
      expect(slack_client)
        .not_to receive(:conversations_join)
        .with(channel: "shared-test-id")
      expect(slack_client)
        .not_to receive(:conversations_join)
        .with(channel: "pending-shared-test-id")

      subject.run
    end
  end
end
