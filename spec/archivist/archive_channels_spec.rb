describe Archivist::ArchiveChannels do
  subject { Archivist::ArchiveChannels }

  let(:slack_client) { double(Slack::Web::Client) }
  let(:no_archive_label) { "%noarchive" }
  let(:use_default_rules) { true }

  let(:active_channel) {
    Slack::Messages::Message.new(
      id: "active-test-id",
      name: "active-test",
    )
  }
  let(:stale_channel) {
    Slack::Messages::Message.new(
      id: "stale-test-id",
      name: "stale-test",
    )
  }
  let(:member_channel) {
    Slack::Messages::Message.new(
      id: "member-test-id",
      name: "member-test",
      is_member: true,
    )
  }
  let(:general_channel) {
    Slack::Messages::Message.new(
      id: "general-test-id",
      name: "general-test",
      is_general: true,
    )
  }
  let(:shared_channel) {
    Slack::Messages::Message.new(
      id: "shared-test-id",
      name: "shared-test",
      is_shared: true,
    )
  }
  let(:pending_shared_channel) {
    Slack::Messages::Message.new(
      id: "pending-shared-test-id",
      name: "pending-shared-test",
      pending_shared: ["other-team"]
    )
  }
  let(:no_archive_description_channel) {
    Slack::Messages::Message.new(
      id: "no-archive-description-test-id",
      name: "no-archive-description-test",
      purpose: Slack::Messages::Message.new(
        value: "A #{no_archive_label} description!"
      )
    )
  }
  let(:no_archive_topic_channel) {
    Slack::Messages::Message.new(
      id: "no-archive-topic-test-id",
      name: "no-archive-topic-test",
      topic: Slack::Messages::Message.new(
        value: "A #{no_archive_label} topic!"
      )
    )
  }

  let(:conversations_list_responses) {
    [
      Slack::Messages::Message.new(
        channels: [
          active_channel,
          stale_channel,
          member_channel,
          general_channel,
        ]
      ),
      Slack::Messages::Message.new(
        channels: [
          shared_channel,
          pending_shared_channel,
          no_archive_description_channel,
          no_archive_topic_channel,
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
    Archivist::Config.configure

    allow(Archivist::Config).to receive(:slack_client) { slack_client }
    allow(Archivist::Config).to receive(:no_archive_label) { no_archive_label }
    allow(Archivist::Config).to receive(:use_default_rules) {
      use_default_rules
    }

    allow(slack_client).to receive(:conversations_list) do |&block|
      conversations_list_responses.each { |response| block.call(response) }
    end
    allow(slack_client).to receive(:conversations_leave)
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

  describe ".run with default rules" do
    let(:use_default_rules) { true }

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

    it "doesn't join channels with the no archive label in their description" do
      expect(slack_client)
        .not_to receive(:conversations_join)
        .with(channel: no_archive_description_channel.id)

      subject.run
    end

    it "doesn't join channels with the no archive label in their topic" do
      expect(slack_client)
        .not_to receive(:conversations_join)
        .with(channel: no_archive_topic_channel.id)

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

  describe ".run without default rules" do
    let(:use_default_rules) { false }

    it "doesn't join any channels" do
      expect(slack_client).not_to receive(:conversations_join)

      subject.run
    end

    it "doesn't archive any channels" do
      # TODO: Replace this with a check of the Slack client method instead.
      expect(subject).not_to receive(:archive_channel)

      subject.run
    end

    it "leaves any channels of which it's a member" do
      expect(slack_client)
        .to receive(:conversations_leave)
        .with(channel: member_channel.id)

      subject.run
    end
  end
end
