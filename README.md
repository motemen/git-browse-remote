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

HOW TO SET UP
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
```

Execute `git config browse-remote.<host>.{top|ref|rev} <url template>`
to register other hosts mappings.

Especially, if you have a GitHub Enterprise repository, run

```
% git browse-remote --init <ghe host>=github
```

to easyly setup url mappings. `--init <host>=gitweb` is also available.

VARIABLES AVAILABLE IN URL TEMPLATE
-----------------------------------

 * `host` (eg. "github.com")
 * `path` (eg. "motemen/git-browse-remote")
   * Sliceable, subscribable like an `Array`
 * `ref` (eg. "refs/heads/master")
 * `short_ref` (eg. "master")
 * `commit` (eg. "04f7c64ba9d524cf311a673ddce5722b2441e2ea")
