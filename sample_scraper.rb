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
    results['global'] = selection_rss_urls_for_global(response)
    save_to "results.json", results, format: :pretty_json
  end

  private def selection_rss_urls(response, key_word)
    rss_urls = []
    response.xpath("//*[@id='AP_block']/table/tbody/tr/td[position()=2 and contains(text(), '#{key_word}')]").each do |target|
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
    response.xpath("//*[@id='AP_block']/table/tbody/tr/td[position()=2 and contains(text(), '(') and contains(text(), ')')]").each do |target|
      pp region = target.text[/\((.*?)\)/, 1]
      regions << region
    end
    regions.uniq
  end
  private def selection_rss_urls_for_global(response)
    rss_urls = []
    response.xpath("//*[@id='AP_block']/table/tbody/tr/td[position()=2 and not(contains(text(), '(')) and not(contains(text(), ')'))]").each do |target|
      begin
        path = target.path
        path[-2] = '4'
        path.concat('/a')
        pp rss_url = target.at_xpath(path)[:href]
        rss_urls << rss_url
      rescue NoMethodError
        pp 'Error!'
        next
      end
    end
    rss_urls.uniq
  end
end

AwsFeedSpider.crawl!
