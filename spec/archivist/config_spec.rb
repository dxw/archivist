describe Archivist::Config do
  subject { Archivist::Config }

  describe ".configure" do
    it "populates the Slack API token from the environment" do
      old_token = ENV["ARCHIVIST_SLACK_API_TOKEN"]
      ENV["ARCHIVIST_SLACK_API_TOKEN"] = "test-api-token"

      subject.configure

      ENV["ARCHIVIST_SLACK_API_TOKEN"] = old_token

      expect(subject.slack_api_token).to eq("test-api-token")
    end

    it "sets whether to use the default rules based on the environment" do
      old_disable = ENV["ARCHIVIST_DISABLE_DEFAULTS"]
      ENV["ARCHIVIST_DISABLE_DEFAULTS"] = "anything"

      subject.configure

      ENV["ARCHIVIST_DISABLE_DEFAULTS"] = old_disable

      expect(subject.use_default_rules).to be(false)
    end

    it "parses additional rules from the environment" do
      old_rules = ENV["ARCHIVIST_RULES"]
      ENV["ARCHIVIST_RULES"] = "prefix=chat- , days = 90;\n prefix=test- , skip=true"

      subject.configure

      ENV["ARCHIVIST_RULES"] = old_rules

      expect(subject.rules.count).to eq(2)

      expect(subject.rules[0].prefix).to eq("chat-")
      expect(subject.rules[0].days).to eq(90)
      expect(subject.rules[0].skip).to eq(false)

      expect(subject.rules[1].prefix).to eq("test-")
      expect(subject.rules[1].days).to be_nil
      expect(subject.rules[1].skip).to eq(true)
    end

    it "raises an error if any rules overlap" do
      old_rules = ENV["ARCHIVIST_RULES"]
      ENV["ARCHIVIST_RULES"] = "prefix=chat-;prefix=cha;prefix=test-"

      expect { subject.configure }.to raise_error("The following rules overlap: chat-, cha")

      ENV["ARCHIVIST_RULES"] = old_rules
    end

    it "populates the report channel from the environment if one is set" do
      old_channel = ENV["ARCHIVIST_REPORT_CHANNEL_ID"]
      ENV["ARCHIVIST_REPORT_CHANNEL_ID"] = "C12345678"

      subject.configure

      ENV["ARCHIVIST_REPORT_CHANNEL_ID"] = old_channel

      expect(subject.report_channel_id).to eq("C12345678")
    end
  end
end
