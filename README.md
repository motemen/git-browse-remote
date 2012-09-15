git-browse-remote
=================

`git-browse-remote` helps viewing remote repositories e.g. GitHub in your browser.

USAGE
-----

```
git browse-remote [-r|--remote <remote>] [--top|--rev|--ref] [<commit> | <remote>]
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
