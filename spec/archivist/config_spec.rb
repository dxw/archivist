describe Archivist::Config do
  subject { Archivist::Config }

  describe ".configure" do
    it "creates a Slack client instance" do
      subject.configure(slack_token: "testtoken")

      expect(subject.slack_client).to be_instance_of(Slack::Web::Client)
    end
  end
end
