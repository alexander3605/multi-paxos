# Leszek Nowaczyk (lkn16) and Alessandro Serena (as6316)
defmodule Leader do
  def start config, src do
    if (config.debug_level == 2), do: IO.puts "#{inspect(src)}          Started Leader at #{inspect(self())}"
    state = Map.put Map.new, :ballot_number, {0, self()}
    state = Map.put state, :active, false
    state = Map.put state, :proposals, Map.new

    receive do
			{:bind, acceptors, replicas} ->
        state = Map.put state, :acceptors, acceptors
        state = Map.put state, :replicas, replicas

        spawn(Scout, :start, [config, self(), state.acceptors, state.ballot_number])

        next config, state
		end # receive
  end # start

  defp next config, state do
    receive do
    {:propose, src, slot_number, command} ->
      if (not Map.has_key?(state.proposals, slot_number)) do
        new_proposals = Map.put state.proposals, slot_number, command
        state = Map.put state, :proposals, new_proposals
        if (config.debug_level == 2), do: IO.puts("#{inspect(self())} received PROPOSE from #{inspect(src)}")
        #IO.puts("    propose state.proposals #{inspect(state.proposals)}")
        #IO.puts("    propose slot_number #{inspect(slot_number)}")
        if state.active do
          spawn(Commander, :start, [config, self(), state.acceptors, state.replicas, state.ballot_number, slot_number, command])
        end

        next config, state
      else
        next config, state
      end

    {:adopted, src, _ballot_number, accepted} -> #accepted contains pvalues
    if (config.debug_level == 2), do: IO.puts("#{inspect(self())} recieved ADOPTED from #{inspect(src)}")
      #IO.puts("Adopted state ballot #{inspect(state.ballot_number)} and ballot #{inspect(ballot_number)}")
      # if (state.ballot_number == ballot_number) do #this line was present in python code, but works without
        #IO.puts(["Accepted", inspect(accepted)])

      # group accepted by slot_number
      override = Enum.group_by(MapSet.to_list(accepted), fn pv -> pv.slot_number end, fn pv -> {pv.ballot_number, pv.cmd} end)

      #IO.puts(["override", inspect(override)])

      # find a map of slot_numbers to command with maximum ballot_number
      max_map = for {slot_num, v} <- override, into: %{} do
        {slot_num, elem(Enum.max_by(v, fn {ballot_number, _} -> ballot_number end), 1)}
      end

      #IO.puts(inspect(max_map))

      # merge proposals and max_map according to the triangular operator
      new_proposals = Map.merge(state.proposals, max_map, fn _, _, v2 -> v2 end)
      state = Map.put state, :proposals, new_proposals

      for slot_number <- Map.keys(state.proposals) do
        spawn(Commander, :start, [config, self(), state.acceptors, state.replicas, state.ballot_number,
          slot_number, Map.get(state.proposals, slot_number)])
      end

      state = Map.put state, :active, true

      next config, state

    {:preempted, src, ballot_number} ->
      if (config.debug_level == 2), do: IO.puts("#{inspect(self())} recieved PREEMPTED from #{inspect(src)}")
      if (ballot_number > state.ballot_number) do
        Process.sleep(DAC.random(config.delay))
        new_ballot_number = {elem(state.ballot_number, 0) + 1, self()}
        state = Map.put state, :ballot_number, new_ballot_number
        spawn(Scout, :start, [config, self(), state.acceptors, new_ballot_number])
        state = Map.put state, :active, false
        next config, state
      else
        # state = Map.put state, :active, false #appears in python code but not in pseudo code
        next config, state
      end # if
    end # receive
  end # next
end
