class SearchController < Ramaze::Controller
  engine :Erubis

  helper :cache
  helper :partial
  helper :redirect
  helper :ysearch

  layout '/layout/main'
  
  if ENABLE_CACHE
    cache :index, :ttl => 300, :key => lambda {
      request[:q] + (request[:start] || '') + (request[:count] || '')
    }
  end
  
  def index
    redirect_referrer if request[:q].nil? || request[:q].empty?
    
    @query = request[:q].strip
    
    redirect_referrer if @query.empty?

    count  = request[:count] ? request[:count].strip.to_i : 10
    start  = request[:start] ? request[:start].strip.to_i : 1
    
    count = 5   if count < 5
    count = 100 if count > 100
    start = 1   if start < 1
    start = 990 if start > 990
    
    @title = "Search results for #{@query}"
    
    @data = yahoo_search(
        "#{@query} -inurl:/tag -inurl:/archive",
        :adult_ok => 1, :results => count, :site => 'wonko.com',
        :start => start)
    
    # Set up pagination links.
    if @data[:available] > @data[:returned]
      if @data[:start] > 1
        prev_start = start - count
        prev_start = 1 if prev_start < 1
        
        @prev_url = "#{Rs()}?q=#{u(@query)}&count=#{count}&start=" +
            prev_start.to_s
      end
      
      if @data[:available] > (@data[:start] + @data[:returned])
        next_start = start + @data[:returned]
        next_start = 1001 - count if next_start > (1001 - count)
        
        @next_url = "#{Rs()}?q=#{u(@query)}&count=#{count}&start=" +
            next_start.to_s
      end
    end
      
  rescue SearchError => e
    @error = e.message
    @data  = {:results => []}
  end
end
