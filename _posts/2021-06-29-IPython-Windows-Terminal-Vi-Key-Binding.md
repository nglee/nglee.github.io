---
layout: post
title: "IPython, Windows Terminal, Vi 키 바인딩"
published: true
comments: true
---

# 1. Install IPython with pip

```
PS > python3 --version
Python 3.9.5
PS > pip3 install ipython
```

# 2. Vi key bindings for IPython

```
PS > ipython profile create
PS > cd $env:USERPROFILE\.ipython/profile_default
PS > Get-Content .\ipython_config.py

...

PS > Add-Content -Path .\ipython_config.py -Value "c=get_config()"
PS > Add-Content -Path .\ipython_config.py -Value "c.TerminalInteractiveShell.editing_mode = 'vi'"
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
    <td class="td_center">1.0</td>
    <td>Publish</td>
    <td class="td_center">2021-06-29</td>
  </tr>
</table>
</div>
