#!/usr/bin/env ruby
# coding: utf-8

bad = " "

require "csv"
require "mechanize"
require 'nokogiri'

agent = Mechanize.new{ |agent| agent.history.max_size=0 }
agent.user_agent = 'Mozilla/5.0'

base = "http://www.basketball-reference.com/leagues"
#http://www.basketball-reference.com/leagues/NBA_2016.html
tl_base = "http://www.basketball-reference.com/teams"

table_xpath = '//*[@id="all_team_stats"]/comment()'
tl_xpath = '//*[@id="tgl_basic"]/tbody/tr'

first_year = 2016
last_year = 2016

if (first_year==last_year)
  results = CSV.open("csv/team_logs_#{first_year}.csv","w")
else
  results = CSV.open("csv/team_logs_#{first_year}-#{last_year}.csv","w")
end

(first_year..last_year).each do |year|

  url = "#{base}/NBA_#{year}.html"
  print "Pulling year #{year}"

  begin
    page = agent.get(url)
  rescue
    retry
  end

  comment_start = '<!--'
  comment_end = '-->'

  table_str = page.parser.xpath(table_xpath)
  table_str = table_str.to_s
  table_str = table_str.split(/#{comment_start}(.*?)#{comment_end}/m)[1]

  doc = Nokogiri::HTML(table_str, 'UTF-8')
  node = doc.xpath('//*[@id="team_stats"]/tbody/tr/td/a')

  teams = []
  node.each do |team|
    teams << team["href"].split("/")[2]
  end
  # page.parser.xpath(table_xpath).each do |team|
    # teams << team["href"].split("/")[2]
  # end

  print " - found #{teams.size} teams\n"

  teams.each do |team_id|

    tl_url = "#{tl_base}/#{team_id}/#{year}/gamelog/"

    begin
      page = agent.get(tl_url)
    rescue
      retry
    end

    page.parser.xpath(tl_xpath).each do |tr|
      row = [year,team_id]
      tr.xpath("td").each_with_index do |td,i|
        field = td.text
        if (field==nil) or (field.size==0)
          row << nil
        else
          row << field
        end
      end
      if (row.size>2)
        results << row
      end
    end

    results.flush

  end
end

results.close
