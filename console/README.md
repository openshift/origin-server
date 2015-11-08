# OpenShift Origin Management Console
Installation and use of the Management Console is documented in the [Administration Guide](http://openshift.github.io/documentation/oo_administration_guide.html#management-console)

## Developing / Contributing
We expect code contributions to follow these standards:

1. Ensure code matches the [GitHub Ruby styleguide](https://github.com/styleguide/ruby), except where the file establishes a different standard.
2. Ensure CSS and HTML match the [Bootstrap styleguide](http://mdo.github.com/code-guide/), except where explicitly identified differently.
3. We use Test::Unit with Rails extensions for all our test cases.
4. We try to maintain 100% line coverage of all newly added model and
   controller code via testing.  Coverage reports are generated if
   you have the simplecov gem installed after tests execute via
   bundle exec rake test.

Once you've made your changes:

1. [Fork](http://help.github.com/forking/) the code
2. Create a topic branch - `git checkout -b my_branch`
3. Push to your branch - `git push origin my_branch`
4. Create a [Pull Request](http://help.github.com/pull-requests/) from your branch
5. That's it!

For more details about the console visit the [OpenShift Origin open source
community page](https://www.openshift.com/open-source).

Please stop by #openshift on irc.freenode.net if you have any questions or
comments.  For more information about OpenShift, visit https://www.openshift.com/
or the OpenShift support page https://www.openshift.com/support
