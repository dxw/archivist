describe Archivist do
  subject { Archivist }

  describe ".configure" do
    it "runs the configuration" do
      expect(Archivist::Config).to receive(:configure)

      subject.configure
    end
  end
end
