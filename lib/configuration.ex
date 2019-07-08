# Leszek Nowaczyk (lkn16) and Alessandro Serena (as6316) - added to the file
# distributed algorithms, n.dulay, 11 feb 19
# multi-paxos, configuration parameters v3

defmodule Configuration do

def version :default do
  %{
  debug_level:  0, 		# debug level 0
  docker_delay: 1_000,		# time (ms) to wait for containers to start up

  max_requests: 2,		# max requests each client will make
  client_sleep: 100,		# time (ms) to sleep before sending new request
  client_stop:  60_000,		# time (ms) to stop sending further requests
  client_send:	:quorum,	# :round_robin, :quorum or :broadcast

  n_accounts:   100,		# number of active bank accounts
  max_amount:   1_000,		# max amount moved between accounts

  print_after:  1_000,		# print transaction log summary every print_after msecs

  crash_server: %{},

  window:       10,   # when window = 1, it is equivelent to not having a window

  delay:        1   # random delay from 0 to 'delay' when the leader is preemted (0 means no delay)
  }
end

# -----------------------------------------------------------------------------

def version :faster do
  version :default	# settings for faster throughput and flow-control
  # settings omitted
end

# -----------------------------------------------------------------------------

def version :debug1 do		# same as :default with debug_level: 1
  config = version :default
  Map.put config, :debug_level, 1
end

# -----------------------------------------------------------------------------

def version :debug2 do		# same as :default with debug_level: 1
  config = version :default
  Map.put config, :debug_level, 2
end

# -----------------------------------------------------------------------------

def version :crashes do		# settings for crashing servers
  version :default
  # settings omitted
end

end # module ----------------------------------------------------------------

