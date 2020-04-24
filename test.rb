class Parent
	def m 
		return "greg"
	end
end

class Child < Parent
	def m
		return super + " the egg"
	end
end

bob = Parent.new
nob = Child.new

puts bob.m

puts

puts nob.m 