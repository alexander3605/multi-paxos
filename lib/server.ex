
# distributed algorithms, n.dulay 11 feb 19
# coursework 2, paxos made moderately complex

defmodule Server do

def start config, server_num, multipaxos, monitor do
  if (config.debug_level == 2), do: IO.puts "          Starting server #{server_num} at #{inspect(self())}"
  config   = Map.put config, :server_num, server_num

  database = spawn Database, :start, [config, self(), monitor]
  replica  = spawn Replica,  :start, [config, self(), database, monitor]
  leader   = spawn Leader,   :start, [config, self()]
  acceptor = spawn Acceptor, :start, [config, self()]

  send multipaxos, { :config, replica, acceptor, leader }

end # start

end # Server

