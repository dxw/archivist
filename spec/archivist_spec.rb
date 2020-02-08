describe Archivist do
  subject { Archivist }

  describe ".configure" do
    it "runs the configuration" do
      expect(Archivist::Config).to receive(:configure)

      subject.configure(slack_token: "testtoken")
    end
  end
end
