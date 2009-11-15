require "environment"
require "digest/sha1"

module Cap
  
  # Used to raise a more informative error when verifying a
  # subject's ability to perform an operation on an object
  class ClearanceError < Exception
    def initialize(subject, object)
      super("#{subject.clearance} is less than #{object.clearance}")
    end
  end
  
  # Used to raise a more informative error when attempting to
  # transfer a capability with more privelege than allowed
  # the owner possesses.
  class PrivelegeError < Exception
  end
  
  module Clearance
    Confidential = 1
    Secret       = 2
    TopSecret    = 3
  end
  
  # Each right is a bit in a mask, therefore RW = 3
  module Right
    R = 1
    W = 2
    RW = 3 # 01 + 10 = 11 = 3
  end
  
  class Object
    attr :clearance
    def initialize(clearance=Clearance::Confidential)
      @clearance = clearance
    end
  end
  
  class Subject
    attr :clearance
    def initialize(clearance=Clearance::Confidential)
      @clearance = clearance
    end
  end
  
  class Capability
    attr :token
    attr :right
    attr :object

    # The subject is not an attribute, but is still used to generate
    # the token so that a capability for the same object/rights will
    # not generate the same token for different people.
    def initialize(subject, object, rights, salt=nil)
      @object = object
      @right = rights
      
      # Calling a class method instead of an instance method.  The actual
      # kernel has no involvement in the 
      @token = Capability.sign(subject, object, rights, salt)
    end
    
    # Creates a new capability.  Note, this function does not enforce
    # the subject's clearance and the object's clearance.  However, it
    # does ensure that a capability will never have rights that exceed
    # what was given within this capability.  If the subject requests
    # rights that exceed what is allowed for, then an exception is
    # raised.
    def transfer(subject, rights)
      # Ensure the requestsed rights never exceed the rights for the ticket.
      validate(rights)
      
      # Build a new capability for the subject.
      Capability.new(subject, self.object, rights, self.token)
    end
    
    # Raises a PrivelegeError if the rights argument exceeds the rights
    # of the token.
    def validate(rights)
      raise PrivelegeError.new if rights != (self.right & rights)
    end
    
    # Identical to Kernel::Signature – implemented here to avoid the appearance
    # that Capability collaborates with Kernel when generating derivative
    # capabilities.
    def self.sign(subject, object, right, salt = nil)
      Digest::SHA1.hexdigest("#{subject.hash}+#{object.hash}+#{right}+#{salt}")[0..7]
    end
  end
  
  class Kernel
    def initialize
      @seed = Time.now # right...
    end
    
    # A map of objects -> [capability, owner]
    def object_map
      @object_mapping ||= Hash.new
    end
    
    # Creates a new capability and adds a mapping between the object and 
    # the subject that can be used later to verify capabilities.  In this
    # system an object has exactly one owner.  This is a design decision
    # and not an oversight.
    def grant(subject, object, right=Right::RW)
      capability = Capability.new(subject, object, right, @seed)
      object_map[object] = [capability, subject]
      capability
    end
    
    # Verify a supplicant and a capability within the context of a
    # set of subjects, objects, and capabilities maintained by the
    # kernel.  This relies on a class method to perform the actual
    # verification.  Returns true if:
    # 1a. alleged_capability's was transferred from the owner to
    #     the supplicant.
    # 1b. alleged_capability matches the kernel's maintained capability
    #     for the referenced object
    # 2.  supplicant has proper clearance to the object referenced by
    #     alleged_capability
    #
    def verify(supplicant, alleged_capability)
      original_capability, owner = object_map[alleged_capability.object]
      Kernel::verify(supplicant, alleged_capability, original_capability, owner)
    end
    
    # Determine if alleged_capability was either legitimately generated via
    # a transfer or is the original capability.  Enforces clearances.
    def self.verify(supplicant, alleged_capability, original_capability, owner)
      # If the supplicant doesn't have the appropriate clearance, bail out early.
      return false unless cleared(supplicant, alleged_capability.object)
      
      # If the original matches the alleged capability then it is valid.  However,
      # the supplicant must also be the owner.  Otherwise, this means that someone
      # else is using a capability they should not have.
      return true if original_capability == alleged_capability and supplicant == owner

      # At this point, we must determine if the alleged_capability was derived
      # from the original_capability.  If the rights have been tampered with or
      # the capability was not issued to the supplicant then token will not match
      return true if alleged_capability.token == original_capability.transfer(supplicant, alleged_capability.right).token
      
      # If there was no success by now, we could not verify the alleged_capability
      false
    end
    
    def self.cleared(c1, c2)
      raise ClearanceError.new(c1,c2) if c1.clearance < c2.clearance
      true
    end
    
    # 
    def self.signature(subject, object, right, salt = nil)
      Digest::SHA1.hexdigest("#{subject.hash}+#{object.hash}+#{right}+#{salt}")[0..7]
    end
    
  end

end
