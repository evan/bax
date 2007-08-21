
require 'open-uri'
require 'rubygems'
require 'script/support'
require 'highline/import'
require 'cgi'

namespace :apache do
  task :start => [:stop] do
    Dir.chdir File.dirname(__FILE__) do
      system("ulimit -n 1000; /opt/local/apache2/bin/httpd -f #{ROOT}/../httpd.conf")
    end
  end
  
  task :stop do
    system("ps awx | grep httpd | grep -v grep | awk '{print $1}' | xargs kill -9")
  end
end

task :start => [:'apache:start']
task :stop => [:'apache:stop']

namespace :article do
  
  task :link do
    link_article find_article
  end
  
  task :index do
    with_dir do 
      articles = Dir['articles/**/intro.element'].sort_by do |el|
        File.mtime el
      end.reverse
      puts "found #{articles.size} articles"    
  
      articles = articles.map do |el|
        File.dirname(el)
      end
      
      File.open("all/body.element", 'w') do |f|
        articles.each do |article|
          # build the all articles index  
          f.puts "<!--#include virtual='/#{article}/post_index.element' -->"
        end
      end
  
        File.open("recent.element", "w") do |recent|
          File.open("content.element", "w") do |content|
            File.open("xml/content.element", "w") do |xml|    
              # build the most recent lists
              articles[0..5].each do |article|
              title = open("#{article}/title.element").read
              recent.puts "<li class=\"item\"><a href=\"/#{article}\">#{title}</a></li>"
              content.puts "<!--#include virtual='/#{article}/post_short.element' -->"
              xml.puts "<!--#include virtual='/#{article}/xml.post.element' -->"
            end
          end
        end
      end
      
    end
  end

  task :new do
    base = "/articles/#{Time.now.strftime('%Y/%m/%d')}/"
    title = ask("new url: #{base} ")
    url = base + title.gsub(' ', '-').gsub(/[^\w\-]/, '')
    with_dir(url) do
      File.open('title.element', 'w') {|f| f.puts title }
      File.open('date.element', 'w') {|f| f.write Time.now }
      File.open('url.element', 'w') {|f| f.write url }
      File.open('body.element', 'w') {|f| f.puts ".</p>"}
      File.open('intro.element', 'w') {|f| f.puts "<p>Intro" }
      File.open('ellipsis.element', 'w') {|f| f.puts "...</p>" }
    end    
    link_article url
    index_comments url
    puts "ok"
  end
  
  task :delete do
    with_dir do
      article = find_article
      if agree("delete #{article}? ")
        system("rm -rf #{article}")
      end
    end
    Rake::Task[:index].invoke
  end

end

task :new => [:'article:new']
task :delete => [:'article:delete']
task :index => [:'article:index']

task :slogan do
  with_dir do
    slogans = open('../slogans.txt').readlines
    File.open('slogan.element', 'w') do |f|
      f.write slogans[rand(slogans.size)]
    end
  end
end

task :import do
  load 'script/import.rb'
end

namespace :comments do
  task :open do
    allow_comments(find_article, true)
  end
  
  task :close do
    allow_comments(find_article, false)
  end
  
  task :index do
    index_comments find_article
  end
end

task :open => [:'comments:open']
task :close => [:'comments:close']

task :dir do
  puts find_article
end

task :default => [:dir]

