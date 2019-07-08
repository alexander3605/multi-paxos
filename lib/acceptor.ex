# Leszek Nowaczyk (lkn16) and Alessandro Serena (as6316)
defmodule Acceptor do

  def start(config, src) do
    if (config.debug_level == 2), do: IO.puts "#{inspect(src)}          Started Acceptor at #{inspect(self())}"
    state = Map.put Map.new, :ballot_number, nil
    state = Map.put state, :accepted, MapSet.new

    next(config, state)
  end # start

  defp next config, state do
    receive do
      {:P1a, src, ballot_number} ->
        if (config.debug_level == 2), do: IO.puts("#{inspect(self())} recieved P1a from #{inspect(src)}")
        # ##IO.puts("p1a ballot_number #{inspect(ballot_number)}")
        # ##IO.puts("p1a state.ballot_number #{inspect(state.ballot_number)}")
        if (ballot_number > state.ballot_number) do
          state = Map.put state, :ballot_number, ballot_number
          send src, {:P1b, self(), state.ballot_number, state.accepted}
          next(config, state)
        else
          send src, {:P1b, self(), state.ballot_number, state.accepted}
          next(config, state)
        end


      {:P2a, src, ballot_number, slot_number, cmd} ->
        if (config.debug_level == 2), do: IO.puts("#{inspect(self())} received P2a from #{inspect(src)}")
        if (ballot_number == state.ballot_number) do
          pValue = Map.put Map.new, :ballot_number, ballot_number
          pValue = Map.put pValue, :slot_number, slot_number
          pValue = Map.put pValue, :cmd, cmd

          # update accepted
          new_accepted = MapSet.put(state.accepted, pValue)
          state = Map.put state, :accepted, new_accepted

          send(src, {:P2b, self(), state.ballot_number})
          next(config, state)
        else
          send(src, {:P2b, self(), state.ballot_number})
          next(config, state)
        end


    end # receive

  end # next

end # module
