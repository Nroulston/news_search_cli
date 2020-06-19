require 'awesome_print'
require 'pry'

class ApiResponse
	BASE_PATH = "https://content.guardianapis.com/search?q="
	API_KEY = "62e6b16d-8157-43d2-ab3a-647afb341c7e"
	RECORDS_LIMIT = 200
	attr_accessor :search_keywords, :total_articles, :pages

	def initialize(search_keywords)
		self.search_keywords = search_keywords
		self.get_response_page
	end

	def self.records_limit
		RECORDS_LIMIT
	end

	def generate_search_url(page=1)
		# eample result: https://content.guardianapis.com/search?q=debate%20AND%20economy&tag=politics/politics&from-date=2014-01-01&api-key=test
    search_terms = self.search_keywords.map{|keyword| keyword}.join("%20AND%20")
    #from what I understand the %20 is automatically placed into white space. 
		BASE_PATH + search_terms + "&api-key=#{API_KEY}&page=#{page}"
	end

	def get_response_page(page=1)
		uri = URI.parse(generate_search_url(page))
		response = JSON.parse(uri.open.string)
		self.total_articles = response["response"]["total"]
		self.pages = response["response"]["pages"]
		response
	end

	def get_results(page_num)
		self.get_response_page(page_num)["response"]["results"]
	end

	def get_articles(articles_desired)
		if articles_desired <= RECORDS_LIMIT
			pages_needed = articles_desired/10 + 1
			remainder_on_last_page = articles_desired%10
			articles = (1...pages_needed).map{|page_num| self.get_results(page_num)}.flatten
			remaining_articles = self.get_results(pages_needed)[0...remainder_on_last_page]
			articles_desired = articles + remaining_articles
			
			needed_keys = ["sectionName", "webPublicationDate", "webTitle", "webUrl", ]
			articles_desired.map do |article|
				article.select{|k,v| needed_keys.include?(k)}
			end
		end
	end
end


