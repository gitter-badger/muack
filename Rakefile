
begin
  require "#{dir = File.dirname(__FILE__)}/task/gemgem"
rescue LoadError
  sh 'git submodule update --init'
  exec Gem.ruby, '-S', 'rake', *ARGV
end

Gemgem.dir = dir
($LOAD_PATH << File.expand_path("#{Gemgem.dir}/lib")).uniq!

desc 'Generate gemspec'
task 'gem:spec' do
  Gemgem.spec = Gemgem.create do |s|
    require 'muack/version'
    s.name    = 'muack'
    s.version = Muack::VERSION

    %w[].each{ |g| s.add_runtime_dependency(g) }
  end

  Gemgem.write
end
