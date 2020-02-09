describe Archivist::Config do
  subject { Archivist::Config }

  describe ".configure" do
    it "creates a Slack client instance" do
      subject.configure

      expect(subject.slack_client).to be_instance_of(Slack::Web::Client)
    end

    it "populates the no archive label from the environment if one is set" do
      old_label = ENV["ARCHIVIST_NO_ARCHIVE_LABEL"]
      ENV["ARCHIVIST_NO_ARCHIVE_LABEL"] = "%test"

      subject.configure

      ENV["ARCHIVIST_NO_ARCHIVE_LABEL"] = old_label

      expect(subject.no_archive_label).to eq("%test")
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
      ENV["ARCHIVIST_RULES"] = "prefix=chat- , days = 90;\n prefix=test-"

      subject.configure

      ENV["ARCHIVIST_RULES"] = old_rules

      expect(subject.rules.count).to eq(2)

      expect(subject.rules[0].prefix).to eq("chat-")
      expect(subject.rules[0].days).to eq(90)

      expect(subject.rules[1].prefix).to eq("test-")
      expect(subject.rules[1].days).to be_nil
    end

    it "raises an error if any rules overlap" do
      old_rules = ENV["ARCHIVIST_RULES"]
      ENV["ARCHIVIST_RULES"] = "prefix=chat-;prefix=cha;prefix=test-"

      expect { subject.configure }.to raise_error("The following rules overlap: chat-, cha")

      ENV["ARCHIVIST_RULES"] = old_rules
    end
  end
end
