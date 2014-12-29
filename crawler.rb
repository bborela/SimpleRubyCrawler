require 'rubygems'
require 'nokogiri'
require 'open-uri'

class Ingredient
  attr_accessor :name
  attr_accessor :rating
  attr_accessor :description
  attr_accessor :categories
  attr_reader :read_more_link
  
  def read_more_link=(str)
    @read_more_link = "#{PaulasChoiceWebCrawler::BASE_PAULASCHOICE_URL}#{str}"
  end
end

class PaulasChoiceWebCrawler
  INGREDIENTS_PER_PAGE = 100
  BASE_PAULASCHOICE_URL = "http://www.paulaschoice.com"
  INGREDIENTS_DICTIONARY_BASE_URL = "#{BASE_PAULASCHOICE_URL}/cosmetic-ingredient-dictionary?count=#{INGREDIENTS_PER_PAGE}&page="

  def scrape
    @number_of_pages = get_number_of_pages
    (1..@number_of_pages).each do |page_index|
      ingredients = extract_ingredients page_index
      ingredients.each {|ingredient| puts "\"#{ingredient.name}\",#{ingredient.rating},\"#{ingredient.description}\",\"#{ingredient.categories}\",#{ingredient.read_more_link}"}
      sleep 0.5
    end
  end

  private

  def get_number_of_pages
    #return the number of pages our script will have to scrape
    page = Nokogiri::HTML(open("#{INGREDIENTS_DICTIONARY_BASE_URL}1"))
    page.css('div .pagecount option').length
  end

  def get_ingredients_table_rows
    @current_page.css('div .wl-ingredientlist .base tr')
  end

  def create_ingredient_from_row(row)
    #all the HTML parsing happens here
    ingredient = Ingredient.new

    ingredient.rating = row.css('.col-rating').text.strip

    ingredient_description_element = row.css('.col-ingredient')

    ingredient.name = ingredient_description_element.css('h2.name').text.strip

    ingredient.categories = ingredient_description_element.css('.categories a').inject('') { |categories, element| categories + ", " + element.text }
    ingredient.categories = ingredient.categories[2..-1]  #remove leading comma and space
     
    read_more_element = ingredient_description_element.css('.read-more')[0]
    ingredient.read_more_link = read_more_element['href'] if read_more_element
    
    #remove these elements from the ingredients description
    ingredient_description_element.css('.categories').remove
    ingredient_description_element.css('.read-more').remove

    ingredient.description = ingredient_description_element.css('p.description').text.split.join(' ')  #trick to remove tabs, spaces, newlines
    ingredient.description.gsub! /"/, '""'  #replace double quotes for double double quotes so our CSV will interpret the information as text

    return ingredient
  end

  def extract_ingredients(page_index)
    @current_page = Nokogiri::HTML(open("#{INGREDIENTS_DICTIONARY_BASE_URL}#{page_index}"))

    ingredients = []

    get_ingredients_table_rows.each do |row|
      ingredients.push create_ingredient_from_row row
    end

    return ingredients
  end
end

crawler = PaulasChoiceWebCrawler.new
crawler.scrape
