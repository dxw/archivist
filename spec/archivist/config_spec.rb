describe Archivist::Config do
  subject { Archivist::Config }

  describe ".configure" do
    it "creates a Slack client instance" do
      subject.configure(slack_token: "testtoken")

      expect(subject.slack_client).to be_instance_of(Slack::Web::Client)
    end
  end

  describe ".no_archive_label" do
    it "returns nil by default" do
      expect(subject.no_archive_label).to be_nil
    end

    it "returns the no archive label from the environment if one is set" do
      old_label = ENV["NO_ARCHIVE_LABEL"]
      ENV["NO_ARCHIVE_LABEL"] = "%test"

      expect(subject.no_archive_label).to eq("%test")

      ENV["NO_ARCHIVE_LABEL"] = old_label
    end
  end
end
