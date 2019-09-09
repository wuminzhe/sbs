# sbs

A better substrate up tool.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sbs'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sbs

## Usage

- **new**: generate new blockchain from node-template

  ```shell
  # Default branch is master
  sbs new testchain
  
  sbs new testchain -b v1.0
  
  sbs new testchain -b v1.0 -a author
  ```

- **check**: Check your rust environment and substrate commits used by your project. Do it in your project directory

  ```shell
  sbs check
  ```

- **diff**: Compare the difference between your node-template and the branch's node-template

  ```shell
  # If fzf installed, a selectable diff list will appear, and the diff content will be displayed when you choose.
  # If no fzf, all diffs with content will be shown.
  sbs diff -b v1.0
  
  # Only list diffs without content.
  sbs diff -l -b v1.0
  
  # Default branch is master.
  sbs diff
  ```

  [fzf](https://github.com/junegunn/fzf) is a great command-line fuzzy finder.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/sbs.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
