defmodule Collections do
	def testList() do
		lst = [1, 2]
		IO.inspect(lst)
	end
	
	def testMap() do
		map = %{1=>"Hello", 2=>"There"}
		IO.inspect(map)
	end
	
	def testSet() do
		set = MapSet.new()
		set = MapSet.put(set, 4)
#		recur ()
		set = MapSet.put(set, 2)
		IO.inspect(set)
	end
end


Collections.testList()
Collections.testMap()
Collections.testSet()
