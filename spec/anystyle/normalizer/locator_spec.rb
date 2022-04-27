module AnyStyle
  describe "Locator Normalizer" do
    let(:n) { Normalizer::Locator.new }

    it "extracts valid DOIs" do
      ({
        'doi:10/aabbe' => { doi: ['10/aabbe'] },
        'doi:10/gckfx5' => { doi: ['10/gckfx5'] },
        'doi:10/abc' => { doi: ['10/abc'] },
        'doi:10.1002/mpr.33.' => { doi: ['10.1002/mpr.33.'] },
        'https://doi.org/10.1000/182' => { doi: ['10.1000/182'] }
      }).each do |(a, b)|
        expect(n.normalize({ doi: [a] })).to include(b)
      end
    end

    it "extracts valid DOIs in URLs" do
      ({
        'https://doi.org/10/aabbe' => { doi: ['10/aabbe'] },
        'https://doi.org/10.1000/182' => { doi: ['10.1000/182'] }
      }).each do |(a, b)|
        expect(n.normalize({ url: [a] })).to include(b)
      end
    end

    it "extracts valid URLs" do
      ({
        'https://www.example.com/a1' => { url: ['https://www.example.com/a1'] },
        'www.example.com/a1' => { url: ['www.example.com/a1'] },
        'Foo bar http://example.org baz.' => { url: ['http://example.org'] },
        'Foo bar http://example.org baz. https://example.com/x' => { url: ['http://example.org', 'https://example.com/x'] }
      }).each do |(a, b)|
        expect(n.normalize({ url: [a] })).to include(b)
      end
    end
  end
end
