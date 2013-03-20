# @markup markdown
# @title Learning OpenShift Origin

# Learning OpenShift Origin

We get quite a few questions about where to start with learning OpenShift Origin. This document provides a guided path on how to embark on learning OpenShift Origin well enough to start building your own cartridges.

The first thing to consider is when to use a quickstart, DIY application, a cartridge or submit a patch of OpenShift Origin. It's important to understand the right tool for the right job.

A quickstart is best used when you want to use an existing cartridge but replace the default application with something customized. For example, [Wordpress is a great quickstart example](https://github.com/openshift/wordpress-example) because it uses the PHP cartridge and replaces the default application with Wordpress. If you want to show off an application that you wrote or get a new framework running on OpenShift, a quickstart is your best bet.

However, sometimes the provided cartridges aren't enough. For example, maybe you want to experiment with Python 3 or something like [Ceylon](http://ceylon-lang.org/) which requires Java 7. In those cases, you need to start installing and running your own processes. DIY provides a great place to start experimenting. You essentially get an empty cartridge into which you can upload your own binaries and start serving HTTP requests. At a minimum, you can see whether the binaries you want to run actually work in the OpenShift environment. The limitations of a DIY cartridge is that they really don't take advantage of the PaaS platform. They are just there for experimentation and don't understand how to do things like deployment, auto-scaling, snapshots, etc. They are also only consumable by you - DIY instances aren't easily shared with other users.

If your DIY experimentation goes well, your next step is building an actual cartridge. Cartridges provide a mechanism to capture all your hard work and knowledge about a platform and enable other users with it. It's a combination of where to get the binaries and runtimes as well as an implementation of the lifecycle events to make the software run (e.g. start, stop, scale, snapshot, etc). This is a more involved process and usually involves getting your binaries into a consumable, trusted location (like Fedora) as well as implementing the various hooks that required to make your cartridge build, deploy, scale, etc. However, that hard work has the benefit of allowing others to consume and build on your cartridges.

If your experimentation requires features from the platform that are missing, your next step would be to create a patch against OpenShift Origin which adds the features you require. Making changes to the core framework of OpenShift requires a deep understanding of the architecture and code but would give you the most flexibility in extending the platform. It would also benefit all users of OpenShift but allowing them to access the functionality you add.

With that introduction behind us, I want to introduce a bit of a guided path to build up the knowledge you'll need to be able to build good quickstarts or cartridges. The first place I usually recommend people start with is by joining our [discussion channels](https://www.openshift.com/open-source#Discussion_Forums), specifically the Google Plus community, IRC and the Mailing Lists. This is a fast moving project and just watching the development chatter will teach you a lot.

But you also need to have a base understanding to get the most value out of that chatter. To get that, the first doc to read through is our architecture doc. It's still evolving but it will at least provide you with the right foundation and some background on the design decisions

[Architecture Overview](https://www.openshift.com/wiki/architecture-overview)

The next thing I would recommend is playing around with are DIY cartridges. DIY cartridges provide a sort of cartridge 'shell' in which you can experiment. That is probably a good way to get exposure to some of the multi-tenancy limitations when working in gears without hitting the cartridge development overhead up front:

[Do It Yourself Documentation](https://www.openshift.com/developers/do-it-yourself)

To learn about building custom cartridges in general, you can read:

[Introduction to Cartridge Building](/origin/node/file.README.writing_cartridges.html)

After that, the next stop should be the origin-server codebase which really makes up the majority of our server code:

[GitHub Origin-Server Repository](https://github.com/openshift/origin-server)

Specifically, you should look at a cartridge like PHP or JBoss:

[GitHub PHP Cartridge](https://github.com/openshift/origin-server/tree/master/cartridges/openshift-origin-cartridge-php)

In addition to cartridges which are a little more complicated, you can also build 'quickstarts' which use existing cartridges to add supplemental capabilities. A good example of this is the wordpress quickstart which uses the php cartridges:

[Wordpress Quickstart](https://github.com/openshift/wordpress-example)

Hope this gets you started on your way to contributing to OpenShift Origin! Don't hesitate to ask questions on the lists or IRC if you get stumped and we'll be there to help.