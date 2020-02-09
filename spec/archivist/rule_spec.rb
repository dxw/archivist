describe Archivist::Config do
  let(:prefix) { "prefix-" }
  let(:days) { 123 }

  subject { Archivist::Rule.new(prefix, days: days) }

  describe "#overlap?" do
    let(:underlapping_rule) { Archivist::Rule.new("pre") }
    let(:overlapping_rule) { Archivist::Rule.new("prefix-with-more-") }
    let(:safe_rule) { Archivist::Rule.new("another-prefix-") }

    it "returns true when this rule's prefix starts with the other rule's prefix" do
      expect(subject.overlap?(underlapping_rule)).to eq(true)
    end

    it "returns true when the other rule's prefix starts with this rule's prefix" do
      expect(subject.overlap?(overlapping_rule)).to eq(true)
    end

    it "returns true when this rule's prefix and other rule's prefix are the same" do
      expect(subject.overlap?(subject)).to eq(true)
    end

    it "returns false if neither rule's prefix starts with the other" do
      expect(subject.overlap?(safe_rule)).to eq(false)
    end
  end
end
