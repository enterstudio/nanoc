# frozen_string_literal: true

describe Nanoc::DataSources::Filesystem do
  let(:data_source) { Nanoc::DataSources::Filesystem.new(site.config, nil, nil, params) }
  let(:params) { {} }
  let(:site) { Nanoc::Int::SiteLoader.new.new_empty }

  before { Timecop.freeze(now) }
  after { Timecop.return }

  let(:now) { Time.local(2008, 1, 2, 14, 5, 0) }

  describe '#load_objects' do
    subject { data_source.send(:load_objects, 'foo', klass) }

    let(:klass) { raise 'override me' }

    context 'items' do
      let(:klass) { Nanoc::Int::Item }

      context 'no files' do
        it 'loads nothing' do
          expect(subject).to be_empty
        end
      end

      context 'one regular file' do
        before do
          FileUtils.mkdir_p('foo')
          File.write('foo/bar.html', "---\nnum: 1\n---\ntest 1")
          FileUtils.touch('foo/bar.html', mtime: now)
        end

        let(:expected_attributes) do
          {
            content_filename: 'foo/bar.html',
            extension: 'html',
            filename: 'foo/bar.html',
            meta_filename: nil,
            mtime: now,
            num: 1,
          }
        end

        it 'loads that file' do
          expect(subject.size).to eq(1)

          expect(subject[0].content.string).to eq('test 1')
          expect(subject[0].attributes).to eq(expected_attributes)
          expect(subject[0].identifier).to eq(Nanoc::Identifier.new('/bar/', type: :legacy))
          expect(subject[0].checksum_data).to be_nil
          expect(subject[0].attributes_checksum_data).to be_a(String)
          expect(subject[0].attributes_checksum_data.size).to eq(20)
          expect(subject[0].content_checksum_data).to be_a(String)
          expect(subject[0].content_checksum_data.size).to eq(20)
        end

        context 'split files' do
          let(:block) do
            lambda do
              FileUtils.mkdir_p('foo')

              File.write('foo/bar.html', 'test 1')
              FileUtils.touch('foo/bar.html', mtime: now)

              File.write('foo/bar.yaml', "---\nnum: 1\n")
              FileUtils.touch('foo/bar.yaml', mtime: now)
            end
          end

          it 'has a different attributes checksum' do
            expect(block).to change { data_source.send(:load_objects, 'foo', klass)[0].attributes_checksum_data }
          end

          it 'has the same content checksum' do
            expect(block).not_to change { data_source.send(:load_objects, 'foo', klass)[0].content_checksum_data }
          end
        end
      end
    end
  end

  describe '#item_changes' do
    subject { data_source.item_changes }

    it 'returns a stream' do
      expect(subject).to be_a(Nanoc::ChangesStream)
    end

    it 'contains one element after changing' do
      FileUtils.mkdir_p('content')

      enum = SlowEnumeratorTools.buffer(subject.to_enum, 1)
      q = SizedQueue.new(1)
      Thread.new { q << enum.take(1).first }

      # FIXME: sleep is ugly
      sleep 0.3
      File.write('content/wat.md', 'stuff')

      expect(q.pop).to eq(:unknown)
      subject.stop
    end
  end

  describe '#layout_changes' do
    subject { data_source.layout_changes }

    it 'returns a stream' do
      expect(subject).to be_a(Nanoc::ChangesStream)
    end

    it 'contains one element after changing' do
      FileUtils.mkdir_p('layouts')

      enum = SlowEnumeratorTools.buffer(subject.to_enum, 1)
      q = SizedQueue.new(1)
      Thread.new { q << enum.take(1).first }

      # FIXME: sleep is ugly
      sleep 0.3
      File.write('layouts/wat.md', 'stuff')

      expect(q.pop).to eq(:unknown)
      subject.stop
    end
  end

  # def test_parse_embedded_meta_only_1
  #   # Create a file
  #   File.open('test.html', 'w') do |io|
  #     io.write "-----\r\n"
  #     io.write "foo: bar\n"
  #     io.write "-----\n"
  #   end

  #   # Create data source
  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   # Parse it
  #   result = data_source.instance_eval { parse('test.html', nil) }
  #   assert_equal({ 'foo' => 'bar' }, result.attributes)
  #   assert_equal('', result.content)
  # end

  # def test_parse_embedded_meta_only_2
  #   # Create a file
  #   File.open('test.html', 'w') do |io|
  #     io.write "-----\n"
  #     io.write "foo: bar\r\n"
  #     io.write "-----\r"
  #   end

  #   # Create data source
  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   # Parse it
  #   result = data_source.instance_eval { parse('test.html', nil) }
  #   assert_equal({ 'foo' => 'bar' }, result.attributes)
  #   assert_equal('', result.content)
  # end

  # def test_parse_embedded_meta_only_3
  #   # Create a file
  #   File.open('test.html', 'w') do |io|
  #     io.write "-----\r\n"
  #     io.write "foo: bar\n"
  #     io.write '-----'
  #   end

  #   # Create data source
  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   # Parse it
  #   result = data_source.instance_eval { parse('test.html', nil) }
  #   assert_equal({ 'foo' => 'bar' }, result.attributes)
  #   assert_equal('', result.content)
  # end

  # def test_parse_embedded_invalid_2
  #   # Create a file
  #   File.open('test.html', 'w') do |io|
  #     io.write "-----\n"
  #     io.write "blah blah\n"
  #   end

  #   # Create data source
  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   # Parse it
  #   assert_raises(Nanoc::DataSources::Filesystem::Errors::InvalidFormat) do
  #     data_source.instance_eval { parse('test.html', nil) }
  #   end
  # end

  # def test_parse_embedded_separators_but_not_metadata
  #   # Create a file
  #   File.open('test.html', 'w') do |io|
  #     io.write "blah blah\n"
  #     io.write "-----\n"
  #     io.write "blah blah\n"
  #   end

  #   # Create data source
  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   # Parse it
  #   result = data_source.instance_eval { parse('test.html', nil) }
  #   assert_equal(File.read('test.html'), result.content)
  #   assert_equal({},                     result.attributes)
  # end

  # def test_parse_embedded_full_meta
  #   # Create a file
  #   File.open('test.html', 'w') do |io|
  #     io.write "-----\r\n"
  #     io.write "foo: bar\n"
  #     io.write "-----\n"
  #     io.write "  \t\n  blah blah\n"
  #   end

  #   # Create data source
  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   # Parse it
  #   result = data_source.instance_eval { parse('test.html', nil) }
  #   assert_equal({ 'foo' => 'bar' }, result.attributes)
  #   assert_equal("  \t\n  blah blah\n", result.content)
  # end

  # def test_parse_embedded_with_extra_spaces
  #   # Create a file
  #   File.open('test.html', 'w') do |io|
  #     io.write "-----             \n"
  #     io.write "foo: bar\n"
  #     io.write "-----\t\t\t\t\t\n"
  #     io.write "  blah blah\n"
  #   end

  #   # Create data source
  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   # Parse it
  #   result = data_source.instance_eval { parse('test.html', nil) }
  #   assert_equal({ 'foo' => 'bar' }, result.attributes)
  #   assert_equal("  blah blah\n", result.content)
  # end

  # def test_parse_embedded_empty_meta
  #   # Create a file
  #   File.open('test.html', 'w') do |io|
  #     io.write "-----\n"
  #     io.write "-----\n"
  #     io.write "\nblah blah\n"
  #     io.write '-----'
  #   end

  #   # Create data source
  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   # Parse it
  #   result = data_source.instance_eval { parse('test.html', nil) }
  #   assert_equal({}, result.attributes)
  #   assert_equal("blah blah\n-----", result.content)
  # end

  # def test_parse_with_one_blank_line_after_metadata
  #   # Create a file
  #   File.open('test.html', 'w') do |io|
  #     io.write "-----\n"
  #     io.write "-----\n"
  #     io.write "\nblah blah\n"
  #     io.write '-----'
  #   end

  #   # Create data source
  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   # Parse it
  #   result = data_source.instance_eval { parse('test.html', nil) }
  #   assert_equal({}, result.attributes)
  #   assert_equal("blah blah\n-----", result.content)
  # end

  # def test_parse_with_two_blank_lines_after_metadata
  #   # Create a file
  #   File.open('test.html', 'w') do |io|
  #     io.write "-----\n"
  #     io.write "-----\n"
  #     io.write "\n\nblah blah\n"
  #     io.write '-----'
  #   end

  #   # Create data source
  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   # Parse it
  #   result = data_source.instance_eval { parse('test.html', nil) }
  #   assert_equal({}, result.attributes)
  #   assert_equal("\nblah blah\n-----", result.content)
  # end

  # def test_parse_utf8_bom
  #   File.open('test.html', 'w') do |io|
  #     io.write [0xEF, 0xBB, 0xBF].map(&:chr).join
  #     io.write "-----\n"
  #     io.write "utf8bomawareness: high\n"
  #     io.write "-----\n"
  #     io.write "content goes here\n"
  #   end

  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, encoding: 'utf-8')

  #   result = data_source.instance_eval { parse('test.html', nil) }
  #   assert_equal({ 'utf8bomawareness' => 'high' }, result.attributes)
  #   assert_equal("content goes here\n", result.content)
  # end

  # def test_parse_embedded_no_meta
  #   content = "blah\n" \
  #     "blah blah blah\n" \
  #     "blah blah\n"

  #   # Create a file
  #   File.open('test.html', 'w') { |io| io.write(content) }

  #   # Create data source
  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   # Parse it
  #   result = data_source.instance_eval { parse('test.html', nil) }
  #   assert_equal({}, result.attributes)
  #   assert_equal(content, result.content)
  # end

  # def test_parse_embedded_diff
  #   content = \
  #     "--- a/foo\n" \
  #     "+++ b/foo\n" \
  #     "blah blah\n"

  #   # Create a file
  #   File.open('test.html', 'w') { |io| io.write(content) }

  #   # Create data source
  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   # Parse it
  #   result = data_source.instance_eval { parse('test.html', nil) }
  #   assert_equal({}, result.attributes)
  #   assert_equal(content, result.content)
  # end

  # def test_parse_external
  #   # Create a file
  #   File.open('test.html', 'w') { |io| io.write('blah blah') }
  #   File.open('test.yaml', 'w') { |io| io.write('foo: bar') }

  #   # Create data source
  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   # Parse it
  #   result = data_source.instance_eval { parse('test.html', 'test.yaml') }
  #   assert_equal({ 'foo' => 'bar' }, result.attributes)
  #   assert_equal('blah blah', result.content)
  # end

  # def test_parse_internal_bad_metadata
  #   content = \
  #     "---\n" \
  #     "Hello world!\n" \
  #     "---\n" \
  #     "blah blah\n"

  #   File.open('test.html', 'w') { |io| io.write(content) }

  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   assert_raises(Nanoc::DataSources::Filesystem::Errors::InvalidMetadata) do
  #     data_source.instance_eval { parse('test.html', nil) }
  #   end
  # end

  # def test_parse_internal_four_dashes
  #   content = \
  #     "----\n" \
  #     "fav_animal: donkey\n" \
  #     "----\n" \
  #     "blah blah\n"

  #   File.open('test.html', 'w') { |io| io.write(content) }

  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   result = data_source.instance_eval { parse('test.html', nil) }
  #   assert_equal({}, result.attributes)
  #   assert_equal(content, result.content)
  # end

  # def test_parse_external_bad_metadata
  #   File.open('test.html', 'w') { |io| io.write('blah blah') }
  #   File.open('test.yaml', 'w') { |io| io.write('Hello world!') }

  #   data_source = Nanoc::DataSources::Filesystem.new(nil, nil, nil, nil)

  #   assert_raises(Nanoc::DataSources::Filesystem::Errors::InvalidMetadata) do
  #     data_source.instance_eval { parse('test.html', 'test.yaml') }
  #   end
  # end
end
