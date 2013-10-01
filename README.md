git-browse-remote
=================

`git-browse-remote` helps viewing remote repositories e.g. GitHub in your browser.

Usage
-----

```
git browse-remote [-r|--remote <remote>] [--top|--rev|--ref] [-L <n> [<commit> | <remote>] [<file>]
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

How to set up
-------------

`git browse-remote` stores url mapping in ~/.gitconfig.
To initialize this, execute with `--init` option.

```
% git browse-remote --init
Writing config for github.com...
Mappings generated:
browse-remote.github.com.top https://{host}/{path}
browse-remote.github.com.ref https://{host}/{path}/tree/{short_ref}
browse-remote.github.com.rev https://{host}/{path}/commit/{commit}
browse-remote.github.com.file https://{host}/{path}/blob/{short_rev}/{file}{line && "#L%d" % line}
```

Execute `git config browse-remote.<host>.{top|ref|rev} <url template>`
to register other hosts mappings.

Especially, if you have a GitHub Enterprise repository, run

```
% git browse-remote --init <ghe host>=github
```

to easyly setup url mappings. `--init <host>=gitweb` is also available.

Variables available in url template
-----------------------------------

 * `host` (eg. "github.com")
 * `path` (eg. "motemen/git-browse-remote")
   * Sliceable, subscribable like an `Array`
 * `ref` (eg. "refs/heads/master")
 * `short_ref` (eg. "master")
 * `commit` (eg. "04f7c64ba9d524cf311a673ddce5722b2441e2ea")
 * `short_commit` (eg. "04f7c64b")
 * `rev` (ref or commit)
 * `short_rev` (short_ref or short_commit)
 * `file` (eg. "bin/git-browse-remote")
 * `line` (eg. 30)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
