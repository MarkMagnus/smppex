defmodule SMPPEX.ClientPool do
  @moduledoc false

  alias :erlang, as: Erlang
  alias :ranch, as: Ranch
  alias :ranch_server, as: RanchServer
  alias :ranch_conns_sup, as: RanchConnsSup

  @default_capacity 500
  @default_transport :ranch_tcp
  @default_cert_file "priv/host.crt"
  @default_key_file "priv/host.key"
  @default_timeout 5000
  @default_number_of_acceptors 50

  @type session :: term
  @type handler_result :: {:ok, session} | {:error, reason :: term}
  @type handler :: (Ranch.ref, term, module, pid -> handler_result)

  @type pool :: {pid, Ranch.ref, module}

  @spec start(handler, non_neg_integer, module, non_neg_integer) :: pool

  def start(
        handler,
        capacity \\ @default_capacity,
        transport \\ @default_transport,
        ack_timeout \\ @default_timeout,
        num_acceptors \\ @default_number_of_acceptors
      ) do
    ref = make_ref()

    protocol_options = [{:handler, handler}]
    transport_options = %{
      handshake_timeout: ack_timeout,
      shutdown: :brutal_kill,
      max_connections: capacity,
      num_acceptors: num_acceptors,
      socket_options: %{  }
    }

    start_args = []
    protocol = SMPPEX.Session

    RanchServer.set_new_listener_opts(ref, capacity, transport_options, protocol_options, start_args)

    transport_options = RanchServer.get_transport_options(ref)
	  number_conn_sup = Map.get(transport_options, :num_conns_sups, num_acceptors)
	  stats_counters = :counters.new(2*number_conn_sup, [])
    :ok = RanchServer.set_stats_counters(ref, stats_counters)
    {:ok, sup_pid} = RanchConnsSup.start_link(ref, 1, transport, transport_options, protocol, Logger)

    {sup_pid, ref, transport}
  end

  def stop({sup_pid, ref, _transport}) do
    Erlang.unlink(sup_pid)
    Erlang.exit(sup_pid, :shutdown)
    RanchServer.cleanup_listener_opts(ref)
  end

  def start_session({sup_pid, ref, transport}, socket) do
    transport.controlling_process(socket, sup_pid)
    RanchConnsSup.start_protocol(sup_pid, ref, socket)
    :ok
  end

  @spec ref(pool) :: Ranch.ref

  def ref({_pid, ref, _transport}), do: ref

end
