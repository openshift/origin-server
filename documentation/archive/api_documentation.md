# @markup markdown
# @title API Documentation Guidelines

# API Documentation Guidelines

OpenShift Origin uses [Yard](http://yardoc.org) to generate documentation for all Ruby code.
The Yard docs include a [Getting started guide](http://rubydoc.info/docs/yard/file/docs/GettingStarted.md)
as well as a reference to all [supported tags](http://rubydoc.info/docs/yard/file/docs/Tags.md#taglist).
Below I have included some examples of how to use Yard.

### Examples

#### Documenting a class

  ```
  # Class to represent an OpenShift Application
  # @!attribute [r] name
  #   @return [String] The name of the application
  # ...
  class Application
    field :name, type: String
    ...
    
    # Setter for application name - sets the name and the canonical_name
    # @param app_name [String] User provided application name
    # @return [String] application name
    def name=(app_name)
      self.canonical_name = app_name.downcase
      super
    end
  end
  ```

#### Documenting a REST endpoint

  ```
  # @api REST
  # Support API to check if application DNS entry is available
  class DnsResolvableController < BaseController
    ##
    # Support API to check if application DNS entry is available
    #
    # URL: /domains/:domain_id/applications/:application_id/dns_resolvable
    #
    # Action: GET
    #
    # @return [RestReply<Boolean>] Returns true when DNS entry is resolvable
    def show
      domain_id = params[:domain_id]
      id = params[:application_id]
      ...
    end
    ...
  end
  ```

#### Documenting a REST model

    ```
    ##
    # @api REST
    # Describes an SSH Key associated with a user
    # @see RestUser
    #
    # Example:
    #   ```
    #   <key>
    #     <name>default</name>
    #     <content>AAAAB3Nz...SeRRcMw==</content>
    #     <type>ssh-rsa</type>
    #     <links>
    #     ...
    #     </links>
    #   </key>
    #   ```
    #
    # @!attribute [r] name
    #   @return [String] Name of the ssh key
    # @!attribute [r] content
    #   @return [String] Content of the SSH public key
    # @!attribute [r] type
    #   @return [String] Type of the ssh-key. Eg: ssh-rsa
    class RestKey < OpenShift::Model
      attr_accessor :name, :content, :type, :links
      ...
    end
    ```