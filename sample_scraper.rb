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
    results = {}
    selection_regions(response).each do |region|
      results[region] = selection_rss_urls(response, region)
    end
    save_to "results.json", results, format: :pretty_json
  end

  private def selection_rss_urls(response, key_word)
    rss_urls = []
    response.xpath("//*[@id='AP_block']/table/tbody/tr/td[contains(text(), '#{key_word}')]").each do |target|
      path = target.path
      path[-2] = '4'
      path.concat('/a')
      pp rss_url = target.at_xpath(path)[:href]
      rss_urls << rss_url
    end
    rss_urls.uniq
  end
  private def selection_regions(response)
    regions = []
    response.xpath("//*[@id='AP_block']/table/tbody/tr/td[contains(text(), '(') and contains(text(), ')')]").each do |target|
      pp region = target.text[/\((.*?)\)/, 1]
      regions << region
    end
    regions.uniq
  end
end

AwsFeedSpider.crawl!
