# Leszek Nowaczyk (lkn16) and Alessandro Serena (as6316)
defmodule Replica do

    def start config, src, database, monitor do
        if (config.debug_level == 2), do: IO.puts ["#{inspect(src)}           Started replica ", inspect(self())]
        state = Map.put Map.new, :database, database
        state = Map.put state, :monitor , monitor
        state = Map.put state, :slot_in , 1
        state = Map.put state, :slot_out , 1
        state = Map.put state, :proposals , Map.new
        state = Map.put state, :decisions , Map.new
        state = Map.put state, :requests , []
        state = Map.put state, :server_num, config.server_num
        state = Map.put state, :window, config.window

        receive do
            {:bind, leaders} ->
                state = Map.put state, :leaders , leaders
                next config, state
        end # receive
    end # start



    defp next config, state do
        receive do
        {:client_request, src, cmd} ->
            if (config.debug_level == 2), do: IO.puts("#{inspect(self())} received client_request from #{inspect(src)}")
            send state.monitor, {:client_request, state.server_num}
            new_requests = state.requests ++ [cmd]
            state = Map.put state, :requests, new_requests
            state = propose(state)
            next(config, state)

        {:decision, src, slot_number, cmd} ->
            if (config.debug_level == 2), do: IO.puts("#{inspect(self())} received DECISION from #{inspect(src)}")
            new_decisions = Map.put(state.decisions, slot_number, cmd)
            state = Map.put state, :decisions, new_decisions
            state = decision_loop(state)
            state = propose(state)
            next(config, state)
        end # receive
    end # next




    defp decision_loop state do # TODO
        if not Map.has_key?(state.decisions, state.slot_out) do
            state
        else
            #IO.puts("decision_loop")
            if Map.has_key?(state.proposals, state.slot_out) do
                if (Map.get(state.proposals, state.slot_out) != Map.get(state.decisions, state.slot_out)) do
                    new_requests = state.requests ++ [Map.get(state.proposals, state.slot_out)]
                    state = Map.put state, :requests, new_requests
                    new_proposals = elem(Map.pop(state.proposals, state.slot_out),1)
                    state = Map.put state, :proposals, new_proposals
                    state = perform(state, Map.get(state.decisions, state.slot_out))
                    decision_loop(state)
                else
                    new_proposals = elem(Map.pop(state.proposals, state.slot_out),1)
                    state = Map.put state, :proposals, new_proposals
                    state = perform(state, Map.get(state.decisions, state.slot_out))
                    decision_loop(state)
                end
            else
                state = perform(state, Map.get(state.decisions, state.slot_out))
                decision_loop(state)
            end
        end
    end # decision_loop




    defp perform(state, cmd) do
        #IO.puts("perform")

        # returns list of decisions that have the same command and happened in the past
        past_cmd_decisions = Enum.filter(Map.to_list(state.decisions), fn {k, v} -> v == cmd && k < state.slot_out end)

        if Enum.empty?(past_cmd_decisions) do
            # update database
            { _, _, transaction } = cmd
            send state.database, {:execute, self(), transaction}
        end
        state = Map.put state, :slot_out, state.slot_out + 1
        state
    end # perform



    defp propose(state) do
        if ( (length(state.requests) != 0) and (state.slot_in < state.slot_out+state.window) ) do
            # inside while loop
            if (Map.get(state.decisions, state.slot_in) == nil) do
                cmd = Enum.at(state.requests, 0)
                new_requests = state.requests -- [cmd]
                state = Map.put state, :requests, new_requests
                #IO.puts("       propose replica slot_number #{inspect(state.slot_in)}")
                #IO.puts("       propose replica cmd #{inspect(cmd)}")
                new_proposals = Map.put(state.proposals, state.slot_in, cmd)
                state = Map.put state, :proposals, new_proposals
                for leader <- state.leaders do
                    send(leader, {:propose, self(), state.slot_in, cmd} )
                end
                state = Map.put state, :slot_in, state.slot_in + 1
                propose(state)
            else
                state = Map.put state, :slot_in, state.slot_in + 1
                propose(state)
            end

        else
            state
        end
    end # propose



end # module
