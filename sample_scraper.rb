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
    selection_area_blocks(response).each do |area_block|
      results[area_block] =  {}
      selection_regions(response, area_block).each do |region|
        query = xpath_query(area_block, "contains(text(), '#{region}')")
        results[area_block][region] = selection_rss_urls(response, query)
      end
      query = xpath_query(area_block,"not(contains(text(), '(')) and not(contains(text(), ')'))")
      results[area_block]['global'] = selection_rss_urls(response, query)
      save_to "results.json", results, format: :pretty_json
    end
  end

  private def selection_area_blocks(response)
    area_blocks = []
    response.xpath("//*[@id='current_events_block']/div/*[contains(@id, '_block')]").each do |target|
      pp area_block = target[:id]
      area_blocks << area_block
    end
    area_blocks.uniq
  end
  private def selection_regions(response, area_block)
    regions = []
    response.xpath(xpath_query(area_block, "contains(text(), '(') and contains(text(), ')')")).each do |target|
      pp region = target.text[/\((.*?)\)/, 1]
      regions << region
    end
    regions.uniq
  end
  private def selection_rss_urls(response, query)
    rss_urls = []
    response.xpath(query).each do |target|
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

  private def xpath_query(area_block, query)
    "//*[@id='#{area_block}']/table/tbody/tr/td[position()=2 and #{query}]"
  end
end

AwsFeedSpider.crawl!
