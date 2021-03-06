# CoffeeShop

[Guides](http://mikesmullin.github.com/coffee-shop-docs/) documentation in progress. We welcome your contributions!

![CoffeeShop artwork](https://raw.github.com/mikesmullin/coffee-shop/stable/skeleton/static/public/images/coffee-shop.png)

Inspired by [Tower.js](http://towerjs.org/), [Jekyll](https://github.com/mojombo/jekyll), [Picard](https://github.com/dantebronto/picard), and of course [Rails](http://rubyonrails.org/).

## What is CoffeeShop?

Watch the 15min intro to [Installing Node.js CoffeeShop v0.1.1](http://youtu.be/sdVvesNOn6g) on YouTube.

## Why CoffeeShop?

    (4:30:59 PM) Antono: what makes coffee-shop innovative? :)
    (4:31:13 PM) Antono: comparing to X (X is what you consider good alternative)
    (5:12:59 PM) Mike: back sry
    (5:13:40 PM) Mike: i think the biggest thing that makes it innovative is a) goal of elimination of double-trees between server and client-side, which also means b) 100% portability of server-side and client-side MVC logic 
    (5:15:07 PM) Mike: the secondary goal is c) performance/speed; everything that can be precompiled IS precompiled at the time the source file changes on disk, versus every time the result is requested which is what most frameworks are doing. this also means almost always only the end result is stored on disk, so that the disk + static file server can act as a cache
    (5:16:23 PM) Mike: i am porting an existing rails project to coffee-shop because, after adding several hundred MB of assets (its a very front-end heavy site), rails takes FOREVER to compile any minor changes and render them for the browser
    (5:16:28 PM) Mike: or respond to requests
    (5:17:15 PM) Mike: its true in general that nodejs is faster than RoR; you get close to C/C++/C#/Java performance
    (5:17:26 PM) Mike: but this comes with a contingency: as long as the code is well-written
    (5:17:54 PM) Mike: and i was sad to discover that efforts like TowerJS.org which set out to replace rails with a node solution became bloated and slow just like rails, because they kept the implementation strategies the same
    (5:19:07 PM) Mike: so i started blazing my own trails with coffee-* libs with a bias toward performance, minimalism, and the #1 goal everyone who moves to node.js for a web framework wants--portability/reusability of front-end and back-end code

See also: http://gilesbowkett.blogspot.com/2012/02/rails-went-off-rails-why-im-rebuilding.html

## Installation

```bash
# install NVM (recommended)
sudo apt-get remove nodejs npm # if it was installed before this
curl https://raw.github.com/creationix/nvm/master/install.sh | sh

# install node
nvm install 0.8.15 # the version we're testing with
nvm alias default 0.8.15

# install CoffeeSprites/node-gd dependencies
sudo apt-get install libgd2-xpm-dev build-essential # libgd, build tools
sudo apt-get install pngcrush # optional optimizer makes PNG files smaller
# install CoffeeShop dependencies
npm install coffee-script -g # gives `cake` binary
# install CoffeeShop
npm install coffee-shop -g

# generate new project
shop new <project>

# start server
cd <project>
shop open

# browse to
http://localhost:3001/

# explore
shop help # to see more fun things you can do
```

## Related

* [CoffeeAssets](https://github.com/mikesmullin/coffee-assets)
* [CoffeeTemplates](https://github.com/mikesmullin/coffee-templates)
* [CoffeeStylesheets](https://github.com/mikesmullin/coffee-stylesheets)
* [CoffeeSprites](https://github.com/mikesmullin/coffee-sprites)

## Credits

Sponsored by [Smullin Design](http://www.smullindesign.com/).
