
# imports a typo blog, as long as its exactly like old snax

require 'rubygems'
require 'hpricot'
require 'chronic'

def import_article base, url
  puts "article for #{url}"
  with_dir url do
    system("rm -rf *")
    doc = get base, url
    title = (doc/:'p.dt').innerHTML
    tags = (doc/:'.time_info'/:a).map {|s| s.innerHTML} - ['edit']

    contents = (doc/'#content'/'.entries'/:dd)[1].innerHTML
    # fix some image urls
    contents = contents.gsub("/images/", "/files/").gsub(/style=('|").*?('|")/, "")
    
    contents = contents.split("<h2>")    
    date = Chronic.parse((doc/'.typo_date')[0].innerHTML.split(" ")[1..3].join(" "))
    intro = contents.shift
    intro = contents.shift if intro !~ /\w/
    body = contents.any? ? "<h2>" + contents.join("<h2>") : nil
    ellipsis = nil

    if body and intro =~ /^(.*)(.)(<\/.*?>)[\s\n]*$/
      intro = $1
      ellipsis = "..." + $3
      body = $2 + $3 + body
    end
          
    comments = (doc/'.comments'/:li).map do |li|
      h = {}
      h['author'] = (li/:cite).innerHTML
      if li.attributes['class'] == "author-comment"
        h['author'] = "<span class=\"me\">#{h['author']}</span>"
        h['date'] = (li/:h3).innerHTML[/wrote(.*?)later/, 1]
        h['date'] = date + (Chronic.parse(h['date'] + "from now") - Time.now)
      end
      h['body'] = li.innerHTML.sub(/.*<\/h3>/, '')
      h
    end
    
    # write data for post
    %w(body intro title url tags ellipsis date).each do |f|
      File.open(f + '.element', 'w') do |file|
        file.write instance_eval(f)
      end
    end    
    set_modtime url, date
    
    # write comments
    system("mkdir -p comments")
    Dir.chdir "comments" do
      last_date = date
      comments.each do |c|
        comment_url = add_comment url, c
        c['date'] ||= last_date # XXX total hack
        last_date = c['date']
        set_modtime comment_url[0..-17], c['date'] if comment_url
      end
    end
    
    # regular tasks    
    link_article url, body, false
    index_comments url
  end
end

# run
(get(OPTIONS['url'], "/articles/all")/:a).map do |a|
  a.attributes['href']
end.select do |url|
  url =~ /articles\// and url !~ /category|all/
#  end.uniq[0..1].reverse.each do |url|
end.uniq.reverse.each do |url|
  import_article(OPTIONS['url'], url)
end
Rake::Task[:'article:index'].invoke  
