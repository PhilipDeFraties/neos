require 'faraday'
require 'figaro'
require 'pry'
# Load ENV vars via Figaro
Figaro.application = Figaro::Application.new(environment: 'production', path: File.expand_path('../config/application.yml', __FILE__))
Figaro.load

class NearEarthObjects
  attr_reader :asteroid_list,
              :largest_asteroid_diameter,
              :total_number_of_asteroids

  def initialize(date)
    @conn = self.access_api_by_date(date)
    @asteroids_list_data = self.get_asteroids_list_data
    @parsed_asteroids_data = self.parse_data(date)
    @largest_asteroid_diameter = self.get_largest_asteroid_diameter
    @total_number_of_asteroids = self.get_total_asteroids
    @asteroid_list = self.format_asteroid_data
  end

  def access_api_by_date(date)
    @conn = Faraday.new(
      url: 'https://api.nasa.gov',
      params: { start_date: date, api_key: ENV['nasa_api_key']}
    )
  end

  def get_asteroids_list_data
    @asteroids_list_data = @conn.get('/neo/rest/v1/feed')
  end


  def parse_data(date)
    @parsed_asteroids_data = JSON.parse(@asteroids_list_data.body, symbolize_names: true)[:near_earth_objects][:"#{date}"]
  end


  def get_largest_asteroid_diameter
    @parsed_asteroids_data.map do |astroid|
      astroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i
    end.max { |a,b| a<=> b}
  end


  def get_total_asteroids
    @parsed_asteroids_data.count
  end


  def format_asteroid_data
    @parsed_asteroids_data.map do |astroid|
      {
        name: astroid[:name],
        diameter: "#{astroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i} ft",
        miss_distance: "#{astroid[:close_approach_data][0][:miss_distance][:miles].to_i} miles"
      }
    end
  end
end
