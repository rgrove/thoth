#--
# Copyright (c) 2008 Ryan Grove <ryan@wonko.com>
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

class MediaController < Ramaze::Controller
  engine :Erubis  
  helper :admin, :error
  layout '/layout'
  
  template_root Thoth::Config.theme.view/:media,
                Thoth::VIEW_DIR/:media
  
  deny_layout :index

  def index(filename = nil)
    unless filename && file = Media[:filename => filename.strip]
      error_404
    end
    
    send_file(file.path)
  end
  
  def delete(id = nil)
    require_auth
    
    error_404 unless id && @file = Media[id]

    if request.post?
      if request[:confirm] == 'yes'
        @file.destroy
        flash[:success] = 'File deleted.'
        redirect(Rs(:list))
      else
        redirect(Rs(:edit, id))
      end
    end
    
    @title  = "Delete File: #{@file.filename}"
    @delete = true
  end
  
  def edit(id = nil)
    require_auth
    redirect(Rs(:new)) unless id && @file = Media[id]

    @title       = "Edit Media - #{@file.filename}"
    @form_action = Rs(:edit, id)

    if request.post?
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
    
    @files    = Media.reverse_order(:created_at).paginate(page.to_i, 20)
    @prev_url = @files.prev_page ? Rs(:list, @files.prev_page) : nil
    @next_url = @files.next_page ? Rs(:list, @files.next_page) : nil
    @title    = "Media (page #{page} of #{@files.page_count})"
  end

  def new
    require_auth
    
    @title       = "Upload Media"
    @form_action = Rs(:new)
    
    if request.post?
      tempfile, filename, type = request[:file].values_at(
          :tempfile, :filename, :type)
      
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
