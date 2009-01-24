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
  class MediaController < Ramaze::Controller
    map       '/media'
    layout    '/layout'
    view_root File.join(Config.theme.view, 'media'),
              File.join(VIEW_DIR, 'media')

    helper      :admin, :error, :pagination
    deny_layout :index

    def index(filename = nil)
      unless filename && file = Media[:filename => filename.strip]
        error_404
      end

      send_file(file.path)

    rescue Errno::ENOENT => e
      error_404
    end

    def delete(id = nil)
      require_auth

      error_404 unless id && @file = Media[id]

      if request.post?
        error_403 unless form_token_valid?

        if request[:confirm] == 'yes'
          @file.destroy
          flash[:success] = 'File deleted.'
          redirect(Rs(:list))
        else
          redirect(Rs(:edit, id))
        end
      end

      @title          = "Delete File: #{@file.filename}"
      @delete         = true
      @show_file_edit = true
    end

    def edit(id = nil)
      require_auth

      redirect(Rs(:new)) unless id && @file = Media[id]

      @title          = "Edit Media - #{@file.filename}"
      @form_action    = Rs(:edit, id)
      @show_file_edit = true

      if request.post?
        error_403 unless form_token_valid?

        tempfile, filename, type = request[:file].values_at(
            :tempfile, :filename, :type)

        @file.mimetype = type || 'application/octet-stream'

        begin
          unless File.directory?(File.dirname(@file.path))
            FileUtils.mkdir_p(File.dirname(@file.path))
          end

          FileUtils.mv(tempfile.path, @file.path)
          @file.save

          flash[:success] = 'File saved.'
          redirect(Rs(:edit, id))
        rescue => e
          @media_error = "Error: #{e}"
        end
      end
    end

    def list(page = 1)
      require_auth

      page = page.to_i

      @columns  = [:filename, :size, :created_at, :updated_at]
      @order    = (request[:order] || :asc).to_sym
      @sort     = (request[:sort]  || :filename).to_sym
      @sort     = :created_at unless @columns.include?(@sort)
      @sort_url = Rs(:list, page)

      @files = Media.paginate(page, 20).order(@order == :desc ? @sort.desc :
          @sort)

      @title = "Media (page #{page} of #{[@files.page_count, 1].max})"
      @pager = pager(@files, Rs(:list, '%s', :sort => @sort, :order => @order))
    end

    def new
      require_auth

      @title       = "Upload Media"
      @form_action = Rs(:new)

      if request.post?
        error_403 unless form_token_valid?

        tempfile, filename, type = request[:file].values_at(
            :tempfile, :filename, :type)

        # Ensure that the filename is a name only and not a full path, since
        # certain browsers are stupid (I'm looking at you, IE).
        filename = filename[/([^\/\\]+)$/].strip

        if filename.empty?
          return @media_error = 'Error: Invalid filename.'
        end

        file = Media.new do |f|
          f.filename = filename
          f.mimetype = type || 'application/octet-stream'
        end

        begin
          unless File.directory?(File.dirname(file.path))
            FileUtils.mkdir_p(File.dirname(file.path))
          end

          FileUtils.mv(tempfile.path, file.path)
          file.save

          flash[:success] = 'File uploaded.'
          redirect(Rs(:edit, file.id))
        rescue => e
          @media_error = "Error: #{e}"
        end
      end
    end
  end
end
