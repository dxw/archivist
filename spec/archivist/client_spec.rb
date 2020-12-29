describe Archivist::Client do
  subject { Archivist::Client }

  let(:channel) {
    Slack::Messages::Message.new(
      id: "test-id",
      name: "test"
    )
  }

  let(:blocks) {
    [
      {
        type: "section",
        text: {
          type: "plain_text",
          text: "Some words"
        }
      }
    ]
  }

  describe ".configure" do
    it "creates a Slack client instance" do
      subject.configure

      expect(subject.slack_client).to be_instance_of(Slack::Web::Client)
    end
  end

  describe ".list_public_channels" do
    it "calls conversations_list on the Slack client" do
      expect(subject.slack_client)
        .to receive(:conversations_list)
        .with(
          exclude_archived: true,
          types: "public_channel",
          sleep_interval: 2
        )

      subject.list_public_channels
    end
  end

  describe ".join" do
    it "calls conversations_join on the Slack client" do
      expect(subject.slack_client)
        .to receive(:conversations_join)
        .with(channel: channel.id)

      subject.join(channel)
    end
  end

  describe ".leave" do
    it "calls conversations_leave on the Slack client" do
      expect(subject.slack_client)
        .to receive(:conversations_leave)
        .with(channel: channel.id)

      subject.leave(channel)
    end
  end

  describe ".archive" do
    it "calls conversations_archive on the Slack client" do
      expect(subject.slack_client)
        .to receive(:conversations_archive)
        .with(channel: channel.id)

      subject.archive(channel)
    end
  end

  describe ".post_to" do
    it "calls chat_postMessage on the Slack client" do
      expect(subject.slack_client)
        .to receive(:chat_postMessage)
        .with(channel: channel.id, blocks: blocks)

      subject.post_to(channel, blocks: blocks)
    end
  end

  describe ".post_to_id" do
    it "calls chat_postMessage on the Slack client" do
      expect(subject.slack_client)
        .to receive(:chat_postMessage)
        .with(channel: channel.id, blocks: blocks)

      subject.post_to_id(channel.id, blocks: blocks)
    end
  end

  describe ".last_messages_in" do
    it "calls conversations_history on the Slack client" do
      expect(subject.slack_client)
        .to receive(:conversations_history)
        .with(
          channel: channel.id,
          limit: 123,
          latest: Date.today - 12,
          oldest: Date.today - 23,
          sleep_interval: 1
        )

      subject.last_messages_in(
        channel,
        limit: 123,
        min_days_ago: 12,
        max_days_ago: 23
      )
    end
  end
end
