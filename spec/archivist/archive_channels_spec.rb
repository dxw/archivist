describe Archivist::ArchiveChannels do
  let(:slack_client) { double(Slack::Web::Client) }
  let(:no_archive_label) { "%noarchive" }
  let(:use_default_rules) { true }
  let(:rules) {
    [
      Archivist::Rule.new("stale-", days: 123),
      Archivist::Rule.new("warned-", days: 123),
      Archivist::Rule.new("skip-", skip: true),
    ]
  }

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
  let(:warned_active_channel) {
    Slack::Messages::Message.new(
      id: "warned-active-test-id",
      name: "warned-active-test",
    )
  }
  let(:warned_stale_channel) {
    Slack::Messages::Message.new(
      id: "warned-stale-test-id",
      name: "warned-stale-test",
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
  let(:skip_channel) {
    Slack::Messages::Message.new(
      id: "skip-test-id",
      name: "skip-test",
    )
  }

  let(:conversations_list_responses) {
    [
      Slack::Messages::Message.new(
        channels: [
          active_channel,
          stale_channel,
          warned_active_channel,
          warned_stale_channel,
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
          skip_channel,
        ]
      ),
    ]
  }
  let(:active_conversations_history_responses) {
    [
      Slack::Messages::Message.new(
        messages: [
          Slack::Messages::Message.new(
            subtype: "channel_join",
            ts: Time.now.to_f.to_s
          ),
          Slack::Messages::Message.new(
            subtype: "channel_leave",
            ts: Time.now.to_f.to_s
          ),
          Slack::Messages::Message.new(
            ts: Time.now.to_f.to_s
          ),
          Slack::Messages::Message.new(
            ts: Time.now.to_f.to_s
          ),
          Slack::Messages::Message.new(
            subtype: "bot_message",
            ts: Time.now.to_f.to_s
          ),
          Slack::Messages::Message.new(
            ts: Time.now.to_f.to_s
          ),
          Slack::Messages::Message.new(
            hidden: true,
            ts: Time.now.to_f.to_s
          ),
        ]
      ),
      Slack::Messages::Message.new(
        messages: [
          Slack::Messages::Message.new(
            subtype: "bot_message",
            ts: Time.now.to_f.to_s
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
            subtype: "channel_join",
            ts: Time.now.to_f.to_s
          ),
          Slack::Messages::Message.new(
            subtype: "channel_leave",
            ts: Time.now.to_f.to_s
          ),
          Slack::Messages::Message.new(
            subtype: "bot_message",
            ts: Time.now.to_f.to_s
          ),
          Slack::Messages::Message.new(
            hidden: true,
            ts: Time.now.to_f.to_s
          ),
        ]
      ),
      Slack::Messages::Message.new(
        messages: [
          Slack::Messages::Message.new(
            subtype: "bot_message",
            ts: Time.now.to_f.to_s
          ),
          Slack::Messages::Message.new(
            bot_id: "testbotid",
            ts: Time.now.to_f.to_s
          ),
        ]
      ),
    ]
  }
  let(:warned_active_conversations_history_responses) {
    [
      Slack::Messages::Message.new(
        messages: [
          Slack::Messages::Message.new(
            ts: Time.now.to_f.to_s
          ),
          Slack::Messages::Message.new(
            blocks: [
              Slack::Messages::Message.new(block_id: "archivist-warn-1234"),
            ],
            bot_id: "testbotid",
            ts: Time.now.to_f.to_s
          ),
        ]
      ),
    ]
  }
  let(:warned_stale_conversations_history_responses) {
    [
      Slack::Messages::Message.new(
        messages: [
          Slack::Messages::Message.new(
            blocks: [
              Slack::Messages::Message.new(block_id: "archivist-warn-1234"),
            ],
            bot_id: "testbotid",
            ts: Time.now.to_f.to_s
          ),
        ]
      ),
    ]
  }

  let(:warning_message_blocks) {
    blocks = Archivist::ArchiveChannels::WARNING_MESSAGE_BLOCKS.dup
    blocks[0][:block_id] = "archivist-warn-#{SecureRandom.uuid}"
    blocks
  }

  before do
    Archivist::Config.configure

    allow(Archivist::Config).to receive(:slack_client) { slack_client }
    allow(Archivist::Config).to receive(:no_archive_label) { no_archive_label }
    allow(Archivist::Config).to receive(:use_default_rules) {
      use_default_rules
    }
    allow(Archivist::Config).to receive(:rules) { rules }

    allow(slack_client).to receive(:chat_postMessage)
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
      when warned_active_channel.id
        warned_active_conversations_history_responses.each(&block)
      when warned_stale_channel.id
        warned_stale_conversations_history_responses.each(&block)
      else
        active_conversations_history_responses.each(&block)
      end
    end

    allow(SecureRandom).to receive(:uuid) { "1234" }
  end

  describe "#run with default rules" do
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

    it "doesn't join channels marked as skip by a matching rule" do
      expect(slack_client)
        .not_to receive(:conversations_join)
        .with(channel: skip_channel.id)

      subject.run
    end

    it "uses activity no older than 30 days when deciding whether a channel is stale by default" do
      Timecop.freeze do
        expect(slack_client)
          .to receive(:conversations_history)
          .with(
            channel: active_channel.id,
            limit: nil,
            latest: Time.now,
            oldest: Date.today - 30
          )

        subject.run
      end
    end

    it "uses activity no older than specified by a matching rule when deciding whether a channel is stale" do
      Timecop.freeze do
        expect(slack_client)
          .to receive(:conversations_history)
          .with(
            channel: stale_channel.id,
            limit: nil,
            latest: Time.now,
            oldest: Date.today - rules[0].days
          )

        subject.run
      end
    end

    it "warns stale channels" do
      expect(slack_client)
        .to receive(:chat_postMessage)
        .with(channel: stale_channel.id, blocks: warning_message_blocks)

      subject.run
    end

    it "doesn't warn active channels" do
      expect(slack_client)
        .not_to receive(:chat_postMessage)
        .with(channel: active_channel.id, blocks: warning_message_blocks)
      expect(slack_client)
        .not_to receive(:chat_postMessage)
        .with(channel: warned_active_channel.id, blocks: warning_message_blocks)

      subject.run
    end

    it "doesn't warn warned channels" do
      expect(slack_client)
        .not_to receive(:chat_postMessage)
        .with(channel: warned_active_channel.id, blocks: warning_message_blocks)
      expect(slack_client)
        .not_to receive(:chat_postMessage)
        .with(channel: warned_stale_channel.id, blocks: warning_message_blocks)

      subject.run
    end

    it "archives warned stale channels" do
      # TODO: Replace this with a check of the Slack client method instead.
      expect(subject)
        .to receive(:archive_channel)
        .with(warned_stale_channel)

      subject.run
    end

    it "doesn't archive active channels" do
      # TODO: Replace this with a check of the Slack client method instead.
      expect(subject)
        .not_to receive(:archive_channel)
        .with(active_channel)

      subject.run
    end

    it "doesn't archive stale but unwarned channels" do
      # TODO: Replace this with a check of the Slack client method instead.
      expect(subject)
        .not_to receive(:archive_channel)
        .with(stale_channel)

      subject.run
    end

    it "doesn't archive warned active channels" do
      # TODO: Replace this with a check of the Slack client method instead.
      expect(subject)
        .not_to receive(:archive_channel)
        .with(warned_active_channel)

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

  describe "#run without default rules" do
    let(:use_default_rules) { false }

    it "joins channels covered by the rules" do
      expect(slack_client)
        .to receive(:conversations_join)
        .with(channel: stale_channel.id)

      subject.run
    end

    it "doesn't join channels not covered by the rules" do
      expect(slack_client)
        .not_to receive(:conversations_join)
        .with(channel: active_channel.id)

      subject.run
    end

    it "doesn't join channels marked as skip by a matching rule" do
      expect(slack_client)
        .not_to receive(:conversations_join)
        .with(channel: skip_channel.id)

      subject.run
    end

    it "warns stale channels" do
      expect(slack_client)
        .to receive(:chat_postMessage)
        .with(channel: stale_channel.id, blocks: warning_message_blocks)

      subject.run
    end

    it "doesn't warn active channels" do
      expect(slack_client)
        .not_to receive(:chat_postMessage)
        .with(channel: active_channel.id, blocks: warning_message_blocks)
      expect(slack_client)
        .not_to receive(:chat_postMessage)
        .with(channel: warned_active_channel.id, blocks: warning_message_blocks)

      subject.run
    end

    it "doesn't warn warned channels" do
      expect(slack_client)
        .not_to receive(:chat_postMessage)
        .with(channel: warned_active_channel.id, blocks: warning_message_blocks)
      expect(slack_client)
        .not_to receive(:chat_postMessage)
        .with(channel: warned_stale_channel.id, blocks: warning_message_blocks)

      subject.run
    end

    it "archives warned stale channels" do
      # TODO: Replace this with a check of the Slack client method instead.
      expect(subject)
        .to receive(:archive_channel)
        .with(warned_stale_channel)

      subject.run
    end

    it "archives warned stale channels covered by the rules" do
      # TODO: Replace this with a check of the Slack client method instead.
      expect(subject)
        .to receive(:archive_channel)
        .with(warned_stale_channel)

      subject.run
    end

    it "doesn't archive any channels not covered by the rules" do
      # TODO: Replace this with a check of the Slack client method instead.
      expect(subject)
        .not_to receive(:archive_channel)
        .with(active_channel)

      subject.run
    end

    it "doesn't archive stale but unwarned channels covered by the rules" do
      # TODO: Replace this with a check of the Slack client method instead.
      expect(subject)
        .not_to receive(:archive_channel)
        .with(stale_channel)

      subject.run
    end

    it "doesn't archive warned active channels covered by the rules" do
      # TODO: Replace this with a check of the Slack client method instead.
      expect(subject)
        .not_to receive(:archive_channel)
        .with(warned_active_channel)

      subject.run
    end

    it "leaves any channels not covered by the rules" do
      expect(slack_client)
        .to receive(:conversations_leave)
        .with(channel: member_channel.id)

      subject.run
    end
  end
end
