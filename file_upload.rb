require 'sinatra/base'
require 'haml'

class FileUpload < Sinatra::Base
  configure do
    enable :static
    enable :sessions

    set :views, File.join(File.dirname(__FILE__), 'views')
    set :public_folder, File.join(File.dirname(__FILE__), 'public')
  end

  not_found do
    'err 404'
  end

  error do
    "err (#{request.env['sinatra.error']})"
  end

  get '/' do
    haml :index
  end

  def log name, params
    STDERR.write "[#{name}] #{params.to_s}\n"
  end

  def check_token dir, token
    saved_token = `cat #{dir}/.token`.strip
    if token == saved_token
      return true
    end 
    return false
  end

  def check_dirname dirname
    return dirname.match /^[a-zA-Z0-9_-]+$/
  end

  def get_dir dirname
    return "upload/#{dirname}"
  end

  post '/upload' do
    log '/upload', params

    if params[:qqfile] && params[:dirname] && params[:token]

      dirname = params[:dirname]
      dir = get_dir params[:dirname]
      token = params[:token]

      allowed = check_dirname(dirname) && check_token(dir, token)

      if allowed
        filename = params[:qqfile][:filename]
        file = params[:qqfile][:tempfile]

        File.open(File.join(dir, filename), 'wb') do |f|
          f.write file.read
        end

        return '{"success":true}'
      end

    end

    return '{"success":false}'
  end

  post '/mkdir' do
    log '/mkdir', params

    dirname = params[:dirname]
    token = params[:token]

    return "err" if !dirname||!token

    dir = get_dir params[:dirname]

    return "err" if !check_dirname(dirname)

    allowed = false
    if Dir.exists? dir
      if check_token dir, token
        allowed = true
      end
    else
      `mkdir -p #{dir}`
      `echo #{token} >> #{dir}/.token`
      allowed = true
    end

    if allowed
      redirect "upload.html?dirname=#{dirname}&token=#{token}"
    else
      "Falsches token/Wrong token <a href='/'>Zur&uuml;ck/Back</a>"
    end
  end

  get "/list_dir/:dirname/:token" do
    log '/list_dir', params
    
    dirname = params[:dirname]
    dir = get_dir dirname
    token = params[:token]

    allowed = check_dirname(dirname) && check_token(dir, token)

    if allowed
      s = "<ul>"
      s += Dir[dir+"/*"].map { |i| i.gsub(get_dir(""),"") }.map { |i| "<li>#{i}</li>" }.join "\n"
      s += "</ul>"
      return s
    end

    return ""
  end

  get '/check/:dirname/:token' do
    log '/check', params

    dirname = params[:dirname]
    dir = get_dir dirname
    token = params[:token]

    if check_dirname(dirname) && check_token(dir, token)
      return "true"
    end

    return "false"
  end

end

