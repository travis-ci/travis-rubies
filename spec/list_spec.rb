require 'travis/rubies'

describe Travis::Rubies::List do
  subject(:list) { described_class.new(open(path)) }
  let(:path) { File.expand_path('../travis-rubies.xml', __FILE__) }

  example 'parses rubies from travis-rubies.xml' do
    expect(list.os_archs).to be == [
      Travis::Rubies::List::OsArch.new('osx', '10.9', 'x86_64', [
        Travis::Rubies::List::Ruby.new('ruby-head', 'osx', '10.9', 'x86_64', Time.parse('2014-03-28 09:06:22 UTC'))
      ]),
      Travis::Rubies::List::OsArch.new('ubuntu', '12.04', 'x86_64', [
        Travis::Rubies::List::Ruby.new('ruby-head',  'ubuntu', '12.04', 'x86_64', Time.parse('2014-03-28 08:48:50 UTC')),
        Travis::Rubies::List::Ruby.new('ruby-2.1.1', 'ubuntu', '12.04', 'x86_64', Time.parse('2014-03-24 13:04:16 UTC'))
      ])
    ]
  end
end