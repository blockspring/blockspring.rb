require 'rest_client'
require 'json'
require 'base64'
require 'mime/types'
require "tempfile"

module Blockspring
  def self.parse(input_params, json_parsed = true)
    @request = Request.new

    if json_parsed == true
      params = input_params
    else
      begin
        params = JSON.parse(input_params)
      rescue
        raise "You didn't pass valid json inputs."
      end
    end

    if !(params.is_a?(Hash))
      raise "Can't parse keys/values from your json inputs."
    end

    if !(params.has_key?("_blockspring_spec") && params["_blockspring_spec"])
      @request.instance_variable_set("@params", params)
    else
      for var_name in params.keys
        if (var_name == "_blockspring_spec")
          # pass
        elsif ((var_name == "_errors") && params[var_name].is_a?(Array))
          for error in params[var_name]
            if (error.is_a?(Hash)) && (error.has_key?("title"))
              @request.addError(error)
            end
          end
        elsif ((var_name == "_headers") && params[var_name].is_a?(Hash))
          headers = params[var_name]
          if(headers.is_a?(Hash))
            @request.addHeaders(stringify_keys(headers))
          else
            @request.addHeaders(headers)
          end
        elsif (
          params[var_name].is_a?(Hash) and
          params[var_name].has_key?("filename") and
          params[var_name]["filename"] and
          # either data or url must exist and not be empty
          (
            (params[var_name].has_key?("data") and params[var_name]["data"]) or
            (params[var_name].has_key?("url") and params[var_name]["url"]))
          )
            suffix = "-%s" % params[var_name]["filename"]
            tmp_file = Tempfile.new(["",suffix])
            if (params[var_name].has_key?("data"))
              begin
                tmp_file.write(Base64.decode64(params[var_name]["data"]))
                @request.params[var_name] = tmp_file.path
              rescue
                @request.params[var_name] = params[var_name]
              end
            else
              begin
                tmp_file.write(RestClient.get(params[var_name]["url"]))
                @request.params[var_name] = tmp_file.path
              rescue
                @request.params[var_name] = params[var_name]
              end
            end
            tmp_file.close
        else
          @request.params[var_name] = params[var_name]
        end
      end
    end

    return @request
  end

  def self.run(block, data = {}, api_key = nil )
    if !(data.is_a?(Hash))
      raise "your data needs to be a dictionary."
    end

    data = data.to_json
    api_key = api_key || ENV['BLOCKSPRING_API_KEY'] || ""
    blockspring_url = ENV['BLOCKSPRING_URL'] || 'https://sender.blockspring.com'
    block = block.split("/")[-1]

    begin
      response = RestClient.post "https://sender.blockspring.com/api_v2/blocks/#{block}?api_key=#{api_key}", data, :content_type => :json
    rescue => e
      response = e.response
    end

    results = response.body

    begin
      return JSON.parse(results)
    rescue
      return results
    end
  end

  def self.runParsed(block, data = {}, api_key = nil )
    if !(data.is_a?(Hash))
      raise "your data needs to be a dictionary."
    end

    data = data.to_json
    api_key = api_key || ENV['BLOCKSPRING_API_KEY'] || ""
    blockspring_url = ENV['BLOCKSPRING_URL'] || 'https://sender.blockspring.com'
    block = block.split("/")[-1]

    begin
      response = RestClient.post "https://sender.blockspring.com/api_v2/blocks/#{block}?api_key=#{api_key}", data, :content_type => :json
    rescue => e
      response = e.response
    end

    results = response.body


    begin
      parsed_results = JSON.parse(results)

      if (!parsed_results.is_a?(Hash))
        return parsed_results
      else
        parsed_results["_headers"] = response.headers
      end
    rescue
      return results
    end

    return self.parse(parsed_results, true)
  end

  def self.define(block)
    @response = Response.new

    #stdin parsing
    if(!STDIN.tty?)
      @request = self.parse($stdin.read, false)
    else
      @request = Request.new
    end

    #args parsing
    if (ARGV.length > 0)
      argv = {}
      for arg in ARGV
        found_match = /([^=]*)\=(.*)/.match(arg)
        if found_match
          found_match = found_match.captures
          if found_match[0][0..1] == "--"
            argv[ found_match[0][2..-1] ] = found_match[1]
          else
            argv[ found_match[0] ] = found_match[1]
          end
        end
      end
    else
      argv = {}
    end

    for key in argv.keys
      @request.params[key] = argv[key]
    end

    block.call(@request, @response)
  end

  class Request
    def initialize
      @params = {}
      @_errors = []
      @_headers = {}
    end

    attr_reader :params
    attr_reader :_errors

    def getErrors
      return @_errors
    end

    def addError(error)
      @_errors.push(error)
    end

    def addHeaders(headers)
      @_headers = headers
    end

    def getHeaders
      return @_headers
    end
  end

  class Response
    def initialize
      @result = {
        :_blockspring_spec => true,
        :_errors => []
      }
    end

    def addOutput(name, value = nil)
      @result[name] = value
      return self
    end

    def addFileOutput(name, filepath)
      filename = File.basename(filepath)
      b64_file_contents = Base64.strict_encode64(File.read(filepath))
      mime_type_object = MIME::Types.of(filename).last
      mime_type = mime_type_object ? mime_type_object.content_type : nil

      @result[name] = {
        :filename => filename,
        :"content-type" => mime_type,
        :data => b64_file_contents
      }
      return self
    end

    def addErrorOutput(title, message = nil)
      @result[:_errors].push({
        title: title,
        message: message
        }
      )

      return self
    end

    def end
      puts @result.to_json
    end
  end

  def self.transform_hash(original, options={}, &block)
    original.inject({}){|result, (key,value)|
      value = if (options[:deep] && Hash === value)
                transform_hash(value, options, &block)
              else
                value
              end
      block.call(result,key,value)
      result
    }
  end

  def self.stringify_keys(hash)
    transform_hash(hash) {|hash, key, value|
      hash[key.to_s] = value
    }
  end

  private_class_method :transform_hash
  private_class_method :stringify_keys
end
