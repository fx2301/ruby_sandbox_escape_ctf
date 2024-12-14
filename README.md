Your mission is from within the console to:

1. successfully run a system command (e.g. `system("ls")`), or
2. successfully access the secret_key (e.g. `Rails.application.config.secret_key`). 

To launch:

```
bundle install --path vendor/bundle
bundle exec rails console
```

Or using docker:
```
docker build .
docker run -it <sha>
```

If you think you've found a bypass, add it as a one-liner to `check_test.rb` and run:

```
bundle exec ruby check_test.rb
```
