# Leszek Nowaczyk (lkn16) and Alessandro Serena (as6316)
defmodule Scout do
    def start config, leader, acceptors, ballot_number do

        send config.monitor, { :scout_spawned, config.server_num }

        if (config.debug_level == 2), do: IO.puts "#{inspect(leader)}           Started Scout at #{inspect(self())}"
        state = Map.put Map.new, :leader, leader
        state = Map.put state, :acceptors, acceptors
        state = Map.put state, :ballot_number, ballot_number

        for acceptor <- state.acceptors do
            send acceptor, {:P1a, self(), ballot_number}
        end

        waitfor = MapSet.new(state.acceptors)
        pvalues = MapSet.new

        next config, state, waitfor, pvalues

        send config.monitor, { :scout_finished, config.server_num }
    end # start

    defp next config, state, waitfor, pvalues do
        receive do
        {:P1b, src, ballot_number, accepted} ->
            if (config.debug_level == 2), do: IO.puts("#{inspect(self())} received P1b from #{inspect(src)}")
            if (state.ballot_number == ballot_number) do
                pvalues = MapSet.union(pvalues, accepted)
                waitfor = MapSet.delete(waitfor, src)
                if ( MapSet.size(waitfor) < length(state.acceptors) /2 ) do
                    send state.leader, {:adopted, self(), state.ballot_number, pvalues}
                else
                    next config, state, waitfor, pvalues
                end
            else
                send state.leader, {:preempted, self(), ballot_number}
            end
        end # receive
    end # next
end # module
