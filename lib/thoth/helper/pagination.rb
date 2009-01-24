#--
# Copyright (c) 2009 Ryan Grove <ryan@wonko.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#   * Neither the name of this project nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#++

module Thoth

  # The Pager class provides a simple wrapper around a paginated Sequel dataset.
  class Pager

    # Initializes a new Pager instance wrapping the given Sequel _dataset_ and
    # using _url_ as the template for all generated URLs. _url_ should be a
    # string containing an sprintf flag (such as <tt>%s</tt>) in place of the
    # page number.
    def initialize(dataset, url)
      @dataset = dataset
      @url     = url
    end

    # Returns the number of the current page.
    def current_page
      @dataset.current_page
    end

    # Returns the number of records in the current page.
    def current_page_record_count
      @dataset.current_page_record_count
    end

    # Returns the record range for the current page.
    def current_page_record_range
      @dataset.current_page_record_range
    end

    # Iterates over all pages within 5 steps from the current page, yielding the
    # page number and URL for each.
    def navigate # :yields: page, url
      nav_start = [current_page - 5, 1].max
      nav_end   = [nav_start + 9, page_count].min
      (nav_start..nav_end).each {|page| yield page, url(page) }
    end

    # Returns +true+ if the total number of pages is greater than 1.
    def navigation?
      page_count > 1
    end

    # Returns the number of the next page or +nil+ if the current page is the
    # last.
    def next_page
      @dataset.next_page
    end

    # Returns the URL for the next page or +nil+ if the current page is the
    # last.
    def next_url
      next_page ? url(next_page) : nil
    end

    # Returns the total number of pages.
    def page_count
      @dataset.page_count
    end

    # Returns the page range.
    def page_range
      @dataset.page_range
    end

    # Returns the number of records per page.
    def page_size
      @dataset.page_size
    end

    # Returns the number of the previous page or +nil+ if the current page is
    # the first.
    def prev_page
      @dataset.prev_page
    end

    # Returns the URL for the previous page or +nil+ if the current page is the
    # first.
    def prev_url
      prev_page ? url(prev_page) : nil
    end

    # Returns the total number of records in the dataset.
    def record_count
      @dataset.pagination_record_count
    end

    # Returns the URL for the specified page number.
    def url(page)
      sprintf(@url, page.to_i)
    end

  end
end

module Ramaze; module Helper
  module Pagination

    def pager(dataset, url = Rs('%s'))
      Thoth::Pager.new(dataset, url)
    end

  end
end; end
