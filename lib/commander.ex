# Leszek Nowaczyk (lkn16) and Alessandro Serena (as6316)
defmodule Commander do
    @spec start(
            atom() | %{monitor: any(), server_num: any()},
            any(),
            any(),
            any(),
            any(),
            any(),
            any()
          ) :: any()
    def start config, leader, acceptors, replicas, ballot_number, slot_number, command do

        send config.monitor, { :commander_spawned, config.server_num }

        if (config.debug_level == 2), do: IO.puts "#{inspect(leader)}          Started Commander at #{inspect(self())}"
        state = Map.put Map.new, :leader, leader
        state = Map.put state, :acceptors, acceptors
        state = Map.put state, :replicas, replicas
        state = Map.put state, :ballot_number, ballot_number
        state = Map.put state, :slot_number, slot_number
        state = Map.put state, :command, command

        for acceptor <- state.acceptors do
            send acceptor, {:P2a, self(), state.ballot_number, state.slot_number, state.command}
        end

        waitfor = MapSet.new(state.acceptors)

        next config, state, waitfor

        send config.monitor, { :commander_finished, config.server_num }
    end # start

    defp next config, state, waitfor do
      receive do
      {:P2b, src, ballot_number} ->
        if (config.debug_level == 2), do: IO.puts("#{inspect(self())} recieved P2b from #{inspect(src)}")

        #IO.puts("    ballot_number received #{inspect(ballot_number)}")
        #IO.puts("    ballot_number #{inspect(state.ballot_number)}")

        if (state.ballot_number == ballot_number) do
            #IO.puts("inside if")
            waitfor = MapSet.delete(waitfor, src)
            #IO.puts("    Waitfor size #{MapSet.size(waitfor)}")
            #IO.puts("    State acceptors size/2 #{length(state.acceptors)/2}")
            if ( MapSet.size(waitfor) < length(state.acceptors) /2 ) do
                #IO.puts("inside if2")
                #IO.puts("    state.replicas #{inspect(state.replicas)}")
                for replica <- state.replicas do
                    send replica, {:decision, self(), state.slot_number, state.command}
                end
            else
                next config, state, waitfor
            end
        else
            send state.leader, {:preempted, self(), ballot_number}
        end
      end # receive
    end # next
end # module
