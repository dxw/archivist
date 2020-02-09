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
  end
end
