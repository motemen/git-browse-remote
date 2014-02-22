git-browse-remote [![Build Status](https://travis-ci.org/motemen/git-browse-remote.png?branch=master)](https://travis-ci.org/motemen/git-browse-remote) [![Gem Version](https://badge.fury.io/rb/git-browse-remote.png)](http://badge.fury.io/rb/git-browse-remote)
=================

`git-browse-remote` helps viewing remote repositories e.g. GitHub in your browser.

Installation
------------

```
[sudo] gem install git-browse-remote 
```

Usage
-----

```
git browse-remote [-r|--remote <remote>] [--top|--rev|--ref] [-L <n>] [<commit> | <remote>] [<file> | <directory>]
```

`git-browse-remote` opens your web browser by `git web--browse` to show current repository in browser.

`git-browse-remote` depends on what commit/ref `HEAD` points (or you supplied by an argument), such as:

 * When on "master", opens repository's top page ("top" mode)
   * e.g. opens https://github.com/motemen/git-browse-remote
 * When on another branch/tag, opens repository's branch/tag page ("ref" mode)
   * e.g. opens https://github.com/motemen/git-browse-remote/tree/master
 * Otherwise, opens repository's commit page ("rev" mode)
   * e.g. opens https://github.com/motemen/git-browse-remote/commit/04f7c64ba9d524cf311a673ddce5722b2441e2ea

As a special case, if <var>commit</var> is invalid and an valid remote name, that remore repository's page is opened.

For more information such as custom URL mappings, please visit the [web page](http://motemen.github.io/git-browse-remote/).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
