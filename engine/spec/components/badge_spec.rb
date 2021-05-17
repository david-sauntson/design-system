# frozen_string_literal: true

RSpec.describe CitizensAdviceComponents::Badge, type: :component do
  subject(:component) do
    render_inline(described_class.new(type: type.presence))
  end

  subject(:badge) { component.at(".cads-badge--#{type}") }

  let(:type) { :adviser }

  context "when missing type" do
    let(:type) { nil }

    context "non-production rails env" do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it "raises an error with available options" do
        expect do
          described_class.new(type: type)
        end.to raise_error(CitizensAdviceComponents::FetchOrFallbackHelper::InvalidValueError)
      end
    end

    context "production rails env" do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it "does not render" do
        expect(component.at(".cads-badge")).to be_nil
      end
    end
  end

  context "when type is example" do
    let(:type) { :example }

    it "has the correct label" do
      expect(badge.text).to eq "Example"
    end

    context "when welsh language" do
      before { I18n.locale = :cy }
      it "has translated label" do
        expect(badge.text).to eq "Enghraifft"
      end
    end
  end

  context "when type is important" do
    let(:type) { :important }

    it "has the correct label" do
      expect(badge.text).to eq "Important"
    end

    context "when welsh language" do
      before { I18n.locale = :cy }
      it "has translated label" do
        expect(badge.text).to eq "Pwysig"
      end
    end
  end

  context "when type is adviser" do
    let(:type) { :adviser }

    it "has the correct label" do
      expect(badge.text).to eq "Adviser"
    end

    context "when welsh language" do
      before { I18n.locale = :cy }
      it "has translated label" do
        expect(badge.text).to eq "Cynghorydd"
      end
    end
  end
end
