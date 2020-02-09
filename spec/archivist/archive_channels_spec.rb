describe Archivist::ArchiveChannels do
  subject { Archivist::ArchiveChannels }

  let(:slack_client) { double(Slack::Web::Client) }

  let(:active_channel) {
    Slack::Messages::Message.new(
      id: "active-test-id",
      name: "active-test",
      pending_shared: []
    )
  }
  let(:stale_channel) {
    Slack::Messages::Message.new(
      id: "stale-test-id",
      name: "stale-test",
      pending_shared: []
    )
  }
  let(:member_channel) {
    Slack::Messages::Message.new(
      id: "member-test-id",
      name: "member-test",
      is_member: true,
      pending_shared: []
    )
  }
  let(:general_channel) {
    Slack::Messages::Message.new(
      id: "general-test-id",
      name: "general-test",
      is_general: true,
      pending_shared: []
    )
  }
  let(:shared_channel) {
    Slack::Messages::Message.new(
      id: "shared-test-id",
      name: "shared-test",
      is_shared: true,
      pending_shared: []
    )
  }
  let(:pending_shared_channel) {
    Slack::Messages::Message.new(
      id: "pending-shared-test-id",
      name: "pending-shared-test",
      pending_shared: ["other-team"]
    )
  }

  let(:conversations_list_responses) {
    [
      Slack::Messages::Message.new(
        channels: [
          active_channel,
          stale_channel,
          member_channel,
        ]
      ),
      Slack::Messages::Message.new(
        channels: [
          general_channel,
          shared_channel,
          pending_shared_channel,
        ]
      ),
    ]
  }

  before do
    Archivist::Config.configure(slack_token: "testtoken")

    allow(Archivist::Config).to receive(:slack_client) { slack_client }

    allow(slack_client).to receive(:conversations_list) do |&block|
      conversations_list_responses.each { |response| block.call(response) }
    end
  end

  describe ".run" do
    it "joins channels it's not already a member of" do
      expect(slack_client)
        .to receive(:conversations_join)
        .with(channel: active_channel.id)
      expect(slack_client)
        .to receive(:conversations_join)
        .with(channel: stale_channel.id)

      subject.run
    end

    it "doesn't join channels it's already a member of" do
      expect(slack_client)
        .not_to receive(:conversations_join)
        .with(channel: member_channel.id)

      subject.run
    end

    it "doesn't join the general channel" do
      expect(slack_client)
        .not_to receive(:conversations_join)
        .with(channel: general_channel.id)

      subject.run
    end

    it "doesn't join shared or pending shared channels" do
      expect(slack_client)
        .not_to receive(:conversations_join)
        .with(channel: shared_channel.id)
      expect(slack_client)
        .not_to receive(:conversations_join)
        .with(channel: pending_shared_channel.id)

      subject.run
    end
  end
end
