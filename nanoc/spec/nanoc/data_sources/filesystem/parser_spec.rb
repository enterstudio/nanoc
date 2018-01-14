# frozen_string_literal: true

describe Nanoc::DataSources::Filesystem::Parser do
  subject(:parser) { described_class.new(config: config) }

  let(:config) do
    Nanoc::Int::Configuration.new.with_defaults
  end

  describe '#call' do
    subject { parser.call(content_filename, meta_filename) }

    # common:
    #   utf-8 bom
    #   \r\n
    #   metadata is empty
    #   metadata is not hash

    let(:content_filename) { nil }
    let(:meta_filename) { nil }

    context 'only meta file' do
      let(:meta_filename) { Tempfile.open('test') { |fn| fn << 'asdf' }.path }

      before do
        File.write(meta_filename, meta)
      end

      context 'simple metadata' do
        let(:meta) { "foo: bar\n" }

        it 'reads attributes' do
          expect(subject.attributes).to eq('foo' => 'bar')
        end

        it 'has no content' do
          expect(subject.content).to eq('')
        end
      end

      context 'UTF-8 bom' do
        let(:meta) { [0xEF, 0xBB, 0xBF].map(&:chr).join + "foo: bar\r\n" }

        it 'strips UTF-8 BOM' do
          expect(subject.attributes).to eq('foo' => 'bar')
        end

        it 'has no content' do
          expect(subject.content).to eq('')
        end
      end

      context 'CRLF' do
        let(:meta) { "foo: bar\r\n" }

        it 'handles CR+LF line endings' do
          expect(subject.attributes).to eq('foo' => 'bar')
        end

        it 'has no content' do
          expect(subject.content).to eq('')
        end
      end

      context 'metadata is empty' do
        let(:meta) { "" }

        it 'has no attributes' do
          expect(subject.attributes).to eq({})
        end

        it 'has no content' do
          expect(subject.content).to eq('')
        end
      end

      context 'metadata is not hash' do
        let(:meta) { "- stuff\n" }

        it 'raises' do
          expect { subject }
            .to raise_error(Nanoc::DataSources::Filesystem::Errors::InvalidMetadata, /has invalid metadata \(expected key-value pairs, found Array instead\)/)
        end
      end
    end

    context 'only content file' do
      # TODO
    end

    context 'meta and content file' do
      # TODO

      # content also includes metadata
      # separator = ---
      # separator = ----
      # separator = -----
      # another separator in body
      # leading newline is removed
    end
  end

  # test_parse_embedded_diff
  # test_parse_embedded_empty_meta
  # test_parse_embedded_full_meta
  # test_parse_embedded_invalid_2
  # test_parse_embedded_meta_only_1
  # test_parse_embedded_meta_only_2
  # test_parse_embedded_meta_only_3
  # test_parse_embedded_no_meta
  # test_parse_embedded_separators_but_not_metadata
  # test_parse_embedded_with_extra_spaces
  # test_parse_external
  # test_parse_external_bad_metadata
  # test_parse_internal_bad_metadata
  # test_parse_internal_four_dashes
  # test_parse_utf8_bom
  # test_parse_with_one_blank_line_after_metadata
  # test_parse_with_two_blank_lines_after_metadata
end
