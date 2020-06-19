class Cli
	attr_accessor :article_search_keywords, 
								:view_articles_start_index, 
								:article_records_requested,
                :option_one_first_time # do we ever explicitly call this outside of the instance? I think we need a reader when we call the instance variable in another file 
                #but the instance variable is available between instance methods without a reader. We definitely don't need a writer method if you cast the local variable directly to the instance method, or just the value.  

	def initialize
		self.article_search_keywords = [] 
		self.view_articles_start_index = 0
		# self.option_one_first_time = true # don't need if write new search method
		Article.clear_all #these should be empty upon instantiation A new object knows nothing.
    Snippet.clear_all #potentially each cli needs a relationship with Article and snippet, and Visa Vi. So you could ask the cli instance what articles it knows about. Hopefully only the ones that were created during the cli's existence.
    # A new search method would allow you to not have to build those relationships.
	end

	def run
		self.greeting
		next_step = self.articles_prompt
		articles_menu_logic(next_step)
	end

	def articles_prompt(first_time = true)#might not need the argument if you write the new search method
		# unless first_time
		# 	Article.clear_all 
    #   self.article_search_keywords = [] 
      # I am thinking that you should create a custom new search method
      # This would allow you to get rid of this check for first time
      # articles_prompt would get rid of line 22-24. 
      # Your new search would be inititialized on user input when they wanted to start over
      #This would make articles prompt the main menu
      #The main menu then would be responsible for displaying the puts ""
		# end
		api_response = self.search_for_articles
		api_articles = self.select_articles(api_response) #create json_of_articles for the two methods. 
		self.make_articles(api_articles) #article should be responsible for making articles. Send the Json data over to Article
		self.articles_menu # I think the entirety of this method could be taken out. 
	end

	def articles_menu #the entirety of this method returns the input. which makes it seem like a validation method. 
		self.option_one_first_time ? option_one_lang = "first" : option_one_lang = "next" #@count = 0 in initialized @count += 1? loop
		puts ""
		puts "You've selected #{Article.all.length} articles. What would you like to do next?"
		puts "1: View list of the #{option_one_lang} 10 articles." #what happens when they choose less than 10 articles. You see the option of 10. 
    
    puts "2: Search by a keyword and return snippets from all the selected articles with that keyword."
		puts "3: Get article details by the article's title."
		puts "4: Do a new article search." # here is where you chain the new search method clearing all the data. 
		puts "5: End program."
		puts "Please enter '1', '2', '3', '4', or '5':"
		input = gets.chomp
		puts ""
		accepted_input = ['1', '2', '3', '4', '5']
		while !accepted_input.include?(input) do
			puts "Invalid input, please enter '1', '2', '3', '4', or '5':"
			input = gets.chomp
		end
		input
	end

	def process_menu
		next_step = self.articles_menu
		self.articles_menu_logic(next_step)
	end

	def articles_menu_logic(next_step)
		case next_step 
			when "1"
				if self.view_articles_start_index >= self.article_records_requested # view_articles_start_index is legit complicated overcomplicated 
					puts "There are no more articles. Please do another article search or select another menu option:"
					self.process_menu #this check could be written on the last page printed. 
				end
				self.option_one_first_time = false # don't need if you create clear all method
				self.view_ten_articles(self.view_articles_start_index)
				self.process_menu
			when "2"
				self.snippet_search_prompt
				self.view_snippet_results
				self.process_menu
			when "3"
				self.find_article_by_title_prompt
				self.process_menu
			when "4"
				self.option_one_first_time = true
				next_step = self.articles_prompt(first_time = false)
				self.articles_menu_logic(next_step)
			when "5"
				self.goodbye
		end
	end

	def greeting
		puts "Welcome to the News Search and Summary App!"
		puts "Currently, you can search The Guardian for relevant articles and return a summary of article snippets related to your search."
	end

	def goodbye
		puts "Thanks for searching!"
		puts "Contact cwisoff@gmail.com if you have any feedback or would like to contribute."
	end

	def add_search_keyword(keyword)
		self.article_search_keywords << keyword
	end

	def search_for_articles
		puts "Please enter a search term:" #possibly move this to main menu so that your method returns implicitly what you are trying to return at the end
    input = gets.chomp
    #here you ask them if what they input is spelled correctly else start over. 
		self.add_search_keyword(input) # this goes away if you fix input of multiple search terms, Well it becomes a string

    while input != "n" do #why do you need this while loop? 
      #before running this you could print what they typed, and then see if   
      api_response = ApiResponse.new(article_search_keywords)
      #You are making multiple API calls - You are right. Figuring out how the API uses 
      #search terms all together would clean this this up a lot.
      #potentially take the search terms all in one go, string.split(" ").join" AND " might fix that problem for you. 
      #Then you just make one smaller initial API call. 
			#response = api_response.get_response_page # erroneous line of code? I don't think you call this anywhere? 

			#puts "Your search returned #{api_response.total_articles} articles."
			puts "Would you like to add more search terms to refine your search? (y/n)"
			input = gets.chomp # Might be able to get rid of this line and call it on 125. I don't know if while will get angry that input is not defined

      #Changes to a method outside of search that validates y or n and loops. Returns the input. Single responsibilty of methods.
			while input != "y" && input != "n" do
				puts "'y' and 'n' are the only accepted inputs:"
				input = gets.chomp
			end
		# 	if input == 'y' 
		# 		puts "Please enter another search term:"
		# 		input = gets.chomp
		# 		self.add_search_keyword(input)
		# 	end
		# end
		api_response
	end

	def select_articles(api_response)
		#expect arg api_response to be the output of #search_for_articles
		records_limit = ApiResponse.records_limit #Constants can be accessed through namespacing. I don't think you need to have a method. ApiResponse::RECORDS_LIMIT might just access that same variable
		puts "How many of these articles would you like to select? (limit = #{records_limit})" #put the namespace access in the interpolation
		self.article_records_requested = gets.chomp.to_i #this is just input
		while self.article_records_requested > records_limit do
			puts "Please enter a number lower than #{records_limit}:"
			self.article_records_requested = gets.chomp.to_i
		end
		api_response.get_articles(self.article_records_requested)
	end

	def make_articles(api_articles)
		#expect input api_articles to be the output of #select_articles
		api_articles.each{|article_hash| Article.new_from_api_hash(article_hash)}
	end

	def view_article(article)
			puts "#{article.title}"
			puts "Publication Date: #{article.readable_publication_date}"
			puts "Url: #{article.web_url}"
	end

	def view_full_article(article)
		standard_vars = [:@title, :@publication_date, :@web_url, :@body] 
		article.instance_variables.each do |var|
			unless standard_vars.include?(var)
				var_as_str = var.to_s.delete("@")
				var_value = article.send("#{var_as_str}")
				puts "#{var_as_str.capitalize}: #{var_value}"
			end
		end
		puts ""

		scraper = Scraper.new(article.web_url)
		article.body = scraper.get_article_body
		puts "Full Article:"
		puts "#{article.body}"
	end

	def view_ten_articles(start_index)
		if Article.all # Why doens't article all exist here? 
			Article.all[start_index...(start_index+10)].each.with_index(1) do |article, i|
				puts "-------------------------------------------------------"
				print "#{i+start_index}: "
				self.view_article(article)
				puts "-------------------------------------------------------" 
			end
			self.view_articles_start_index += 10 # you can check here against the length of the collection and puts end of articles or start over at beggining of articles
		end
	end

	def find_article_by_title_prompt
		puts "Please enter the title of the article you'd like to find:"
		title_input = gets.chomp
		article = Article.find_article_by_title(title_input)
		if article 
			puts "-------------------------------------------------------"
			self.view_article(article) 
			self.view_full_article(article)
			puts "-------------------------------------------------------"
		else 
			puts ""
			puts "Sorry, there are no articles by that title. Search for a different title, or search for new articles."
		end
	end

	def snippet_search_prompt
		Snippet.clear_all
		puts "What keyword would you like to get snippets by?"
		search_term = gets.chomp
		puts ""
		puts "Thanks! Getting snippets from #{self.article_records_requested} articles."
		puts "This may take a second..."
		Article.all.each do |article|
			scraper = Scraper.new(article.web_url)
			snippet_text_ary = scraper.get_snippet(search_term)
			snippet_text_ary.each{|snippet_text| Snippet.new(snippet_text, article)}
		end
		puts "We found #{Snippet.all.length} snippet(s)."
	end

	def view_snippet_results
		puts "Here are the results:"
		puts "-------------------------------------------------------"
		Snippet.all.each do |snippet|
			puts "Article: #{snippet.article.title}"
			puts snippet.text.gsub("\n", " ")
			puts "-------------------------------------------------------"
		end
	end
end


