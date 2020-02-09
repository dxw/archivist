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
  let(:active_conversations_history_responses) {
    [
      Slack::Messages::Message.new(
        messages: [
          Slack::Messages::Message.new(
            subtype: "channel_join"
          ),
          Slack::Messages::Message.new(
            subtype: "channel_leave"
          ),
          Slack::Messages::Message.new,
          Slack::Messages::Message.new,
          Slack::Messages::Message.new(
            subtype: "bot_message"
          ),
          Slack::Messages::Message.new,
          Slack::Messages::Message.new(
            hidden: true
          ),
        ]
      ),
      Slack::Messages::Message.new(
        messages: [
          Slack::Messages::Message.new(
            subtype: "bot_message"
          ),
        ]
      ),
    ]
  }
  let(:stale_conversations_history_responses) {
    [
      Slack::Messages::Message.new(
        messages: [
          Slack::Messages::Message.new(
            subtype: "channel_join"
          ),
          Slack::Messages::Message.new(
            subtype: "channel_leave"
          ),
          Slack::Messages::Message.new(
            subtype: "bot_message"
          ),
          Slack::Messages::Message.new(
            hidden: true
          ),
        ]
      ),
      Slack::Messages::Message.new(
        messages: [
          Slack::Messages::Message.new(
            subtype: "bot_message"
          ),
          Slack::Messages::Message.new(
            subtype: "bot_message"
          ),
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
    allow(slack_client).to receive(:conversations_join)
    allow(slack_client).to receive(:conversations_history) do |params, &block|
      case params.fetch(:channel)
      when active_channel.id
        active_conversations_history_responses.each(&block)
      when stale_channel.id
        stale_conversations_history_responses.each(&block)
      else
        active_conversations_history_responses.each(&block)
      end
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

    it "archives stale channels" do
      # TODO: Replace this with a check of the Slack client method instead.
      expect(subject)
        .to receive(:archive_channel)
        .with(stale_channel)

      subject.run
    end

    it "doesn't archive active channels" do
      # TODO: Replace this with a check of the Slack client method instead.
      expect(subject)
        .not_to receive(:archive_channel)
        .with(active_channel)

      subject.run
    end

    it "doesn't archive the general channel" do
      # TODO: Replace this with a check of the Slack client method instead.
      expect(subject)
        .not_to receive(:archive_channel)
        .with(general_channel)

      subject.run
    end

    it "doesn't archive shared or pending shared channels" do
      # TODO: Replace these with checks of the Slack client method instead.
      expect(subject)
        .not_to receive(:archive_channel)
        .with(shared_channel)
      expect(subject)
        .not_to receive(:archive_channel)
        .with(pending_shared_channel)

      subject.run
    end
  end
end
