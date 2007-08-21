
ROOT = File.expand_path(File.dirname(__FILE__) + "/../public")
BT = BACKTRACK = "../../../../.."

require "#{ROOT}/../settings"

def link_article url, has_body = true, with_comments = true
  with_dir url do
    {
      "content.element" => "post_full.element",
      "index.html" => "#{BT}/index.html",
      "post_short.element" => "#{BT}/post_short.element",
      "post_full.element" => "#{BT}/post_full.element",
      "post_index.element" => "#{BT}/post_index.element",
      "xml.post.element" => "#{BT}/xml/post.element",
      "link.element" => "#{BT}/nothing.element",
    }.merge(has_body ? 
      {"link.element" => "#{BT}/read_more.element"} : 
      {}
    ).each do |name, target|
      File.delete name rescue nil
      system("ln -s #{target} #{name}")
    end    
  end
  allow_comments url, with_comments
end

def allow_comments(url, yes = true)
  with_dir "#{url}/comments" do
    File.delete "form.element" rescue nil
    system("ln -s #{BT}/../#{yes ? 'open' : 'closed'}.element form.element")
  end  
end

def index_comments url
  with_dir(url + "/comments") do
    File.delete("content.element") rescue nil
    File.open("content.element", "a+") do |i|
      File.open("count.element", 'w') do |f|
        comments = Dir['**/content.element'].sort - ["content.element"]
        f.puts(case comments.size 
          when 0 
            "no comments yet"
          when 1 
            "#{comments.size} comment"
          else
            "#{comments.size} comments"
          end)
        comments.each do |comment|
          i.puts "<!--#include virtual='#{comment}' -->"
        end
      end
    end
  end
end

def add_comment url, c
  return if c['body'] =~ /no comments yet/    
  current = nil
  with_dir "#{url}/comments" do
    last_body_file = Dir['**/body.element'].sort.last
    current = (last_body_file.to_i + 1).to_s.rjust(3, "0")
    
    unless c['body'] == (open(last_body_file).read.strip rescue nil)
      # check if the last comment body was identical
      with_dir "#{url}/comments/#{current}" do
        # nope, hook up this record
        File.open("author.element", 'w') {|f| f.write c['author'] }
        File.open("body.element", 'w') {|f| f.write c['body'] }
        File.open("index.element", 'w') {|f| f.write current }
        File.open("date.element", 'w') {|f| f.write c['date'] || Time.now.to_s }
        system("ln -s #{BT}/../../comment.element content.element")
      end
      "/#{url}/comments/#{current}/content.element"
    else
      "/nothing.element"
    end
  end
end

def notify msg
  # posts a message to the blog's twitter account
  $LOAD_PATH << 'twitter/lib'
  require "twitter"
  Twitter::Base.new(OPTIONS['twitter']['user'], OPTIONS['twitter']['password']).update msg
end

def set_modtime url, time
  time = time.strftime('%Y%m%d%H%M')
  with_dir url do
    system("touch -m -t #{time} body.element")
  end
end

def with_dir url = "."
  # move to a directory relative to /BT
  # does not nest! recursing directories is bug-prone  
  dir = url.gsub(/^\/+|\/+$/, '')
  Dir.chdir ROOT do
    system("mkdir -p #{dir}")
    Dir.chdir dir do
      raise "Directory escaped! #{url} -> #{Dir.getwd}!" unless Dir.getwd =~ /public/
      yield
    end
  end
end

def get base, url
  Hpricot.parse(open(base + url).read)
end

def find_article(url = ENV['a'])
  raise "No 'a' variable supplied" unless url
  with_dir "articles" do
    matches = Dir["**/*#{url}*"].select {|s| s !~ /(html|xml|element)$/}
    unless matches.size == 1
      puts "#{url.inspect} match is not unique:"
      puts matches 
      exit
    end
    "articles/" + matches.first
  end
end
