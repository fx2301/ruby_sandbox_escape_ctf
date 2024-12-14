Your mission is to successfully run a system command (e.g. `ls`) from within the console.

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
