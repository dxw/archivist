describe Archivist::Channel do
  let(:no_archive_label) { "%noarchive" }
  let(:use_default_rules) { true }

  let(:active_channel) {
    Archivist::Channel.new(
      Slack::Messages::Message.new(
        id: "active-test-id",
        name: "active-test",
        is_member: true,
      )
    )
  }
  let(:included_active_channel) {
    Archivist::Channel.new(
      Slack::Messages::Message.new(
        id: "included-active-test-id",
        name: "included-active-test",
      )
    )
  }
  let(:stale_channel) {
    Archivist::Channel.new(
      Slack::Messages::Message.new(
        id: "stale-test-id",
        name: "stale-test",
      )
    )
  }
  let(:warned_active_channel) {
    Archivist::Channel.new(
      Slack::Messages::Message.new(
        id: "warned-active-test-id",
        name: "warned-active-test",
      )
    )
  }
  let(:warned_stale_channel) {
    Archivist::Channel.new(
      Slack::Messages::Message.new(
        id: "warned-stale-test-id",
        name: "warned-stale-test",
      )
    )
  }
  let(:general_channel) {
    Archivist::Channel.new(
      Slack::Messages::Message.new(
        id: "general-test-id",
        name: "general-test",
        is_general: true,
      )
    )
  }
  let(:shared_channel) {
    Archivist::Channel.new(
      Slack::Messages::Message.new(
        id: "shared-test-id",
        name: "shared-test",
        is_shared: true,
      )
    )
  }
  let(:pending_shared_channel) {
    Archivist::Channel.new(
      Slack::Messages::Message.new(
        id: "pending-shared-test-id",
        name: "pending-shared-test",
        pending_shared: ["other-team"]
      )
    )
  }
  let(:no_archive_description_channel) {
    Archivist::Channel.new(
      Slack::Messages::Message.new(
        id: "no-archive-description-test-id",
        name: "no-archive-description-test",
        purpose: Slack::Messages::Message.new(
          value: "A #{no_archive_label} description!"
        )
      )
    )
  }
  let(:no_archive_topic_channel) {
    Archivist::Channel.new(
      Slack::Messages::Message.new(
        id: "no-archive-topic-test-id",
        name: "no-archive-topic-test",
        topic: Slack::Messages::Message.new(
          value: "A #{no_archive_label} topic!"
        )
      )
    )
  }
  let(:skip_channel) {
    Archivist::Channel.new(
      Slack::Messages::Message.new(
        id: "skip-test-id",
        name: "skip-test",
      )
    )
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

  before do
    Archivist::Config.configure

    allow(Archivist::Config).to receive(:slack_api_token) { "test-api-token" }
    allow(Archivist::Config).to receive(:no_archive_label) { no_archive_label }
    allow(Archivist::Config).to receive(:use_default_rules) {
      use_default_rules
    }
    allow(Archivist::Config).to receive(:rules) {
      [
        Archivist::Rule.new("included-", days: 123),
        Archivist::Rule.new("stale-", days: 123),
        Archivist::Rule.new("warned-", days: 123),
        Archivist::Rule.new("skip-", skip: true),
      ]
    }

    Archivist::Client.configure

    allow(Archivist::Client)
      .to receive(:last_messages_in) { |channel, params, &block|
        case channel.id
        when stale_channel.id
          next stale_conversations_history_responses.each(&block)
        when warned_active_channel.id
          next warned_active_conversations_history_responses.each(&block)
        when warned_stale_channel.id
          next warned_stale_conversations_history_responses.each(&block)
        else
          next active_conversations_history_responses.each(&block)
        end
      }

    allow(SecureRandom).to receive(:uuid) { "1234" }
  end

  describe "#id" do
    it "matches the wrapped channel's id" do
      expect(active_channel.id).to eq("active-test-id")
    end
  end

  describe "#name" do
    it "matches the wrapped channel's name" do
      expect(active_channel.name).to eq("active-test")
    end
  end

  describe "#member?" do
    it "matches the wrapped channel's member status" do
      expect(active_channel.member?).to eq(true)
      expect(stale_channel.member?).to eq(false)
    end
  end

  describe "#general?" do
    it "matches the wrapped channel's general status" do
      expect(active_channel.general?).to eq(false)
      expect(general_channel.general?).to eq(true)
    end
  end

  describe "#shared?" do
    it "matches the wrapped channel's shared status" do
      expect(active_channel.shared?).to eq(false)
      expect(shared_channel.shared?).to eq(true)
      expect(pending_shared_channel.shared?).to eq(true)
    end
  end

  describe "#monitored?" do
    context "with default rules" do
      let(:use_default_rules) { true }

      it "returns true for channels covered by the rules" do
        expect(active_channel.monitored?).to eq(true)
        expect(stale_channel.monitored?).to eq(true)
        expect(warned_active_channel.monitored?).to eq(true)
        expect(warned_stale_channel.monitored?).to eq(true)
      end

      it "returns false for channels not covered by the rules" do
        expect(general_channel.monitored?).to eq(false)
        expect(shared_channel.monitored?).to eq(false)
        expect(pending_shared_channel.monitored?).to eq(false)
        expect(no_archive_description_channel.monitored?).to eq(false)
        expect(no_archive_topic_channel.monitored?).to eq(false)
        expect(skip_channel.monitored?).to eq(false)
      end
    end

    context "without default rules" do
      let(:use_default_rules) { false }

      it "returns true for channels covered by the rules" do
        expect(stale_channel.monitored?).to eq(true)
        expect(warned_active_channel.monitored?).to eq(true)
        expect(warned_stale_channel.monitored?).to eq(true)
      end

      it "returns false for channels not covered by the rules" do
        expect(active_channel.monitored?).to eq(false)
        expect(general_channel.monitored?).to eq(false)
        expect(shared_channel.monitored?).to eq(false)
        expect(pending_shared_channel.monitored?).to eq(false)
        expect(no_archive_description_channel.monitored?).to eq(false)
        expect(no_archive_topic_channel.monitored?).to eq(false)
        expect(skip_channel.monitored?).to eq(false)
      end
    end
  end

  describe "#not_monitored?" do
    context "with default rules" do
      let(:use_default_rules) { true }

      it "returns false for channels covered by the rules" do
        expect(active_channel.not_monitored?).to eq(false)
        expect(stale_channel.not_monitored?).to eq(false)
        expect(warned_active_channel.not_monitored?).to eq(false)
        expect(warned_stale_channel.not_monitored?).to eq(false)
      end

      it "returns true for channels not covered by the rules" do
        expect(general_channel.not_monitored?).to eq(true)
        expect(shared_channel.not_monitored?).to eq(true)
        expect(pending_shared_channel.not_monitored?).to eq(true)
        expect(no_archive_description_channel.not_monitored?).to eq(true)
        expect(no_archive_topic_channel.not_monitored?).to eq(true)
        expect(skip_channel.not_monitored?).to eq(true)
      end
    end

    context "without default rules" do
      let(:use_default_rules) { false }

      it "returns false for channels covered by the rules" do
        expect(stale_channel.not_monitored?).to eq(false)
        expect(warned_active_channel.not_monitored?).to eq(false)
        expect(warned_stale_channel.not_monitored?).to eq(false)
      end

      it "returns true for channels not covered by the rules" do
        expect(active_channel.not_monitored?).to eq(true)
        expect(general_channel.not_monitored?).to eq(true)
        expect(shared_channel.not_monitored?).to eq(true)
        expect(pending_shared_channel.not_monitored?).to eq(true)
        expect(no_archive_description_channel.not_monitored?).to eq(true)
        expect(no_archive_topic_channel.not_monitored?).to eq(true)
        expect(skip_channel.not_monitored?).to eq(true)
      end
    end
  end

  describe "#warnable?" do
    context "with default rules" do
      let(:use_default_rules) { true }

      it "returns true for stale monitored channels" do
        expect(stale_channel.warnable?).to eq(true)
      end

      it "returns false for active monitored channels" do
        expect(active_channel.warnable?).to eq(false)
      end

      it "returns false for recently warned stale monitored channels" do
        expect(warned_stale_channel.warnable?).to eq(false)
      end

      it "returns false for recently warned active monitored channels" do
        expect(warned_active_channel.warnable?).to eq(false)
      end

      it "returns false for unmonitored channels" do
        expect(general_channel.warnable?).to eq(false)
        expect(shared_channel.warnable?).to eq(false)
        expect(pending_shared_channel.warnable?).to eq(false)
        expect(no_archive_description_channel.warnable?).to eq(false)
        expect(no_archive_topic_channel.warnable?).to eq(false)
        expect(skip_channel.warnable?).to eq(false)
      end
    end

    context "without default rules" do
      let(:use_default_rules) { false }

      it "returns true for stale monitored channels" do
        expect(stale_channel.warnable?).to eq(true)
      end

      it "returns false for active monitored channels" do
        expect(active_channel.warnable?).to eq(false)
      end

      it "returns false for recently warned stale monitored channels" do
        expect(warned_stale_channel.warnable?).to eq(false)
      end

      it "returns false for recently warned active monitored channels" do
        expect(warned_active_channel.warnable?).to eq(false)
      end

      it "returns false for unmonitored channels" do
        expect(active_channel.warnable?).to eq(false)
        expect(general_channel.warnable?).to eq(false)
        expect(shared_channel.warnable?).to eq(false)
        expect(pending_shared_channel.warnable?).to eq(false)
        expect(no_archive_description_channel.warnable?).to eq(false)
        expect(no_archive_topic_channel.warnable?).to eq(false)
        expect(skip_channel.warnable?).to eq(false)
      end
    end
  end

  describe "#archivable?" do
    context "with default rules" do
      let(:use_default_rules) { true }

      it "returns false for stale monitored channels" do
        expect(stale_channel.archivable?).to eq(false)
      end

      it "returns false for active monitored channels" do
        expect(active_channel.archivable?).to eq(false)
      end

      it "returns true for recently warned stale monitored channels" do
        expect(warned_stale_channel.archivable?).to eq(true)
      end

      it "returns false for recently warned active monitored channels" do
        expect(warned_active_channel.archivable?).to eq(false)
      end

      it "returns false for unmonitored channels" do
        expect(general_channel.archivable?).to eq(false)
        expect(shared_channel.archivable?).to eq(false)
        expect(pending_shared_channel.archivable?).to eq(false)
        expect(no_archive_description_channel.archivable?).to eq(false)
        expect(no_archive_topic_channel.archivable?).to eq(false)
        expect(skip_channel.archivable?).to eq(false)
      end
    end

    context "without default rules" do
      let(:use_default_rules) { false }

      it "returns false for stale monitored channels" do
        expect(stale_channel.archivable?).to eq(false)
      end

      it "returns false for active monitored channels" do
        expect(active_channel.archivable?).to eq(false)
      end

      it "returns true for recently warned stale monitored channels" do
        expect(warned_stale_channel.archivable?).to eq(true)
      end

      it "returns false for recently warned active monitored channels" do
        expect(warned_active_channel.archivable?).to eq(false)
      end

      it "returns false for unmonitored channels" do
        expect(active_channel.archivable?).to eq(false)
        expect(general_channel.archivable?).to eq(false)
        expect(shared_channel.archivable?).to eq(false)
        expect(pending_shared_channel.archivable?).to eq(false)
        expect(no_archive_description_channel.archivable?).to eq(false)
        expect(no_archive_topic_channel.archivable?).to eq(false)
        expect(skip_channel.archivable?).to eq(false)
      end
    end
  end
end
