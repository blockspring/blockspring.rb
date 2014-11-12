# blockspring.rb

Ruby gem to assist in creating and running blocks (cloud functions) with Blockspring.

http://rubygems.org/gems/blockspring

### Installation
To get started, we'll need ruby. If you don't have ruby on your machine, first visit https://www.ruby-lang.org/en/installation/ to install it.

Next:

    $ gem install blockspring

### Getting started


####Step 1: Write our block
First, in an empty directory we'll save the following code to a file called ```block.rb```.
```ruby
# save this block.rb file into an empty directory.
require 'blockspring'

myBlock = lambda do |request, response|
  sum = request.params["num1"].to_f + request.params["num2"].to_f
  
  response.addOutput("sum", sum)

  response.end()
end

Blockspring.define(myBlock)
```

####Step 2: Test our block locally
Next, we'll test our block locally:

    // pass parameters via stdin (recommended)
    $ echo '{"num1":20, "num2": 50}' | ruby block.rb

or

    // pass parameters via command-line arguments
    $ ruby block.rb --num1=20 --num2=50

Our response should be:

    $ {"_blockspring_spec":true,"_errors":[],"sum":70.0}
    
Looks like our block can add!

####Step 3: Deploy our block
Now it's time to deploy our block. We can deploy our block with the [Blockspring online editor](https://api.blockspring.com/blocks/new) or with the [Blockspring-CLI tool](https://www.github.com/blockspring/blockspring-cli). Let's try out the command-line tool.

We'll need to login with Blockspring so if you don't have a blockspring account, visit https://api.blockspring.com/users/sign_up.

Run the following commands in the same directory as your ```block.rb``` file:

    // Install the cli tool (make sure you have ruby installed)
    $ gem install blockspring-cli
    
    // Login to blockspring
    $ blockspring login
    
    // Deploy our block
    $ blockspring push
    
Our block is deployed. That was easy.

Blockspring generated a  ```blockspring.json``` file in our working directory along the way. Find the ```user``` (our username) and ```id``` (our block's id) parameters in this file, and let's run our block from the cloud:

    $ echo '{"num1":20, "num2": 50}' | blockspring run <user>/<id>
    
We should get back the same result as when we ran the block locally:

    $ {"_blockspring_spec":true,"_errors":[],"sum":70.0}

####Step 4: Customize our block
The final step is to make our block a bit more usable. Let's open up ```blockspring.json``` and paste in the following.

<b>Note: some values like the id, user, language, updated_at, and created_at shouldn't be changed.</b>

```json
{
  "id": DONT_CHANGE_THIS,
  "user": DONT_CHANGE_THIS,
  "title": "Summer",
  "description": "A basic block to sum two numbers",
  "parameters": [
    {
      "type": "number",
      "label": "Number 1",
      "parameter_name": "num1",
      "default": 50,
      "help_text": "Our first number to sum."
    },
    {
      "type": "number",
      "label": "Number 2",
      "parameter_name": "num2",
      "default": 20,
      "help_text": "Our second number to sum."
    }
  ],
  "is_public": true,
  "language": DONT_CHANGE_THIS,
  "updated_at": DONT_CHANGE_THIS,
  "created_at": DONT_CHANGE_THIS
}
```

Now let's push our block again to update it and then we'll open it up in Blockspring.

    $ blockspring push
    $ blockspring open

Voila! We set a title, description, and info about our block's parameters so that Blockspring could generate a simple UI. To find out more about parameters and UI input types, see here: https://api.blockspring.com/documentation.

<br/>

### API in Detail

######DEFINE
```Blockspring.define(function_name)``` accepts a single parameter: the name of the function we're defining in our block.

######RUN
```Blockspring.run(block_id, data, [api_key])``` accepts three parameters:
- ```block_id```: the block id that you'd like to run remotely.
- ```data```: a hash of keys that serve as inputs to the block you're running remotely.
- ```api_key```: our api_key found on Blockspring.com. This is an optional parameter. Without an api_key we'll rate limited to 10 calls per minute. If we're running ```Blockspring.run``` from an IDE, we should include an api_key. If we're including a ```Blockspring.run``` within our defined block, we don't need to include the api_key.
 
######Request
- ```request.params```: a hash of inputs being sent into our block.
- ```request.getErrors()```: parse all the errors being input into our block.

######Response
- ```response.addOutput(key, value)```: add a key and value to the output of our block.
- ```response.addFileOutput(key, path_to_file)```: add a file to the output of our block.
- ```response.addErrorOutput(title, [message])```: add an error message. Message is an optional parameter.
- ```response.end()```: call this at the end of our block to print out the results correctly.

Here's a sample block that touches on each function in the API:

```ruby
# save this block.rb file into an empty directory.
require 'blockspring'

myBlock = lambda do |request, response|
    if request.getErrors().length > 0
        response.addErrorOutput("Errors in request", "Our block ran even though errors were passed in through request.")
    end
    
    File.open("truth.txt", 'w') { |file| file.write("I <3 blockspring!") }
    response.addFileOutput("my_file", "truth.txt")
    
    sentiment = Blockspring.run("pkpp1233/6dd22564137f10b8108ec6c8f354f031", {"text" => "hey there, this is so much fun!"})
    response.addOutput("sentiment", sentiment["polarity"])
    response.end()
end

Blockspring.define(myBlock)
```

Try a ```blockspring push``` and ```blockspring open``` and check out the response using the UI.

### License

MIT

### Contact

Email us: founders@blockspring.com