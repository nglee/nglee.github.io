---
layout: post
title: "Setup Jekyll Development Environment"
published: false
comment: true
---

Tested on a 'fresh' installation of Ubuntu 17.10.

Helps from:
* https://help.github.com/articles/setting-up-your-github-pages-site-locally-with-jekyll/
* https://jekyllrb.com/docs/installation/

```shell
# Install Ruby
$ sudo apt install ruby-dev

# Install jekyll and bundler via RubyGems
$ sudo gem install jekyll bundler

# Setup Gemfile
$ echo "source 'https://rubygems.org'" > Gemfile
$ echo "gem 'github-pages', group: :jekyll_plugins" >> Gemfile

# Update RubyGems with bundler
$ sudo apt install zlib1g-dev           # Requirement for nokogiri gem
$ bundle update                         # Without sudo, and enter password only if prompted

# TROUBLE-SHOOTING!!!
# Can't find gem bundler (>= 0.a) with executable bundle (Gem::GemNotFoundException)
$ gem update --system

# Start Jekyll
$ bundle exec jekyll serve              # Server starts on 127.0.0.1:4000
```


```shell
# Tell Jekyll which hostname to respond
# https://zarino.co.uk/post/jekyll-local-network/
$ jekyll serve --host 0.0.0.0
```

----------
<a href="javascript:showChangeLog();">Show ChangeLog</a>
<div id="post_changelog" style="display:none;">
<table>
  <tr>
    <th>Version</th>
    <th>Description</th>
    <th>Date</th>
  </tr>
  <tr>
    <td class="td_center">0.1</td>
    <td>Draft</td>
    <td class="td_center">2018-01-23</td>
  </tr>
</table>
</div>
