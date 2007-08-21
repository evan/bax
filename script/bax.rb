#!/usr/bin/env ruby

require 'cgi'
require 'support'
$LOAD_PATH << 'superredcloth/lib'
require 'superredcloth'
require 'set'
require 'html/tokenizer'
require 'html/node'
require 'white_list_helper'

self.class.send(:include, WhiteListHelper)

cgi = CGI.new
params = Hash[*cgi.params.map do |key, values| 
  [key, white_list(key == 'body' ? SuperRedCloth.new(values.join).to_html : values.join)]
end.flatten]

old_author = params['author']

# mangle some urls
if !(blog = params['blog'].chomp('/')).empty?
  blog = "http://" + blog unless blog =~ /http:\/\//
  author = params['author']
  author = "<a href=\"#{blog}\" rel=\"nofollow\">#{author}</a>"
  if params['author'] =~ /OPTIONS['author']/ and blog == OPTIONS['url']
    author = "<span class=\"me\">#{author}</span>"
  end
  params['author'] = author
end

if !params['article']
  # preview... parse ourselves so we don't have to write to the filesystem
  puts "Content-Type: text/html\n\n"
  puts "<div id=\"preview-inner\">"
  open("#{File.dirname(__FILE__)}/../public/comment.element").each do |line|  
    if line =~ /#(flastmod|include) virtual='(.*?).element'/
      repl = ($1 == "flastmod" ? "preview" : params[$2]) || "nil"
      line.gsub! /<!--.*?-->/, repl
    end
    puts line
  end
  puts "</div>"
  
elsif missing = ['author', 'contact', 'body'].detect{|s| params[s].empty? }
  missing = 'email' if missing == 'contact'
  puts "Content-Type: text/html\n\n"
  puts "<p class=\"error\">#{missing.capitalize} is required.</p>"
  
elsif params['email'].empty? and !params['body'].empty?
  # submitted, and not spam, we hope
  params['article'] =~ /(.*)\/(articles\/.*?)\/($|\#|\?)/
  base, url = $1, $2
  
  comment_url = add_comment url, params
  puts "Location: #{comment_url}\n\n"
  STDOUT.close # don't make the user wait while we clean shit up

  index_comments url  
  notify "New comment by #{old_author} on #{base}/#{url}#comments"
else
  # else spam
  puts "Content-Type: text/plain\n\n"
  puts "Ok." # lies
end
