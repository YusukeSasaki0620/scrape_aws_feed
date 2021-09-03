# github_spider.rb
require 'kimurai'
require 'pry'

class AwsFeedSpider < Kimurai::Base
  @name = "aws_feed_spider"
  @engine = :mechanize
  @start_urls = ["https://status.aws.amazon.com"]
  @config = {
    user_agent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.84 Safari/537.36",
    # before_request: { delay: 4..7 }
  }

  def parse(response, url:, data: {})
    key_word = 'Tokyo'
    item = {}
    item[key_word] = []
    response.xpath("//*[@id='AP_block']/table/tbody/tr/td[contains(text(), '#{key_word}')]").each do |target|
      path = target.path
      path[-2] = '4'
      path.concat('/a')
      pp rss_url = target.at_xpath(path)[:href]
      item[key_word] << rss_url
    end
    save_to "results.json", item, format: :pretty_json
  end
end

AwsFeedSpider.crawl!
